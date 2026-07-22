import { curves } from '@kit.ArkUI';
import { Event, EventActionType, getEventStartDate } from '../models/Event';
import { TimelineNodeType } from '../models/TimelineNode';

/**
 * 长期规划页面
 * 采用水平横向时间轴布局，模拟 WinUI3 端设计
 * 背景透明，由 Index.ets 全局背景层统一处理
 */
@Entry
@Component
export struct LongPlanPage {
  /** 主题品牌色 */
  @StorageLink('brandColor') brandColor: string = '#007DFF';
  /** 当前选中月份索引（相对于月份列表起始） */
  @State selectedMonthIndex: number = 0;
  /** 时间轴水平滚动偏移 */
  @State timelineScrollOffset: number = 0;
  /** 是否展开添加菜单 */
  @State isFabExpanded: boolean = false;
  /** 当前时间 */
  private readonly today: Date = new Date();
  /** 时间轴滚动控制器 */
  private timelineScroller: Scroller = new Scroller();
  /** 月份列表 */
  private readonly monthList: Date[] = this.generateMonthList();
  /** 每个月宽度（vp） */
  private readonly monthWidth: number = 140;
  /** 每天宽度（vp） */
  private readonly dayWidth: number = this.monthWidth / 30;
  /** 时间轴上下内边距 */
  private readonly timelinePaddingV: number = 32;
  /** 时间轴高度 */
  private readonly timelineHeight: number = 280;

  /**
   * 生成月份列表（当前月前后各 3 个月）
   */
  private generateMonthList(): Date[] {
    const months: Date[] = [];
    const center = new Date(this.today.getFullYear(), this.today.getMonth(), 1);
    for (let i = -3; i <= 3; i++) {
      const d = new Date(center.getFullYear(), center.getMonth() + i, 1);
      months.push(d);
    }
    return months;
  }

  /** Mock 事件数据 */
  private get mockEvents(): Event[] {
    return [
      {
        id: 'event-1',
        name: '英语四级',
        detail: '全国大学英语四级笔试',
        action: {
          type: EventActionType.NONE,
          target: '',
          parameters: '',
          description: ''
        },
        timelineNodes: [
          {
            nodeId: 1,
            type: TimelineNodeType.START,
            date: '2026-09-01T00:00:00+08:00',
            nodeName: '报名开始',
            icon: 'sys.symbol.square_and_pencil'
          },
          {
            nodeId: 2,
            type: TimelineNodeType.CUSTOM,
            date: '2026-12-19T09:00:00+08:00',
            nodeName: '笔试考试',
            icon: 'sys.symbol.calendar'
          }
        ],
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      },
      {
        id: 'event-2',
        name: '数学竞赛',
        detail: '全国大学生数学建模竞赛',
        action: {
          type: EventActionType.NONE,
          target: '',
          parameters: '',
          description: ''
        },
        timelineNodes: [
          {
            nodeId: 1,
            type: TimelineNodeType.START,
            date: '2026-09-15T00:00:00+08:00',
            nodeName: '报名截止',
            icon: 'sys.symbol.square_and_pencil'
          },
          {
            nodeId: 2,
            type: TimelineNodeType.CUSTOM,
            date: '2026-10-10T08:00:00+08:00',
            nodeName: '正式比赛',
            icon: 'sys.symbol.calendar'
          }
        ],
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      },
      {
        id: 'event-3',
        name: '期末考试周',
        detail: '本学期期末考试周',
        action: {
          type: EventActionType.NONE,
          target: '',
          parameters: '',
          description: ''
        },
        timelineNodes: [
          {
            nodeId: 1,
            type: TimelineNodeType.START,
            date: '2026-07-25T00:00:00+08:00',
            nodeName: '开始',
            icon: 'sys.symbol.rocket'
          },
          {
            nodeId: 2,
            type: TimelineNodeType.END,
            date: '2026-07-31T23:59:59+08:00',
            nodeName: '结束',
            icon: 'sys.symbol.checkmark_circle'
          }
        ],
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      }
    ];
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 顶部标题区
        this.HeaderBuilder()

        // 月份选择器
        this.MonthSelectorBuilder()

        // 水平时间轴主体
        this.TimelineBuilder()

        // 底部占位，避免 FAB 遮挡
        Blank().height(88)
      }
      .width('100%')
      .height('100%')

