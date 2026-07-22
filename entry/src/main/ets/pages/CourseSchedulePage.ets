import { Course } from '../models/Course';
import { TimeSlot } from '../models/TimeSlot';
import { Semester } from '../models/Semester';
import { WeekSelector } from '../components/schedule/WeekSelector';
import { ScheduleGrid } from '../components/schedule/ScheduleGrid';
import { ScheduleFabMenu } from '../components/schedule/ScheduleFabMenu';
import { CourseEditSheet } from '../components/schedule/CourseEditSheet';
import { CourseRepository } from '../repository/CourseRepository';
import { TimeSlotRepository } from '../repository/TimeSlotRepository';
import { SemesterRepository } from '../repository/SemesterRepository';
import { calculateDayWidth, calculateWeekNumber } from '../utils/ScheduleUtils';
import { common } from '@kit.AbilityKit';
import { curves } from '@kit.ArkUI';

/**
 * 课程表页面
 * 传统网格课表：左侧固定节次列，右侧日期栏 + 网格 + 课程卡片
 */
@Entry
@Component
export struct CourseSchedulePage {
  /** 主题色 */
  @StorageLink('brandColor') brandColor: string = '#007DFF';

  /** 底部导航指示条高度，用于 FAB 避让 */
  @StorageLink('bottomNaviHeight') bottomNaviHeight: number = 0;

  /** 顶部状态栏高度，用于避让沉浸模式下的状态栏 */
  @StorageLink('statusBarHeight') statusBarHeight: number = 0;

  /** 当前选中的周次 */
  @State currentWeek: number = 1;

  /** 是否已经初始化过周次（编辑后不再重置） */
  @State isWeekInitialized: boolean = false;

  /** 每天列宽度 */
  @State dayWidth: number = 72;

  /** 当前学期 */
  @State currentSemester?: Semester = undefined;

  /** 总周数 */
  @State totalWeeks: number = 20;

  /** 节次列表 */
  @State timeSlots: TimeSlot[] = [];

  /** 课程列表 */
  @State courses: Course[] = [];

  /** 是否显示课程编辑抽屉 */
  @State isEditSheetShown: boolean = false;
  /** 当前正在编辑的课程，undefined 表示新增 */
  @State editingCourse?: Course = undefined;

  aboutToAppear(): void {
    // 根据屏幕宽度计算每天列宽
    this.dayWidth = calculateDayWidth();
    // 从本地数据库加载学期、节次和课程
    this.loadData();
  }

  /**
   * 加载本地数据：学期 -> 节次 -> 课程
   */
  private async loadData(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const semester = await SemesterRepository.ensureCurrent(context);
    this.currentSemester = semester;
    this.totalWeeks = semester.totalWeeks;
    if (!this.isWeekInitialized) {
      this.currentWeek = this.calculateCurrentWeek(semester);
      this.isWeekInitialized = true;
    }
    this.timeSlots = await TimeSlotRepository.getAll(context);
    this.courses = await CourseRepository.getBySemester(context, semester.id);
  }

  /**
   * 根据学期开学日期计算当前周次
   * 与 WinUI3 端对齐：先找到各自所在周的周起始日，再计算周数差
   */
  private calculateCurrentWeek(semester: Semester): number {
    const week = calculateWeekNumber(semester.startDate, new Date(), semester.weekStartDay);
    return Math.max(1, Math.min(week, semester.totalWeeks));
  }

  /**
   * 生成周次范围数组（1..totalWeeks），供 Swiper 渲染每周课表
   */
  private generateWeekRange(): number[] {
    const weeks: number[] = [];
    for (let i = 1; i <= this.totalWeeks; i++) {
      weeks.push(i);
    }
    return weeks;
  }

  /**
   * 返回本周
   */
  private backToCurrentWeek(): void {
    if (this.currentSemester) {
      this.currentWeek = this.calculateCurrentWeek(this.currentSemester);
    }
  }

  /**
   * 保存课程（新增或更新）
   */
  private async handleSaveCourse(course: Course): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    if (this.editingCourse) {
      await CourseRepository.update(context, course);
    } else {
      await CourseRepository.insert(context, course);
    }
    this.isEditSheetShown = false;
    this.editingCourse = undefined;
    await this.loadData();
  }

  /**
   * 删除课程
   */
  private async handleDeleteCourse(id: string): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    await CourseRepository.delete(context, id);
    this.isEditSheetShown = false;
    this.editingCourse = undefined;
    await this.loadData();
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 顶部周切换器
        WeekSelector({
          currentWeek: this.currentWeek,
          totalWeeks: this.totalWeeks,
          brandColor: this.brandColor,
          onPrevWeek: () => {
            this.currentWeek--;
          },
          onNextWeek: () => {
            this.currentWeek++;
          },
          onBackToToday: () => {
            this.backToCurrentWeek();
          }
        })

        // 课表主体：使用 Swiper 实现左右翻页切换周次
        Swiper() {
          ForEach(this.generateWeekRange(), (week: number) => {
            ScheduleGrid({
              currentWeek: week,
              courses: this.courses,
              timeSlots: this.timeSlots,
              brandColor: this.brandColor,
              dayWidth: this.dayWidth,
              semesterStartDate: this.currentSemester?.startDate ?? '2025-02-17',
              weekStartDay: this.currentSemester?.weekStartDay ?? 1,
              onEditCourse: (course: Course) => {
                this.editingCourse = course;
                this.isEditSheetShown = true;
              },
              onDeleteCourse: (id: string) => {
                this.handleDeleteCourse(id);
              }
            })
          }, (week: number) => week.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .index(this.currentWeek - 1)
        .indicator(false)
        .loop(false)
        .duration(360)
        .curve(curves.springMotion(0.28, 0.65))
        .effectMode(EdgeEffect.Spring)
        .cachedCount(1)
        .onChange((index: number) => {
          this.currentWeek = index + 1;
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)
      .padding({ top: this.statusBarHeight, left: 8, right: 8 })

      // 右下角 FAB 菜单（底部增加偏移以避让悬浮 TabBar）
      ScheduleFabMenu({
        brandColor: this.brandColor,
        bottomOffset: this.bottomNaviHeight + 56,
        onItemClick: (id: string) => {
          if (id === 'add') {
            this.editingCourse = undefined;
            this.isEditSheetShown = true;
          } else if (id === 'web_import') {
            this.getUIContext()?.getRouter()?.pushUrl({
              url: 'pages/CourseImportPage',
              params: {
                semesterId: this.currentSemester?.id ?? '',
                totalWeeks: this.totalWeeks
              }
            });
          }
        }
      })

      // 课程编辑抽屉（新增/编辑课程）
      CourseEditSheet({
        isShown: this.isEditSheetShown,
        brandColor: this.brandColor,
        semesterId: this.currentSemester?.id ?? '',
        totalWeeks: this.totalWeeks,
        timeSlots: this.timeSlots,
        editingCourse: this.editingCourse,
        onClose: () => {
          this.isEditSheetShown = false;
          this.editingCourse = undefined;
        },
        onSave: (course: Course): void => {
          this.handleSaveCourse(course);
        },
        onDelete: (id: string): void => {
          this.handleDeleteCourse(id);
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
  }
}
