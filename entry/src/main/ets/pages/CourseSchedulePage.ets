/**
 * 课程表页面占位页
 * 仅保留页面框架，业务内容待实现
 */
@Entry
@Component
export struct CourseSchedulePage {
  build() {
    Column() {
      Column({ space: 4 }) {
        Text('课程表')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.ohos_id_color_primary'))
          .width('100%')

        Text('课程表内容待实现')
          .fontSize(13)
          .fontColor($r('sys.color.ohos_id_color_secondary'))
          .width('100%')
      }
      .width('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)

      List() {
        ListItem() {
          Column() {
            SymbolGlyph($r('sys.symbol.calendar'))
              .fontSize(48)
              .fontColor([$r('sys.color.ohos_id_color_secondary')])
              .margin({ bottom: 12 })

            Text('暂无课程')
              .fontSize(16)
              .fontColor($r('sys.color.ohos_id_color_secondary'))
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        }

        ListItem() {
          Column() {
            Text('— 到底了 —')
              .fontSize(12)
              .fontColor($r('sys.color.ohos_id_color_secondary'))
              .margin({ top: 16, bottom: 32 })
          }
          .width('100%')
        }
      }
      .width('100%')
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
  }
}
