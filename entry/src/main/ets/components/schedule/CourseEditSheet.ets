import { Course, DAY_LABELS } from '../../models/Course';
import { TimeSlot } from '../../models/TimeSlot';
import { formatLocalISO, parseWeeksText, formatWeeksText } from '../../utils/ScheduleUtils';
import { util } from '@kit.ArkTS';

/**
 * Select 选项类型
 */
interface CourseSelectOption {
  value: string;
}

/**
 * 表单卡片容器
 * 作为独立组件使用，避免 @Builder 参数传递的限制
 */
@Component
struct FormCard {
  @Prop label: string = '';
  @BuilderParam contentBuilder: () => void = this.defaultBuilder;

  @Builder
  defaultBuilder() {}

  build() {
    Column({ space: 8 }) {
      Text(this.label)
        .fontSize(14)
        .fontColor($r('sys.color.ohos_id_color_secondary'))
        .width('100%')

      this.contentBuilder()
    }
    .width('100%')
    .padding(16)
    .backgroundBlurStyle(BlurStyle.Thin)
    .backgroundColor('rgba(255,255,255,0.5)')
    .borderRadius(12)
  }
}

/**
 * 课程编辑抽屉
 * 通过 bindSheet 从底部弹出，用于新增/编辑课程
 */
@Component
export struct CourseEditSheet {
  /** 抽屉显示状态 */
  @Prop @Watch('onShownChanged') isShown: boolean = false;
  /** 主题色 */
  @Prop brandColor: string = '#007DFF';
  /** 当前学期 ID */
  @Prop semesterId: string = '';
  /** 学期总周数，用于校验周数输入 */
  @Prop totalWeeks: number = 20;
  /** 节次列表 */
  @Prop timeSlots: TimeSlot[] = [];
  /** 正在编辑的课程；undefined 表示新增 */
  @Prop @Watch('onEditingCourseChanged') editingCourse?: Course = undefined;

  /** 表单字段 */
  @State formName: string = '';
  @State formTeacher: string = '';
  @State formLocation: string = '';
  @State formDayOfWeek: number = 1;
  @State formStartSection: number = 1;
  @State formEndSection: number = 1;
  @State formWeeksText: string = '';

  /** 关闭回调 */
  onClose?: () => void;
  /** 保存回调 */
  onSave?: (course: Course) => void;
  /** 删除回调 */
  onDelete?: (id: string) => void;

  onShownChanged(): void {
    if (this.isShown) {
      this.onEditingCourseChanged();
    }
  }

  onEditingCourseChanged(): void {
    if (this.editingCourse) {
      this.formName = this.editingCourse.name;
      this.formTeacher = this.editingCourse.teacher;
      this.formLocation = this.editingCourse.location;
      this.formDayOfWeek = this.editingCourse.dayOfWeek;
      this.formStartSection = this.editingCourse.startSection;
      this.formEndSection = this.editingCourse.endSection;
      this.formWeeksText = formatWeeksText(this.editingCourse.weeks);
    } else {
      this.resetForm();
    }
  }

  private resetForm(): void {
    this.formName = '';
    this.formTeacher = '';
    this.formLocation = '';
    this.formDayOfWeek = 1;
    this.formStartSection = 1;
    this.formEndSection = 1;
    this.formWeeksText = '';
  }

  build() {
    Column() {
      // 空宿主，仅用于绑定 bindSheet
    }
    .width(0)
    .height(0)
    .bindSheet(
      this.isShown,
      this.SheetContentBuilder(),
      {
        height: '85%',
        preferType: SheetType.BOTTOM,
        dragBar: true,
        showClose: false,
        blurStyle: BlurStyle.Thin,
        backgroundColor: 'rgba(255,255,255,0.72)',
        maskColor: 'rgba(0,0,0,0.35)',
        onWillDismiss: (action) => {
          this.onClose?.();
          action.dismiss();
        }
      }
    )
  }

