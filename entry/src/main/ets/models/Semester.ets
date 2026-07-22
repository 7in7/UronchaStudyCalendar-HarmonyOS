/**
 * 学期数据模型
 * 对应 SQLite semesters 表
 */
export interface Semester {
  /** UUID v4 */
  id: string;
  /** 学期名称，如 "2024-2025学年第二学期" */
  name: string;
  /** 开学日期，ISO 8601 日期部分，如 "2025-02-17" */
  startDate: string;
  /** 总周数，默认 20 */
  totalWeeks: number;
  /** 每周起始日：0=周日, 1=周一, ..., 6=周六，默认 1 */
  weekStartDay: number;
  /** 是否为当前学期 */
  isCurrent: boolean;
  /** 创建时间，ISO 8601 */
  createdAt: string;
  /** 更新时间，ISO 8601 */
  updatedAt: string;
}
