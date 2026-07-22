/**
 * 节次数据仓库
 * 提供 time_slots 表的查询与默认数据初始化
 */
import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { TimeSlot } from '../models/TimeSlot';
import { ScheduleDatabase } from '../database/ScheduleDatabase';

const DEFAULT_TIME_SLOTS: TimeSlot[] = [
  { sectionNumber: 1, startTime: '08:00', endTime: '08:45', name: '第一节' },
  { sectionNumber: 2, startTime: '08:55', endTime: '09:40', name: '第二节' },
  { sectionNumber: 3, startTime: '10:00', endTime: '10:45', name: '第三节' },
  { sectionNumber: 4, startTime: '10:55', endTime: '11:40', name: '第四节' },
  { sectionNumber: 5, startTime: '14:00', endTime: '14:45', name: '第五节' },
  { sectionNumber: 6, startTime: '14:55', endTime: '15:40', name: '第六节' },
  { sectionNumber: 7, startTime: '15:50', endTime: '16:35', name: '第七节' },
  { sectionNumber: 8, startTime: '16:45', endTime: '17:30', name: '第八节' },
  { sectionNumber: 9, startTime: '19:00', endTime: '19:45', name: '第九节' },
  { sectionNumber: 10, startTime: '19:55', endTime: '20:40', name: '第十节' },
  { sectionNumber: 11, startTime: '20:50', endTime: '21:35', name: '第十一节' }
];

const SLOT_COLUMNS: string[] = ['sectionNumber', 'startTime', 'endTime', 'name'];

export class TimeSlotRepository {
  /**
   * 查询所有节次，按 sectionNumber 升序排列
   * 如果表为空，自动插入默认节次
   */
  static async getAll(context: common.Context): Promise<TimeSlot[]> {
    try {
      const store = await ScheduleDatabase.getInstance(context);
      const predicates = new relationalStore.RdbPredicates('time_slots');
      predicates.orderByAsc('sectionNumber');
      const resultSet = await store.query(predicates, SLOT_COLUMNS);
      const slots: TimeSlot[] = [];
      while (resultSet.goToNextRow()) {
        slots.push(TimeSlotRepository.mapRowToSlot(resultSet));
      }
      resultSet.close();

      if (slots.length === 0) {
        await TimeSlotRepository.initDefaults(context);
        return TimeSlotRepository.getAll(context);
      }
      return slots;
    } catch (e) {
      console.error('TimeSlotRepository.getAll failed', e);
      return [];
    }
  }

  /**
   * 初始化默认节次数据
   */
  static async initDefaults(context: common.Context): Promise<void> {
    try {
      const store = await ScheduleDatabase.getInstance(context);
      for (const slot of DEFAULT_TIME_SLOTS) {
        await store.insert('time_slots', {
          sectionNumber: slot.sectionNumber,
          startTime: slot.startTime,
          endTime: slot.endTime,
          name: slot.name
        });
      }
    } catch (e) {
      console.error('TimeSlotRepository.initDefaults failed', e);
      throw new Error(String(e));
    }
  }

  private static mapRowToSlot(rs: relationalStore.ResultSet): TimeSlot {
    try {
      return {
        sectionNumber: rs.getLong(rs.getColumnIndex('sectionNumber')),
        startTime: rs.getString(rs.getColumnIndex('startTime')),
        endTime: rs.getString(rs.getColumnIndex('endTime')),
        name: rs.getString(rs.getColumnIndex('name')) ?? ''
      };
    } catch (e) {
      throw new Error(String(e));
    }
  }
}
