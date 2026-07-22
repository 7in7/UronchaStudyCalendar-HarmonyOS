import { Course, DAY_LABELS } from '../../models/Course';
import { TimeSlot } from '../../models/TimeSlot';
import { SCHEDULE_CONSTANTS } from '../../utils/ScheduleUtils';
import { CourseCard, CourseDetailCard } from './CourseCard';
import { DateHeader } from './DateHeader';

/**
 * 课程表网格主体组件
 * 彻底放弃 Grid/GridItem，改用 Stack + position 绝对定位
 * 避免 GridItem 行列索引在不同 API 版本表现不一致导致只显示一个卡片
 */
@Component
export struct ScheduleGrid {
  /** 当前选中的周次 */
  @Prop currentWeek: number;
  /** 课程列表 */
  @Prop courses: Course[];
  /** 节次列表 */
  @Prop timeSlots: TimeSlot[];
  /** 主题色 */
  @Prop brandColor: string = '#007DFF';
  /** 每天列宽度 */
  @Prop dayWidth: number = 72;
  /** 学期开始日期，用于日期栏 */
  @Prop semesterStartDate: string = '2025-02-17';
  /** 每周起始日：0=周日，1=周一，…，6=周六，默认 1（周一） */
  @Prop weekStartDay: number = 1;
  /** 编辑课程回调 */
  onEditCourse?: (course: Course) => void;
  /** 删除课程回调 */
  onDeleteCourse?: (id: string) => void;

  /** 当前选中的课程（用于详情弹层） */
  @State selectedCourse?: Course = undefined;
  /** 是否显示课程详情弹层 */
  @State showDetail: boolean = false;

