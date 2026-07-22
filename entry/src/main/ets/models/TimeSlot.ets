/**
 * 节次时间段模型
 * 描述一天中第几节课的名称和起止时间
 */
export interface TimeSlot {
  /** 节次编号：1, 2, 3 ... */
  sectionNumber: number;
  /** 节次名称，如"第1节" */
  name: string;
  /** 开始时间，格式 HH:mm */
  startTime: string;
  /** 结束时间，格式 HH:mm */
  endTime: string;
}

/**
 * 默认节次时间段配置
 * 与 WinUI3 端默认 11 节课保持一致
 */
export const DEFAULT_TIME_SLOTS: TimeSlot[] = [
  { sectionNumber: 1, name: '第1节', startTime: '08:00', endTime: '08:45' },
  { sectionNumber: 2, name: '第2节', startTime: '08:55', endTime: '09:40' },
  { sectionNumber: 3, name: '第3节', startTime: '10:00', endTime: '10:45' },
  { sectionNumber: 4, name: '第4节', startTime: '10:55', endTime: '11:40' },
  { sectionNumber: 5, name: '第5节', startTime: '14:00', endTime: '14:45' },
  { sectionNumber: 6, name: '第6节', startTime: '14:55', endTime: '15:40' },
  { sectionNumber: 7, name: '第7节', startTime: '15:50', endTime: '16:35' },
  { sectionNumber: 8, name: '第8节', startTime: '16:45', endTime: '17:30' },
  { sectionNumber: 9, name: '第9节', startTime: '19:00', endTime: '19:45' },
  { sectionNumber: 10, name: '第10节', startTime: '19:55', endTime: '20:40' },
  { sectionNumber: 11, name: '第11节', startTime: '20:50', endTime: '21:35' }
];

/**
 * 获取指定节次的起止时间范围字符串
 * @param slots 节次列表
 * @param startSection 起始节次
 * @param endSection 结束节次
 */
export function formatTimeRange(slots: TimeSlot[], startSection: number, endSection: number): string {
  const start = slots.find(s => s.sectionNumber === startSection);
  const end = slots.find(s => s.sectionNumber === endSection);
  if (!start || !end) {
    return '';
  }
  return `${start.startTime} - ${end.endTime}`;
}
