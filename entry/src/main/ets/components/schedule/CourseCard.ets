import { Course } from '../../models/Course';
import { TimeSlot, formatTimeRange } from '../../models/TimeSlot';

/**
 * 课程卡片组件
 * 用于网格中展示课程，支持主题色半透明背景
 */
@Component
export struct CourseCard {
  /** 课程数据 */
  @Prop course: Course;
  /** 宽度 */
  @Prop cardWidth: number;
  /** 高度 */
  @Prop cardHeight: number;
  /** 主题色 */
  @Prop brandColor: string = '#007DFF';
  /** 是否灰显（非本周课程） */
  @Prop dimmed: boolean = false;
  /** 共享元素转场 ID，为空则不参与转场 */
  @Prop transitionId: string = '';
  /** 点击回调 */
  onCardClick?: () => void;
  /** 长按编辑回调 */
  onEdit?: () => void;
  /** 长按删除回调 */
  onDelete?: () => void;

  /**
   * 将主题色转换为半透明背景色
   */
  private getCardBackground(): string {
    if (this.dimmed) {
      return 'rgba(160, 160, 160, 0.28)';
    }
    // 取主题色前 6 位，附加 50% 透明度，提升文字对比度
    const hex = this.brandColor.replace('#', '');
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);
    return `rgba(${r}, ${g}, ${b}, 0.50)`;
  }

  /**
   * 卡片文字统一使用白色，灰显时降低不透明度
   */
  private getCardTextColor(): ResourceColor {
    return this.dimmed ? 'rgba(255, 255, 255, 0.55)' : Color.White;
  }

  /**
   * 灰显时使用灰色边框，否则使用主题色
   */
  private getCardBorderColor(): ResourceColor {
    return this.dimmed ? 'rgba(150, 150, 150, 0.35)' : this.brandColor;
  }

  /**
   * 长按弹出的上下文菜单
   * 根容器保持透明，毛玻璃质感由 bindContextMenu 的 backgroundBlurStyle 统一提供，
   * 避免系统菜单背板与自定义 Builder 背景叠加导致发白、分层。
   */
  @Builder
  CourseContextMenu() {
    Column({ space: 4 }) {
      this.MenuRow($r('sys.symbol.square_and_pencil'), '编辑课程', $r('sys.color.ohos_id_color_primary'), () => {
        this.onEdit?.();
      })
      this.MenuRow($r('sys.symbol.ohos_trash'), '删除课程', '#FF3B30', () => {
        this.onDelete?.();
      })
    }
    .width(160)
    .padding(8)
    .backgroundColor(Color.Transparent)
    .borderRadius(16)
  }

  @Builder
  MenuRow(icon: Resource, label: string, color: ResourceColor, action: () => void) {
    Row() {
      SymbolGlyph(icon)
        .fontSize(18)
        .fontColor([color])
        .width(22)
        .height(22)

      Text(label)
        .fontSize(15)
        .fontColor(color)
        .layoutWeight(1)
        .margin({ left: 8 })
    }
    .width('100%')
    .height(44)
    .padding({ left: 12, right: 12 })
    .borderRadius(10)
    .backgroundColor('rgba(255, 255, 255, 0.18)')
    .backgroundBlurStyle(BlurStyle.Thin)
    .stateStyles({
      pressed: {
        backgroundColor: 'rgba(255, 255, 255, 0.42)'
      }
    })
    .onClick(action)
  }

  build() {
    Column({ space: 2 }) {
      Text(this.course.name)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getCardTextColor())
        .textAlign(TextAlign.Center)
        .maxLines(99)
        .textShadow({ radius: 2, color: 'rgba(0,0,0,0.25)', offsetX: 0, offsetY: 1 })
        .width('100%')

      if (this.course.location) {
        Text(this.course.location)
          .fontSize(11)
          .fontColor(this.getCardTextColor())
          .textAlign(TextAlign.Center)
          .maxLines(99)
          .textShadow({ radius: 2, color: 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: 1 })
          .width('100%')
      }

      Text(this.course.teacher)
        .fontSize(11)
        .fontColor(this.getCardTextColor())
        .opacity(this.dimmed ? 0.8 : 0.9)
        .textAlign(TextAlign.Center)
        .maxLines(99)
        .textShadow({ radius: 2, color: 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: 1 })
        .width('100%')
    }
    .width(this.cardWidth)
    .height(this.cardHeight)
    .padding(4)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.getCardBackground())
    .backgroundBlurStyle(BlurStyle.Thin)
    .borderRadius(8)
    .border({ width: 0.5, color: this.getCardBorderColor() })
    .shadow({ radius: this.dimmed ? 0 : 6, color: 'rgba(0,0,0,0.12)', offsetX: 0, offsetY: this.dimmed ? 0 : 2 })
    .opacity(this.dimmed ? 0.55 : 1)
    .zIndex(1)
    // follow: true 让始终留在树上的原卡片跟随共享动画，系统会在转场期间自动隐藏它并创建替身
    .geometryTransition(this.transitionId, { follow: true })
    .transition(TransitionEffect.OPACITY)
    .onClick(() => {
      this.onCardClick?.();
    })
    .bindContextMenu(this.CourseContextMenu(), ResponseType.LongPress, {
      backgroundColor: 'rgba(255, 255, 255, 0.12)',
      backgroundBlurStyle: BlurStyle.Regular
    })
  }
}