      // 底部 FAB 按钮组
      this.FabGroupBuilder()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
  }

  /**
   * 顶部标题区
   */
  @Builder
  HeaderBuilder() {
    Row() {
      Column({ space: 2 }) {
        Text('今天是 英语四级笔试')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.ohos_id_color_primary'))

        Text('时光正好，快去复习吧')
          .fontSize(13)
          .fontColor($r('sys.color.ohos_id_color_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      SymbolGlyph($r('sys.symbol.xmark'))
        .fontSize(22)
        .fontColor([$r('sys.color.ohos_id_color_primary')])
        .onClick(() => {
          // 关闭按钮：切换到课程表页签
          AppStorage.setOrCreate('currentIndex', 2);
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('rgba(255, 255, 255, 0.18)')
    .backgroundBlurStyle(BlurStyle.Thin)
  }

  /**
   * 月份选择器
   */
  @Builder
  MonthSelectorBuilder() {
    Scroll() {
      Row({ space: 24 }) {
        ForEach(this.monthList, (month: Date, index: number) => {
          Text(`${month.getMonth() + 1}月`)
            .fontSize(index === this.selectedMonthIndex ? 18 : 15)
            .fontWeight(index === this.selectedMonthIndex ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(index === this.selectedMonthIndex ? this.brandColor : $r('sys.color.ohos_id_color_primary'))
            .onClick(() => {
              this.selectedMonthIndex = index;
              this.scrollToMonth(index);
            })
        }, (month: Date) => `${month.getFullYear()}-${month.getMonth()}`)
      }
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    }
    .width('100%')
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .backgroundColor('rgba(255, 255, 255, 0.12)')
  }

  /**
   * 水平时间轴主体
   */
  @Builder
  TimelineBuilder() {
    Stack({ alignContent: Alignment.TopStart }) {
      Scroll(this.timelineScroller) {
        Stack({ alignContent: Alignment.TopStart }) {
          // 月份分栏背景
          this.MonthColumnsBuilder()

          // 今天竖线
          this.TodayIndicatorBuilder()

          // 事件节点
          this.EventNodesBuilder()
        }
        .width(this.monthList.length * this.monthWidth)
        .height(this.timelineHeight)
      }
      .width('100%')
      .height(this.timelineHeight)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .onDidScroll((xOffset: number, yOffset: number) => {
        this.timelineScrollOffset = xOffset;
        this.updateSelectedMonthByScroll(xOffset);
      })
    }
    .width('100%')
    .height(this.timelineHeight)
  }

  /**
   * 月份分栏背景
   */
  @Builder
  MonthColumnsBuilder() {
    Row() {
      ForEach(this.monthList, (month: Date) => {
        Column() {
          // 月份标签背景
          Text(`${month.getMonth() + 1}月`)
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
            .margin({ top: 8 })

          // 日期刻度线（简化显示 1、10、20、30 日）
          Row() {
            ForEach([1, 10, 20, 30], (day: number) => {
              Column() {
                Text(`${day}`)
                  .fontSize(9)
                  .fontColor($r('sys.color.ohos_id_color_tertiary'))

                Column()
                  .width(1)
                  .height(8)
                  .backgroundColor('rgba(0, 0, 0, 0.08)')
                  .margin({ top: 4 })
              }
              .width(this.monthWidth / 4)
              .alignItems(HorizontalAlign.Center)
            }, (day: number) => day.toString())
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ top: 12 })
        }
        .width(this.monthWidth)
        .height('100%')
        .border({ width: { right: 0.5 }, color: 'rgba(0, 0, 0, 0.06)' })
      }, (month: Date) => `${month.getFullYear()}-${month.getMonth()}`)
    }
    .width(this.monthList.length * this.monthWidth)
    .height(this.timelineHeight)
  }

  /**
   * 今天指示器（竖线 + 标签）
   */
  @Builder
  TodayIndicatorBuilder() {
    Column() {
      // 今天标签
      Text(`今天 ${this.formatDate(this.today)}`)
        .fontSize(11)
        .fontColor(Color.White)
        .backgroundColor('#FF3B30')
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .borderRadius(12)
        .margin({ left: -40 })

      // 竖线
      Column()
        .width(2)
        .height(this.timelineHeight - 36)
        .backgroundColor('#FF3B30')
        .margin({ top: 4 })
    }
    .position({ x: this.calculateTodayX() })
    .height(this.timelineHeight)
  }

  /**
   * 事件节点层
   */
  @Builder
  EventNodesBuilder() {
    Stack({ alignContent: Alignment.TopStart }) {
      ForEach(this.mockEvents, (event: Event, index: number) => {
        this.EventNodeBuilder(event, index)
      }, (event: Event) => event.id)
    }
    .width(this.monthList.length * this.monthWidth)
    .height(this.timelineHeight)
  }

  /**
   * 单个事件节点
   */
  @Builder
  EventNodeBuilder(event: Event, index: number) {
    Column({ space: 4 }) {
      SymbolGlyph($r('sys.symbol.calendar'))
        .fontSize(24)
        .fontColor([this.brandColor])
        .width(40)
        .height(40)
        .backgroundColor('rgba(255, 255, 255, 0.45)')
        .backgroundBlurStyle(BlurStyle.Thin)
        .borderRadius(20)

      Text(event.name)
        .fontSize(12)
        .fontColor($r('sys.color.ohos_id_color_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        .backgroundColor('rgba(255, 255, 255, 0.35)')
        .borderRadius(8)
    }
    .position({
      x: this.calculateDateX(getEventStartDate(event)) - 20,
      y: 80 + (index % 3) * 72
    })
    .alignItems(HorizontalAlign.Center)
    .width(80)
    .onClick(() => {
      // TODO: 打开事件详情/编辑
    })
  }

  /**
   * 底部 FAB 按钮组
   */
  @Builder
  FabGroupBuilder() {
    Row({ space: 16 }) {
      // 回到今天 / 折叠按钮
      Column() {
        SymbolGlyph($r('sys.symbol.chevron_down'))
          .fontSize(20)
          .fontColor([$r('sys.color.ohos_id_color_primary')])
      }
      .width(48)
      .height(48)
      .borderRadius(24)
      .backgroundColor('rgba(255, 255, 255, 0.45)')
      .backgroundBlurStyle(BlurStyle.Regular)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.scrollToToday();
      })

      // 添加按钮
      Column() {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(24)
          .fontColor([Color.White])
      }
      .width(56)
      .height(56)
      .borderRadius(28)
      .backgroundColor(this.brandColor)
      .justifyContent(FlexAlign.Center)
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.15)', offsetY: 4 })
      .onClick(() => {
        // TODO: 打开添加事件 bindSheet
      })
    }
    .margin({ right: 20, bottom: 24 })
  }

  /**
   * 滚动到指定月份
   */
  private scrollToMonth(index: number): void {
    const targetOffset = Math.max(0, Math.min(index * this.monthWidth, this.monthList.length * this.monthWidth));
    this.timelineScroller.scrollTo({
      xOffset: targetOffset,
      yOffset: 0,
      animation: { duration: 320, curve: curves.springMotion(0.28, 0.65) }
    });
  }

  /**
   * 滚动到今天
   */
  private scrollToToday(): void {
    const todayX = this.calculateTodayX();
    this.timelineScroller.scrollTo({
      xOffset: Math.max(0, todayX - 80),
      yOffset: 0,
      animation: { duration: 320, curve: curves.springMotion(0.28, 0.65) }
    });
  }

  /**
   * 根据滚动偏移更新选中月份
   */
  private updateSelectedMonthByScroll(offset: number): void {
    const index = Math.round(offset / this.monthWidth);
    if (index >= 0 && index < this.monthList.length && index !== this.selectedMonthIndex) {
      this.selectedMonthIndex = index;
    }
  }

  /**
   * 计算今天对应的 X 坐标
   */
  private calculateTodayX(): number {
    return this.calculateDateX(this.today);
  }

  /**
   * 计算指定日期对应的 X 坐标
   */
  private calculateDateX(date: Date): number {
    const start = this.monthList[0];
    if (!start) return 0;
    const startTime = start.getTime();
    const targetTime = new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
    const diffDays = Math.floor((targetTime - startTime) / (1000 * 60 * 60 * 24));
    return diffDays * this.dayWidth;
  }

  /**
   * 格式化日期为 yyyy年M月d日
   */
  private formatDate(date: Date): string {
    return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`;
  }
}
