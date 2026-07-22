import { display } from '@kit.ArkUI';

/**
 * 课程表布局常量接口
 */
export interface ScheduleConstants {
  /** 左侧节次列宽度（vp） */
  LEFT_COLUMN_WIDTH: number;
  /** 每节课格子高度（vp） */
  SECTION_HEIGHT: number;
  /** 日期栏高度（vp） */
  DATE_HEADER_HEIGHT: number;
  /** 课程卡片之间的间隙（vp） */
  CARD_GAP: number;
  /** 每周天数 */
  DAYS_PER_WEEK: number;
  /** 最小天列宽度（vp） */
  MIN_DAY_WIDTH: number;
  /** 最大天列宽度（vp） */
  MAX_DAY_WIDTH: number;
}

/**
 * 课程表布局常量
 */
export const SCHEDULE_CONSTANTS: ScheduleConstants = {
  LEFT_COLUMN_WIDTH: 42,
  SECTION_HEIGHT: 72,
  DATE_HEADER_HEIGHT: 56,
  CARD_GAP: 4,
  DAYS_PER_WEEK: 7,
  MIN_DAY_WIDTH: 48,
  MAX_DAY_WIDTH: 96
};

/**
 * 计算每天列的宽度
 * 优先让 7 天刚好铺满屏幕，超出范围则取最小/最大值
 */
export function calculateDayWidth(): number {
  try {
    const displaySync = display.getDefaultDisplaySync();
    const density = displaySync.densityPixels || 1;
    const screenVp = displaySync.width / density;
    // 预留页面左右内边距各 8vp
    const availableWidth = screenVp - SCHEDULE_CONSTANTS.LEFT_COLUMN_WIDTH - 16;
    // 向下取整，确保 7 列总宽度不超过可用宽度，避免水平滚动
    const rawWidth = Math.floor(availableWidth / SCHEDULE_CONSTANTS.DAYS_PER_WEEK);
    return Math.max(
      SCHEDULE_CONSTANTS.MIN_DAY_WIDTH,
      Math.min(SCHEDULE_CONSTANTS.MAX_DAY_WIDTH, rawWidth)
    );
  } catch (e) {
    // 获取屏幕失败时给一个安全默认值
    return 72;
  }
}

/**
 * 将 .NET / WinUI3 的 WeekStartDay 约定（0=周日，1=周一，…，6=周六）
 * 转换为内部约定（1=周一，…，7=周日）
 */
function normalizeWeekStartDay(weekStartDay: number): number {
  return weekStartDay === 0 ? 7 : weekStartDay;
}

/**
 * 获取指定日期所在周的周起始日期
 * @param date 指定日期
 * @param weekStartDay 周起始日，使用 WinUI3 约定：0=周日，1=周一，…，6=周六
 */
export function getWeekStartDate(date: Date, weekStartDay: number): Date {
  const startDay = normalizeWeekStartDay(weekStartDay);
  const jsStartDay = startDay === 7 ? 0 : startDay;
  let diff = date.getDay() - jsStartDay;
  if (diff < 0) {
    diff += 7;
  }
  const result = new Date(date.getTime());
  result.setDate(date.getDate() - diff);
  result.setHours(0, 0, 0, 0);
  return result;
}

/**
 * 计算目标日期相对于学期开始日期是第几周（从 1 开始）
 * @param semesterStartDate 学期开始日期
 * @param targetDate 目标日期
 * @param weekStartDay 周起始日，使用 WinUI3 约定：0=周日，1=周一，…，6=周六
 */
export function calculateWeekNumber(semesterStartDate: string, targetDate: Date, weekStartDay: number): number {
  const start = getWeekStartDate(new Date(`${semesterStartDate}T00:00:00`), weekStartDay);
  const target = getWeekStartDate(targetDate, weekStartDay);
  const diffDays = Math.floor((target.getTime() - start.getTime()) / (1000 * 60 * 60 * 24));
  return Math.floor(diffDays / 7) + 1;
}

/**
 * 获取指定周次的周起始日期
 * @param semesterStartDate 学期开始日期
 * @param weekNumber 周次，从 1 开始
 * @param weekStartDay 周起始日，使用 WinUI3 约定：0=周日，1=周一，…，6=周六
 */
