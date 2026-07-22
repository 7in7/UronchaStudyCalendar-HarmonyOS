import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Event, EventActionType } from '../models/Event';
import { TimelineNode, TimelineNodeType } from '../models/TimelineNode';
import { ScheduleDatabase } from '../database/ScheduleDatabase';

/**
 * 事件数据仓库
 * 负责 events 表和 timeline_nodes 表的增删改查
 */
export class EventRepository {
  /**
   * 获取所有事件（含时间节点）
   */
  static async getAll(context: common.Context): Promise<Event[]> {
    const store = await ScheduleDatabase.getInstance(context);
    const eventResult = await store.querySql('SELECT * FROM events ORDER BY createdAt DESC');
    const events: Event[] = [];

    while (eventResult.goToNextRow()) {
      const event = EventRepository.mapEventFromRow(eventResult);
      event.timelineNodes = await EventRepository.getTimelineNodes(store, event.id);
      events.push(event);
    }
    eventResult.close();
    return events;
  }

  /**
   * 根据 ID 查询事件
   */
  static async getById(context: common.Context, id: string): Promise<Event | null> {
    const store = await ScheduleDatabase.getInstance(context);
    const result = await store.querySql('SELECT * FROM events WHERE id = ?', [id]);
    if (!result.goToNextRow()) {
      result.close();
      return null;
    }
    const event = EventRepository.mapEventFromRow(result);
    event.timelineNodes = await EventRepository.getTimelineNodes(store, event.id);
    result.close();
    return event;
  }

  /**
   * 插入事件（含时间节点）
   */
  static async insert(context: common.Context, event: Event): Promise<void> {
    const store = await ScheduleDatabase.getInstance(context);
    try {
      await store.beginTransaction();
      await EventRepository.insertEvent(store, event);
      for (const node of event.timelineNodes) {
        await EventRepository.insertTimelineNode(store, event.id, node);
      }
      await store.commit();
    } catch (e) {
      await store.rollBack();
      throw new Error(String(e));
    }
  }

  /**
   * 更新事件（含时间节点：先删后插）
   */
  static async update(context: common.Context, event: Event): Promise<void> {
    const store = await ScheduleDatabase.getInstance(context);
    try {
      await store.beginTransaction();
      await store.executeSql(
        `UPDATE events SET name = ?, detail = ?, actionType = ?, actionTarget = ?,
         actionParameters = ?, actionDescription = ?, updatedAt = ? WHERE id = ?`,
        [event.name, event.detail, event.action.type, event.action.target,
          event.action.parameters, event.action.description, event.updatedAt, event.id]
      );
      await store.executeSql('DELETE FROM timeline_nodes WHERE eventId = ?', [event.id]);
      for (const node of event.timelineNodes) {
        await EventRepository.insertTimelineNode(store, event.id, node);
      }
      await store.commit();
    } catch (e) {
      await store.rollBack();
      throw new Error(String(e));
    }
  }

  /**
   * 删除事件（级联删除时间节点）
   */
  static async delete(context: common.Context, id: string): Promise<void> {
    const store = await ScheduleDatabase.getInstance(context);
    try {
      await store.executeSql('DELETE FROM events WHERE id = ?', [id]);
    } catch (e) {
      throw new Error(String(e));
    }
  }

  /**
   * 插入事件主体
   */
  private static async insertEvent(store: relationalStore.RdbStore, event: Event): Promise<void> {
    await store.executeSql(
      `INSERT INTO events (id, name, detail, actionType, actionTarget, actionParameters,
       actionDescription, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [event.id, event.name, event.detail, event.action.type, event.action.target,
        event.action.parameters, event.action.description, event.createdAt, event.updatedAt]
    );
  }

  /**
   * 插入时间节点
   */
  private static async insertTimelineNode(
    store: relationalStore.RdbStore,
    eventId: string,
    node: TimelineNode
  ): Promise<void> {
    await store.executeSql(
      `INSERT INTO timeline_nodes (eventId, nodeId, type, date, nodeName, icon)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [eventId, node.nodeId, node.type, node.date, node.nodeName, node.icon]
    );
  }

  /**
   * 查询事件的所有时间节点
   */
  private static async getTimelineNodes(
    store: relationalStore.RdbStore,
    eventId: string
  ): Promise<TimelineNode[]> {
    const result = await store.querySql(
      'SELECT * FROM timeline_nodes WHERE eventId = ? ORDER BY nodeId ASC',
      [eventId]
    );
    const nodes: TimelineNode[] = [];
    while (result.goToNextRow()) {
      nodes.push(EventRepository.mapTimelineNodeFromRow(result));
    }
    result.close();
    return nodes;
  }

  /**
   * 从结果行映射 Event
   */
  private static mapEventFromRow(result: relationalStore.ResultSet): Event {
    return {
      id: result.getString(result.getColumnIndex('id')),
      name: result.getString(result.getColumnIndex('name')),
      detail: result.getString(result.getColumnIndex('detail')),
      action: {
        type: result.getString(result.getColumnIndex('actionType')) as EventActionType,
        target: result.getString(result.getColumnIndex('actionTarget')),
        parameters: result.getString(result.getColumnIndex('actionParameters')),
        description: result.getString(result.getColumnIndex('actionDescription'))
      },
      timelineNodes: [],
      createdAt: result.getString(result.getColumnIndex('createdAt')),
      updatedAt: result.getString(result.getColumnIndex('updatedAt'))
    };
  }

  /**
   * 从结果行映射 TimelineNode
   */
  private static mapTimelineNodeFromRow(result: relationalStore.ResultSet): TimelineNode {
    return {
      nodeId: result.getLong(result.getColumnIndex('nodeId')),
      type: result.getString(result.getColumnIndex('type')) as TimelineNodeType,
      date: result.getString(result.getColumnIndex('date')),
      nodeName: result.getString(result.getColumnIndex('nodeName')),
      icon: result.getString(result.get