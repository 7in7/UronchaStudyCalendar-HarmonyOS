/**
 * 首页占位页
 * 仅保留页面框架，业务内容待实现
 */
@Entry
@Component
export struct HomePage {
  build() {
    List() {
      ListItem() {
        Column() {
          Text('首页')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.ohos_id_color_primary'))
            .margin({ top: 16, bottom: 4 })

          Text('首页内容待实现')
            .fontSize(13)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
            .margin({ bottom: 8 })
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .alignItems(HorizontalAlign.Start)
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
    .height('100%')
    .backgroundColor(Color.Transparent)
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Auto)
  }
}
