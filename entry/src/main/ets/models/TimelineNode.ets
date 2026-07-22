/**
 * 时间节点类型
 */
export enum TimelineNodeType {
  START = 'start',
  END = 'end',
  CUSTOM = 'custom'
}

/**
 * 事件时间节点模型
 * 用于记录一个事件下的多个关键时间点
 */
export interface TimelineNode {
  /** 节点序号（1, 2, 3...） */
  nodeId: number;
  /** 节点类型：start / end / custom */
  type: TimelineNodeType;
  /** 日期，ISO 8601 日期或日期时间 */
  date: string;
  /** 节点名称，如"报名开始"、"笔试考试"、"成绩公布" */
  nodeName: string;
  /** 图标资源名，使用系统 symbol（如 sys.symbol.calendar） */
  icon: string;
}

/**
 * 根据节点名称推断节点类型
 */
export function inferNodeType(nodeName: string): TimelineNodeType {
  if (nodeName.includes('开始') || nodeName.includes('启动') || nodeName.includes('报名')) {
    return TimelineNodeType.START;
  }
  if (nodeName.includes('结束') || nodeName.includes('截止') ||
      nodeName.includes('成绩') || nodeName.includes('结果')) {
    return TimelineNodeType.END;
  }
  return TimelineNodeType.CUSTOM;
}

/**
 * 根据节点名称推断默认图标资源名
 */
export function inferNodeIcon(nodeName: string): string {
  if (nodeName.includes('报名')) {
    return 'sys.symbol.square_and_pencil';
  }
  if (nodeName.includes('考试') || nodeName.includes('竞赛')) {
    return 'sys.symbol.calendar';
  }
  if (nodeName.includes('成绩') || nodeName.includes('结果')) {
    return 'sys.symbol.flag_checkered';
  }
  if (nodeName.includes('开始') || nodeName.includes('启动')) {
    return 'sys.symbol.rocket';
  }
  if (nodeName.includes('结束') || nodeName.includes('截止')) {
    return 'sys.symbol.checkmark_circle';
  }
  return 'sys.symbol.bell';
}

/**
 * 创建一个空的时间节点模板
 */
export function createEmptyTimelineNode(nodeId: number, date?: string): TimelineNode {
  const now = date ?? new Date().toISOString();
  return {
    nodeId,
    type: TimelineNodeType.CUSTOM,
    date: now,
    nodeName: '',
    icon: 'sys.symbol.bell'
  };
}
