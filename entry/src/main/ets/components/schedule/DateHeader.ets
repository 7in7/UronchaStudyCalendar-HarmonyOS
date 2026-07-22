import { DAY_LABELS } from '../../models/Course';
import { formatMonthDay, getDateByWeekAndDay, isToday } from '../../utils/ScheduleUtils';

/**
 * 日期栏组件
 * 显示周一~周日及对应日期，高亮今天
 */
@Component
export struct DateHeader {
  /** 当前选中的周次 */
  @Prop currentWeek: number;
  /** 每天列宽度 */
  @Prop dayWidth: number;
  /** 日期栏高度 */
  @Prop headerHeight: number;
  /** 主题色，用于高亮今天 */
  @Prop brandColor: string = '#007DFF';
  /** 学期开始日期，用于计算日期 */
  @Prop semesterStartDate: string = '2025-02-17';
  /** 每周起始日：0=周日，1=周一，…，6=周六，默认 1（周一） */
  @Prop weekStartDay: number = 1;

  build() {
    Row() {
      ForEach(DAY_LABELS, (label: string, index: number) => {
        Column() {
          Text(`周${label}`)
            .fontSize(12)
            .fontWeight(isToday(this.currentWeek, index + 1, this.semesterStartDate, this.weekStartDay) ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(isToday(this.currentWeek, index + 1, this.semesterStartDate, this.weekStartDay) ? this.brandColor : $r('sys.color.ohos_id_color_secondary'))

          Text(formatMonthDay(getDateByWeekAndDay(this.currentWeek, index + 1, this.semesterStartDate, this.weekStartDay)))
            .fontSize(13)
            .fontWeight(isToday(this.currentWeek, index + 1, this.semesterStartDate, this.weekStartDay) ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(isToday(this.currentWeek, index + 1, this.semesterStartDate, this.weekStartDay) ? Color.White : $r('sys.color.ohos_id_color_primary'))
            .margin({ top: 4 })
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor(isToday(this.currentWeek, index + 1, this.semesterStartDate, this.weekStartDay) ? this.brandColor : Color.Transparent)
            .borderRadius(10)
        }
        .width(this.dayWidth)
        .height(this.headerHeight)
        .justifyContent(FlexAlign.Center)
      }, (label: string, index: number) => `${label}_${index}`)
    }
    .width(this.dayWidth * DAY_LABELS.length)
    .height(this.headerHeight)
    .backgroundColor(Color.Transparent)
  }
}