  @Builder
  SheetContentBuilder() {
    Scroll() {
      Column({ space: 16 }) {
        // 抽屉标题
        Text(this.editingCourse ? '编辑课程' : '添加课程')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.ohos_id_color_primary'))
          .width('100%')

        // 课程名
        FormCard({ label: '课程名称' }) {
          this.CourseNameInput()
        }

        // 教师
        FormCard({ label: '教师' }) {
          this.TeacherInput()
        }

        // 教室
        FormCard({ label: '教室' }) {
          this.LocationInput()
        }

        // 星期
        FormCard({ label: '星期' }) {
          this.DayOfWeekSelector()
        }

        // 节次
        FormCard({ label: '节次' }) {
          this.SectionSelector()
        }

        // 周数
        FormCard({ label: '周数范围' }) {
          this.WeeksInput()
        }

        // 操作按钮
        this.ActionButtons()
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 24, bottom: 32 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Auto)
  }

  @Builder
  CourseNameInput() {
    TextInput({ text: this.formName, placeholder: '如：高等数学' })
      .width('100%')
      .height(44)
      .fontSize(15)
      .placeholderColor($r('sys.color.ohos_id_color_secondary'))
      .backgroundColor(Color.Transparent)
      .onChange((value: string) => { this.formName = value; })
  }

  @Builder
  TeacherInput() {
    TextInput({ text: this.formTeacher, placeholder: '如：张教授' })
      .width('100%')
      .height(44)
      .fontSize(15)
      .placeholderColor($r('sys.color.ohos_id_color_secondary'))
      .backgroundColor(Color.Transparent)
      .onChange((value: string) => { this.formTeacher = value; })
  }

  @Builder
  LocationInput() {
    TextInput({ text: this.formLocation, placeholder: '如：教学楼 A-301' })
      .width('100%')
      .height(44)
      .fontSize(15)
      .placeholderColor($r('sys.color.ohos_id_color_secondary'))
      .backgroundColor(Color.Transparent)
      .onChange((value: string) => { this.formLocation = value; })
  }

  @Builder
  DayOfWeekSelector() {
    Select(DAY_LABELS.map((label: string): CourseSelectOption => ({ value: `周${label}` })))
      .selected(this.formDayOfWeek - 1)
      .value(`周${DAY_LABELS[this.formDayOfWeek - 1]}`)
      .fontColor($r('sys.color.ohos_id_color_primary'))
      .selectedOptionBgColor(this.brandColor)
      .selectedOptionFontColor(Color.White)
      .optionBgColor('rgba(255,255,255,0.9)')
      .optionFontColor($r('sys.color.ohos_id_color_primary'))
      .backgroundColor('rgba(240,240,240,0.8)')
      .borderRadius(16)
      .height(36)
      .padding({ left: 12, right: 8 })
      .onSelect((index: number) => {
        this.formDayOfWeek = index + 1;
      })
  }

  @Builder
  SectionSelector() {
    Row({ space: 12 }) {
      Column({ space: 4 }) {
        Text('开始')
          .fontSize(12)
          .fontColor($r('sys.color.ohos_id_color_secondary'))
        Select(this.timeSlots.map((slot: TimeSlot): CourseSelectOption => ({ value: `第${slot.sectionNumber}节` })))
          .selected(this.formStartSection - 1)
          .value(`第${this.formStartSection}节`)
          .fontColor($r('sys.color.ohos_id_color_primary'))
          .selectedOptionBgColor(this.brandColor)
          .selectedOptionFontColor(Color.White)
          .optionBgColor('rgba(255,255,255,0.9)')
          .optionFontColor($r('sys.color.ohos_id_color_primary'))
          .backgroundColor('rgba(240,240,240,0.8)')
          .borderRadius(16)
          .height(36)
          .padding({ left: 12, right: 8 })
          .onSelect((index: number) => {
            this.formStartSection = index + 1;
            if (this.formEndSection < this.formStartSection) {
              this.formEndSection = this.formStartSection;
            }
          })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column({ space: 4 }) {
        Text('结束')
          .fontSize(12)
          .fontColor($r('sys.color.ohos_id_color_secondary'))
        Select(this.timeSlots.map((slot: TimeSlot): CourseSelectOption => ({ value: `第${slot.sectionNumber}节` })))
          .selected(this.formEndSection - 1)
          .value(`第${this.formEndSection}节`)
          .fontColor($r('sys.color.ohos_id_color_primary'))
          .selectedOptionBgColor(this.brandColor)
          .selectedOptionFontColor(Color.White)
          .optionBgColor('rgba(255,255,255,0.9)')
          .optionFontColor($r('sys.color.ohos_id_color_primary'))
          .backgroundColor('rgba(240,240,240,0.8)')
          .borderRadius(16)
          .height(36)
          .padding({ left: 12, right: 8 })
          .onSelect((index: number) => {
            this.formEndSection = index + 1;
            if (this.formEndSection < this.formStartSection) {
              this.formStartSection = this.formEndSection;
            }
          })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
  }

  @Builder
  WeeksInput() {
    TextInput({ text: this.formWeeksText, placeholder: '如：1,2,3,4 或 1-8' })
      .width('100%')
      .height(44)
      .fontSize(15)
      .placeholderColor($r('sys.color.ohos_id_color_secondary'))
      .backgroundColor(Color.Transparent)
      .onChange((value: string) => { this.formWeeksText = value; })
  }

  @Builder
  ActionButtons() {
    Row({ space: 12 }) {
      if (this.editingCourse) {
        Button('删除', { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(44)
          .backgroundColor('#FF4D4F')
          .fontColor(Color.White)
          .onClick(() => {
            if (this.editingCourse) {
              this.onDelete?.(this.editingCourse.id);
            }
          })
      }

      Button('取消', { type: ButtonType.Capsule })
        .layoutWeight(1)
        .height(44)
        .backgroundColor('rgba(255,255,255,0.3)')
        .fontColor($r('sys.color.ohos_id_color_primary'))
        .onClick(() => {
          this.onClose?.();
        })

      Button('保存', { type: ButtonType.Capsule })
        .layoutWeight(2)
        .height(44)
        .backgroundColor(this.brandColor)
        .fontColor(Color.White)
        .onClick(() => {
          this.handleSave();
        })
    }
    .width('100%')
  }

  private handleSave(): void {
    const name = this.formName.trim();
    if (!name) {
      return;
    }
    const weeks = parseWeeksText(this.formWeeksText, this.totalWeeks);
    if (weeks.length === 0) {
      return;
    }
    const now = formatLocalISO(new Date());
    let course: Course;
    if (this.editingCourse) {
      course = {
        id: this.editingCourse.id,
        name,
        teacher: this.formTeacher.trim(),
        location: this.formLocation.trim(),
        dayOfWeek: this.formDayOfWeek,
        startSection: this.formStartSection,
        endSection: this.formEndSection,
        weeks,
        description: this.editingCourse.description ?? '',
        semesterId: this.editingCourse.semesterId,
        createdAt: this.editingCourse.createdAt,
        updatedAt: now
      };
      if (this.editingCourse.color) {
        course.color = this.editingCourse.color;
      }
    } else {
      course = {
        id: this.generateUuid(),
        name,
        teacher: this.formTeacher.trim(),
        location: this.formLocation.trim(),
        dayOfWeek: this.formDayOfWeek,
        startSection: this.formStartSection,
        endSection: this.formEndSection,
        weeks,
        semesterId: this.semesterId,
        description: '',
        createdAt: now,
        updatedAt: now
      };
    }
    this.onSave?.(course);
  }

  private generateUuid(): string {
    return util.generateRandomUUID();
  }
}
