/**
 * 课程数据模型
 * 用于课程表 UI 展示，后续会与 WinUI3 端数据格式对齐扩展
 */
export interface Course {
  /** 唯一标识 */
  id: string;
  /** 课程名称 */
  name: string;
  /** 任课教师 */
  teacher: string;
  /** 上课地点 */
  location: string;
  /** 星期几：1=周一，7=周日 */
  dayOfWeek: number;
  /** 起始节次（含） */
  startSection: number;
  /** 结束节次（含） */
  endSection: number;
  /** 有课的周次列表 */
  weeks: number[];
  /** 课程描述/备注 */
  description?: string;
  /** 自定义颜色（可选，未设置时使用主题色） */
  color?: string;
  /** 所属学期 ID */
  semesterId: string;
  /** 创建时间，ISO 8601 */
  createdAt: string;
  /** 更新时间，ISO 8601 */
  updatedAt: string;
}

/**
 * 星期几枚举
 */
export enum DayOfWeek {
  MONDAY = 1,
  TUESDAY = 2,
  WEDNESDAY = 3,
  THURSDAY = 4,
  FRIDAY = 5,
  SATURDAY = 6,
  SUNDAY = 7
}

/**
 * 星期几中文标签
 */
export const DAY_LABELS: string[] = ['一', '二', '三', '四', '五', '六', '日'];
