import { curves } from '@kit.ArkUI';

/**
 * FAB 展开菜单项数据
 */
interface FabMenuItem {
  id: string;
  symbol: Resource;
  label: string;
}

/**
 * 课程表右侧悬浮按钮菜单
 * 点击主按钮展开手动添加、AI 导入等入口
 */
@Component
export struct ScheduleFabMenu {
  /** 主题色 */
  @Prop brandColor: string = '#007DFF';
  /** 底部偏移量（vp），用于避让 TabBar */
  @Prop bottomOffset: number = 0;
  /** 菜单项点击回调 */
  onItemClick?: (id: string) => void;

  @State isExpanded: boolean = false;

  private menuItems: FabMenuItem[] = [
    { id: 'add', symbol: $r('sys.symbol.plus'), label: '手动添加' },
    { id: 'web_import', symbol: $r('sys.symbol.arrow_2_circlepath'), label: '教务导入' },
    { id: 'ai_import', symbol: $r('sys.symbol.star'), label: 'AI 导入' }
  ];

  build() {
    Column({ space: 12 }) {
      // 展开的菜单项
      ForEach(this.menuItems, (item: FabMenuItem, index: number) => {
        Row({ space: 8 }) {
          Text(item.label)
            .fontSize(13)
            .fontColor(Color.White)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('rgba(0, 0, 0, 0.6)')
            .borderRadius(8)

          Column() {
            SymbolGlyph(item.symbol)
              .fontSize(20)
              .fontColor([Color.White])
          }
          .width(48)
          .height(48)
          .backgroundColor(this.brandColor)
          .borderRadius(24)
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: 3 })
          .onClick(() => {
            this.onItemClick?.(item.id);
            this.toggleExpanded();
          })
        }
        .opacity(this.isExpanded ? 1 : 0)
        .translate({ y: this.isExpanded ? 0 : 20 })
        .animation({
          duration: 260,
          curve: curves.springMotion(0.28, 0.65),
          delay: index * 40
        })
      }, (item: FabMenuItem) => item.id)

      // 主按钮
      Column() {
        SymbolGlyph(this.isExpanded ? $r('sys.symbol.xmark') : $r('sys.symbol.plus'))
          .fontSize(26)
          .fontColor([Color.White])
          .rotate({ angle: this.isExpanded ? 45 : 0 })
          .animation({
            duration: 260,
            curve: curves.springMotion(0.28, 0.65)
          })
      }
      .width(56)
      .height(56)
      .backgroundColor(this.brandColor)
      .borderRadius(28)
      .shadow({ radius: 10, color: 'rgba(0,0,0,0.25)', offsetX: 0, offsetY: 4 })
      .onClick(() => {
        this.toggleExpanded();
      })
    }
    .alignItems(HorizontalAlign.End)
    .padding({ bottom: 16 + this.bottomOffset, right: 16 })
  }

  private toggleExpanded(): void {
    this.isExpanded = !this.isExpanded;
  }
}