  /** 单节课高度 */
  private readonly sectionHeight: number = SCHEDULE_CONSTANTS.SECTION_HEIGHT;
  /** 节次列宽度 */
  private readonly leftColumnWidth: number = SCHEDULE_CONSTANTS.LEFT_COLUMN_WIDTH;
  /** 卡片间隙 */
  private readonly cardGap: number = SCHEDULE_CONSTANTS.CARD_GAP;
  /** 日期栏高度 */
  private readonly dateHeaderHeight: number = SCHEDULE_CONSTANTS.DATE_HEADER_HEIGHT;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 课表主体
      Column() {
        // 顶部冻结日期行：左侧占位 + 右侧日期栏
        Row() {
          // 与左侧节次列对齐的占位
          Column()
            .width(this.leftColumnWidth)
            .height(this.dateHeaderHeight)

          // 日期栏（不随下方内容滚动）
          DateHeader({
            currentWeek: this.currentWeek,
            dayWidth: this.dayWidth,
            headerHeight: this.dateHeaderHeight,
            brandColor: this.brandColor,
            semesterStartDate: this.semesterStartDate,
            weekStartDay: this.weekStartDay
          })
        }
        .width('100%')
        .height(this.dateHeaderHeight)
        .backgroundColor('rgba(255, 255, 255, 0.25)')
        .backgroundBlurStyle(BlurStyle.Thin)
        .borderRadius(12)

        // 下方主体：左侧节次列 + 右侧可垂直滚动网格
        Row() {
          // 左侧节次列（固定）
          this.SectionColumn()

          // 右侧内容区（7 列总宽固定，课程卡片绝对定位）
          Scroll() {
            Stack({ alignContent: Alignment.TopStart }) {
              // 网格背景（底层）
              this.GridBackground()

              // 课程卡片层：Stack + position 绝对定位
              // 只渲染当前周的课程，避免跨周卡片堆积；
              // transitionId 携带 currentWeek，防止 Swiper 多页中相同 course.id 冲突。
              // 共享元素转场期间，原卡片始终留在组件树中，由 geometryTransition(follow: true)
              // 自动隐藏原卡片并驱动替身动画，避免 in/out 匹配失败。
              ForEach(
                this.getCurrentWeekCourses(),
                (course: Course) => {
                  CourseCard({
                    course: course,
                    cardWidth: Math.max(20, this.dayWidth - this.cardGap * 2),
                    cardHeight: Math.max(20, this.calculateCardHeight(course)),
                    brandColor: this.brandColor,
                    transitionId: `course_${course.id}_week_${this.currentWeek}`,
                    onCardClick: () => {
                      this.openCourseDetail(course);
                    },
                    onEdit: () => {
                      this.onEditCourse?.(course);
                    },
                    onDelete: () => {
                      this.onDeleteCourse?.(course.id);
                    }
                  })
                    .position({
                      x: this.cardGap + (course.dayOfWeek - 1) * this.dayWidth,
                      y: (course.startSection - 1) * this.sectionHeight + this.cardGap
                    })
                    .zIndex(10)
                },
                (course: Course) => `${course.id}_${course.updatedAt}`
              )

              // 空状态提示（基于当前周过滤后的课程）
              if (this.getCurrentWeekCourses().length === 0) {
                this.EmptyStateBuilder()
              }
            }
            .width(this.dayWidth * DAY_LABELS.length)
            .height(this.timeSlots.length * this.sectionHeight)
            .backgroundColor(Color.Transparent)
          }
          .scrollable(ScrollDirection.Vertical)
          .width(this.dayWidth * DAY_LABELS.length)
          .height('100%')
          .scrollBar(BarState.Auto)
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)

      // 课程详情浮层：与课程卡片位于同一组件树中，
      // 通过 if 控制上下树，使 geometryTransition 在关闭时也能执行退场动画。
      if (this.showDetail) {
        this.CourseDetailOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
  }

  /**
   * 左侧节次列
   */
  @Builder
  SectionColumn() {
    Column() {
      // 节次列表
      ForEach(this.timeSlots, (slot: TimeSlot) => {
        Column({ space: 1 }) {
          Text(`${slot.sectionNumber}`)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.ohos_id_color_primary'))

          Text(slot.startTime)
            .fontSize(9)
            .fontColor($r('sys.color.ohos_id_color_secondary'))

          Text(slot.endTime)
            .fontSize(9)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
        }
        .width(this.leftColumnWidth)
        .height(this.sectionHeight)
        .justifyContent(FlexAlign.Center)
        .border({ width: { bottom: 0.5 }, color: 'rgba(0, 0, 0, 0.06)' })
      }, (slot: TimeSlot) => slot.sectionNumber.toString())
    }
    .width(this.leftColumnWidth)
    .height(this.timeSlots.length * this.sectionHeight)
    .backgroundColor('rgba(255, 255, 255, 0.22)')
    .backgroundBlurStyle(BlurStyle.Thin)
    .border({ width: { right: 0.5 }, color: 'rgba(0, 0, 0, 0.06)' })
    .borderRadius(12)
  }

  /**
   * 网格背景
   */
  @Builder
  GridBackground() {
    Column() {
      ForEach(this.timeSlots, (slot: TimeSlot) => {
        Row() {
          ForEach(DAY_LABELS, (label: string, dayIndex: number) => {
            Column()
              .width(this.dayWidth)
              .height(this.sectionHeight)
              .border({
                width: { right: 0.5, bottom: 0.5 },
                color: 'rgba(0, 0, 0, 0.05)'
              })
          }, (label: string, index: number) => `${label}_${index}`)
        }
        .width('100%')
        .height(this.sectionHeight)
      }, (slot: TimeSlot) => slot.sectionNumber.toString())
    }
    .width(this.dayWidth * DAY_LABELS.length)
    .height(this.timeSlots.length * this.sectionHeight)
  }

  /**
   * 课程详情浮层
   * 作为 ScheduleGrid 根 Stack 的子节点直接渲染，和课程卡片共享同一棵组件树。
   * 通过 if(showDetail) 控制上下树，关闭时目标节点下树，
   * 从而触发 geometryTransition 的返回动画，避免直接跳跃。
   */
  @Builder
  CourseDetailOverlay() {
    Stack({ alignContent: Alignment.Center }) {
      // 背景模糊层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.35)')
        .backdropBlur(24)
        .transition(TransitionEffect.OPACITY)
        .onClick(() => {
          this.closeCourseDetail();
        })

      // 详情卡片
      if (this.selectedCourse) {
        CourseDetailCard({
          course: this.selectedCourse,
          timeSlots: this.timeSlots,
          brandColor: this.brandColor,
          transitionId: `course_${this.selectedCourse.id}_week_${this.currentWeek}`,
          onClose: () => {
            this.closeCourseDetail();
          },
          onEdit: () => {
            const course = this.selectedCourse;
            this.closeCourseDetail();
            if (course) {
              this.onEditCourse?.(course);
            }
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .zIndex(100)
    .transition(TransitionEffect.IDENTITY)
  }

  /**
   * 空状态提示
   */
  @Builder
  EmptyStateBuilder() {
    Column({ space: 12 }) {
      SymbolGlyph($r('sys.symbol.calendar'))
        .fontSize(64)
        .fontColor(['rgba(0,0,0,0.25)'])
        .width(64)
        .height(64)

      Text('还没有课程')
        .fontSize(16)
        .fontColor($r('sys.color.ohos_id_color_secondary'))

      Text('点击右下角 + 添加第一节课')
        .fontSize(13)
        .fontColor($r('sys.color.ohos_id_color_tertiary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .zIndex(20)
  }

  /**
   * 计算课程卡片高度（根据跨节数）
   */
  private calculateCardHeight(course: Course): number {
    const span = course.endSection - course.startSection + 1;
    return span * this.sectionHeight - this.cardGap;
  }

  /**
   * 判断课程在当前周次是否有课
   */
  private isCourseActiveInWeek(course: Course): boolean {
    return (course.weeks ?? []).indexOf(this.currentWeek) >= 0;
  }

  /**
   * 获取当前周的课程列表
   */
  private getCurrentWeekCourses(): Course[] {
    return this.courses.filter((course: Course) => this.isCourseActiveInWeek(course));
  }

  /**
   * 打开课程详情
   * 使用 geometryTransition(follow: true) 让原卡片始终留在树上并跟随共享动画，
   * 系统会自动隐藏原卡片并创建替身，完成一镜到底展开效果。
   */
  private openCourseDetail(course: Course): void {
    this.selectedCourse = course;
    this.getUIContext()?.animateTo({
      duration: 360,
      curve: Curve.Friction
    }, () => {
      this.showDetail = true;
    });
  }

  /**
   * 关闭课程详情
   */
  private closeCourseDetail(): void {
    this.getUIContext()?.animateTo({
      duration: 320,
      curve: Curve.Friction
    }, () => {
      this.showDetail = false;
    });
  }
}