export function getWeekStartDateByWeekNumber(semesterStartDate: string, weekNumber: number, weekStartDay: number): Date {
  const start = getWeekStartDate(new Date(`${semesterStartDate}T00:00:00`), weekStartDay);
  const result = new Date(start.getTime());
  result.setDate(start.getDate() + (weekNumber - 1) * 7);
  result.setHours(0, 0, 0, 0);
  return result;
}

/**
 * 根据周次、星期几和学期开始日期计算具体日期
 * @param weekIndex 周次，从 1 开始
 * @param dayOfWeek 星期几，1=周一，7=周日
 * @param semesterStartDate 学期开始日期，ISO 8601 日期部分，如 "2025-02-17"
 * @param weekStartDay 周起始日，使用 WinUI3 约定：0=周日，1=周一，…，6=周六，默认 1（周一）
 */
export function getDateByWeekAndDay(weekIndex: number, dayOfWeek: number, semesterStartDate: string, weekStartDay: number = 1): Date {
  const start = getWeekStartDateByWeekNumber(semesterStartDate, weekIndex, weekStartDay);
  const result = new Date(start.getTime());
  result.setDate(start.getDate() + (dayOfWeek - 1));
  return result;
}

/**
 * 格式化日期为 MM/dd
 * @param date 日期对象
 */
export function formatMonthDay(date: Date): string {
  const month = date.getMonth() + 1;
  const day = date.getDate();
  return `${month}/${day}`;
}

/**
 * 判断指定周次的某一天是否为今天
 * @param weekIndex 周次，从 1 开始
 * @param dayOfWeek 星期几，1=周一，7=周日
 * @param semesterStartDate 学期开始日期，ISO 8601 日期部分
 * @param weekStartDay 周起始日，使用 WinUI3 约定：0=周日，1=周一，…，6=周六，默认 1（周一）
 */
export function isToday(weekIndex: number, dayOfWeek: number, semesterStartDate: string, weekStartDay: number = 1): boolean {
  const target = getDateByWeekAndDay(weekIndex, dayOfWeek, semesterStartDate, weekStartDay);
  const now = new Date();
  return target.getFullYear() === now.getFullYear() &&
    target.getMonth() === now.getMonth() &&
    target.getDate() === now.getDate();
}

/**
 * 将 Date 格式化为本地时区 ISO 8601 字符串
 * 如 2025-03-15T10:00:00+08:00
 */
export function formatLocalISO(date: Date): string {
  const pad = (n: number): string => n.toString().padStart(2, '0');
  const y = date.getFullYear();
  const m = pad(date.getMonth() + 1);
  const d = pad(date.getDate());
  const h = pad(date.getHours());
  const min = pad(date.getMinutes());
  const s = pad(date.getSeconds());
  const offset = -date.getTimezoneOffset();
  const sign = offset >= 0 ? '+' : '-';
  const offH = pad(Math.floor(Math.abs(offset) / 60));
  const offM = pad(Math.abs(offset) % 60);
  return `${y}-${m}-${d}T${h}:${min}:${s}${sign}${offH}:${offM}`;
}

/**
 * 解析用户输入的周数文本
 * 支持：1,2,3 / 1-8 / 1-8,10,12
 * @param text 输入文本
 * @param totalWeeks 学期总周数上限
 */
export function parseWeeksText(text: string, totalWeeks: number): number[] {
  const result = new Set<number>();
  const parts = text.split(',');
  for (const part of parts) {
    const trimmed = part.trim();
    if (!trimmed) {
      continue;
    }
    if (trimmed.includes('-')) {
      const rangeParts = trimmed.split('-');
      const start = parseInt(rangeParts[0].trim(), 10);
      const end = parseInt(rangeParts[1].trim(), 10);
      if (!isNaN(start) && !isNaN(end)) {
        for (let i = Math.max(1, start); i <= Math.min(totalWeeks, end); i++) {
          result.add(i);
        }
      }
    } else {
      const week = parseInt(trimmed, 10);
      if (!isNaN(week) && week >= 1 && week <= totalWeeks) {
        result.add(week);
      }
    }
  }
  return Array.from(result).sort((a, b) => a - b);
}

/**
 * 将周次数组格式化为逗号分隔文本
 */
export function formatWeeksText(weeks: number[]): string {
  return weeks.join(',');
}
