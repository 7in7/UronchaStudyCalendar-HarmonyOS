import { curves } from '@kit.ArkUI';

/**
 * 周切换器组件
 * 显示当前周次，支持前后切换和返回本周
 */
@Component
export struct WeekSelector {
  /** 当前选中的周次 */
  @Prop currentWeek: number;
  /** 总周数 */
  @Prop totalWeeks: number = 20;
  /** 主题色，用于胶囊按钮背景 */
  @Prop brandColor: string = '#007DFF';
  /** 点击左箭头 */
  onPrevWeek?: () => void;
  /** 点击右箭头 */
  onNextWeek?: () => void;
  /** 点击回到本周 */
  onBackToToday?: () => void;

  build() {
    Row() {
      // 左箭头：上一周（胶囊背景）
      Stack({ alignContent: Alignment.Center }) {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(22)
          .fontColor([Color.White])
          .width(22)
          .height(22)
      }
      .width(40)
      .height(40)
      .backgroundColor(this.brandColor)
      .borderRadius(20)
      .onClick(() => {
        if (this.currentWeek > 1) {
          this.onPrevWeek?.();
        }
      })

      // 当前周次文本
      Column() {
        Text(`第${this.currentWeek}周`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.ohos_id_color_primary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      // 右箭头：下一周（胶囊背景）
      Stack({ alignContent: Alignment.Center }) {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(22)
          .fontColor([Color.White])
          .width(22)
          .height(22)
      }
      .width(40)
      .height(40)
      .backgroundColor(this.brandColor)
      .borderRadius(20)
      .onClick(() => {
        if (this.currentWeek < this.totalWeeks) {
          this.onNextWeek?.();
        }
      })

      // 回到本周（主题色胶囊按钮）
      Button('今天', { type: ButtonType.Capsule })
        .height(32)
        .padding({ left: 14, right: 14 })
        .backgroundColor(this.brandColor)
        .fontColor(Color.White)
        .fontSize(13)
        .margin({ left: 8 })
        .onClick(() => {
          this.onBackToToday?.();
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 16 })
    .backgroundColor(Color.Transparent)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .animation({
      duration: 260,
      curve: curves.springMotion(0.28, 0.65)
    })
  }
}