/**
 * 课程详情卡片（全屏弹层中使用）
 * 与普通卡片共享 geometryTransition id，实现一镜到底放大效果
 */
@Component
export struct CourseDetailCard {
  /** 课程数据 */
  @Prop course: Course;
  /** 节次列表，用于格式化时间 */
  @Prop timeSlots: TimeSlot[];
  /** 主题色 */
  @Prop brandColor: string = '#007DFF';
  /** 共享元素转场 ID */
  @Prop transitionId: string = '';
  /** 关闭回调 */
  onClose?: () => void;
  /** 编辑回调 */
  onEdit?: () => void;

  private getCardBackground(): string {
    const hex = this.brandColor.replace('#', '');
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);
    return `rgba(${r}, ${g}, ${b}, 0.22)`;
  }

  build() {
    Column() {
      // 顶部：课程名称与关闭
      Row() {
        Text(this.course.name)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.brandColor)
          .layoutWeight(1)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(24)
          .fontColor([$r('sys.color.ohos_id_color_primary')])
          .width(40)
          .height(40)
          .onClick(() => {
            this.onClose?.();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      // 分隔线
      Divider()
        .strokeWidth(0.5)
        .color($r('sys.color.ohos_id_color_fourth'))
        .margin({ top: 16, bottom: 16 })

      // 详情信息行
      this.DetailRow('教师', this.course.teacher)
      this.DetailRow('地点', this.course.location)
      this.DetailRow('时间', formatTimeRange(this.timeSlots, this.course.startSection, this.course.endSection))
      this.DetailRow('周次', this.formatWeeks())

      if (this.course.description) {
        Divider()
          .strokeWidth(0.5)
          .color($r('sys.color.ohos_id_color_fourth'))
          .margin({ top: 16, bottom: 16 })

        Text('备注')
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_secondary'))
          .width('100%')

        Text(this.course.description)
          .fontSize(15)
          .fontColor($r('sys.color.ohos_id_color_primary'))
          .margin({ top: 6 })
          .width('100%')
      }

      // 编辑按钮
      Button('编辑课程', { type: ButtonType.Capsule })
        .width('100%')
        .height(40)
        .backgroundColor(this.brandColor)
        .fontColor(Color.White)
        .margin({ top: 20 })
        .onClick(() => {
          this.onEdit?.();
        })
    }
    .width('86%')
    .padding(24)
    .backgroundColor(this.getCardBackground())
    .borderRadius(20)
    .border({ width: 1, color: this.brandColor })
    .shadow({ radius: 24, color: 'rgba(0,0,0,0.15)', offsetX: 0, offsetY: 8 })
    .clip(true)
    .onClick(() => {})
    .geometryTransition(this.transitionId, { follow: false })
    .transition(TransitionEffect.OPACITY)
  }

  @Builder
  DetailRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor($r('sys.color.ohos_id_color_secondary'))
        .width(48)

      Text(value)
        .fontSize(15)
        .fontColor($r('sys.color.ohos_id_color_primary'))
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height(34)
    .alignItems(VerticalAlign.Center)
  }

  private formatWeeks(): string {
    if (this.course.weeks.length === 0) {
      return '无';
    }
    const maxWeek = Math.max(...this.course.weeks);
    return `第 ${this.course.weeks.length} 周有课（至第 ${maxWeek} 周）`;
  }
}
