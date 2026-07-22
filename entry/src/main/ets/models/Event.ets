import { TimelineNode } from './TimelineNode';

/**
 * 事件操作类型
 */
export enum EventActionType {
  NONE = 'none',
  OPEN_URL = 'openUrl',
  OPEN_APP = 'openApp',
  OPEN_FILE = 'openFile',
  OPEN_FOLDER = 'openFolder',
  RUN_COMMAND = 'runCommand'
}

/**
 * 事件操作配置
 * 用于记录事件关联的打开链接、应用、文件等动作
 */
export interface EventAction {
  /** 操作类型 */
  type: EventActionType;
  /** 目标 URL / 路径 / 命令 */
  target: string;
  /** 启动参数 */
  parameters: string;
  /** 操作按钮显示文本 */
  description: string;
}

/**
 * 长期规划事件模型
 * 用于记录考试、竞赛、报名、成绩公布等具有时间线的事件
 */
export interface Event {
  /** 事件唯一标识（UUID） */
  id: string;
  /** 事件名称 */
  name: string;
  /** 详细描述 */
  detail: string;
  /** 操作配置 */
  action: EventAction;
  /** 时间节点列表，必须包含 start 和 end */
  timelineNodes: TimelineNode[];
  /** 创建时间 */
  createdAt: string;
  /** 更新时间 */
  updatedAt: string;
}

/**
 * 空操作配置
 */
export const EMPTY_EVENT_ACTION: EventAction = {
  type: EventActionType.NONE,
  target: '',
  parameters: '',
  description: ''
};

/**
 * 生成一个空事件模板
 */
export function createEmptyEvent(): Event {
  const now = new Date().toISOString();
  return {
    id: '',
    name: '',
    detail: '',
    action: {
      type: EventActionType.NONE,
      target: '',
      parameters: '',
      description: ''
    },
    timelineNodes: [],
    createdAt: now,
    updatedAt: now
  };
}

/**
 * 获取事件开始日期
 */
export function getEventStartDate(event: Event): Date {
  if (!event.timelineNodes || event.timelineNodes.length === 0) {
    return new Date();
  }
  return event.timelineNodes
    .map(node => new Date(node.date))
    .reduce((min, current) => current < min ? current : min);
}

/**
 * 获取事件结束日期
 */
export function getEventEndDate(event: Event): Date {
  if (!event.timelineNodes || event.timelineNodes.length === 0) {
    return new Date();
  }
  return event.timelineNodes
    .map(node => new Date(node.date))
    .reduce((max, current) => current > max ? current : max);
}
