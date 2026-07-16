import { TabBarConfig } from '../common/TabBarConfig';
import { BackgroundConfig } from '../common/BackgroundConfig';
import { TabBarLabConfig } from '../common/TabBarLabConfig';
import { applyBrandColor, previewBrandColor, DEFAULT_BRAND_COLOR, isValidHexColor } from '../common/AppTheme';
import { setColorMode, AppColorMode, getColorMode } from '../common/ColorModeConfig';
import { ScrollAnimationConfig, staggerOffset } from '../common/ScrollAnimationConfig';
import {
  FlowLightConfig,
  MIN_FLOW_LIGHT_DURATION,
  MAX_FLOW_LIGHT_DURATION,
  MIN_FLOW_LIGHT_OPACITY,
  MAX_FLOW_LIGHT_OPACITY,
  DEFAULT_FLOW_LIGHT_OPACITY
} from '../common/FlowLightConfig';
import { HdrLightConfig } from '../common/HdrLightConfig';
import { RgbColorPicker } from '../components/color/RgbColorPicker';
import { common } from '@kit.AbilityKit';
import { curves, SegmentButton, SegmentButtonOptions } from '@kit.ArkUI';

/**
 * 菜单项数据结构
 */
interface MenuItem {
  id: string;
  symbol: Resource;
  title: string;
  subtitle: string;
}

/**
 * 我的页面
 * 采用入口列表 + 底部抽屉（bindSheet）的设置页结构
 */
@Entry
@Component
export struct ProfilePage {
  @StorageLink('canUseHDS') canUseHDS: boolean = false;
  @StorageLink('useHDS') useHDS: boolean = false;
  @StorageLink('bgImageUri') bgImageUri: string = '';
  @StorageLink('bgUseDefault') bgUseDefault: boolean = true;
  @StorageLink('hdsMaterialLevel') materialLevel: string = 'ADAPTIVE';

  // ClassicTabs 核心可调视觉属性
  @StorageLink('labEffectRadius') labEffectRadius: number = 20;
  @StorageLink('labEffectSaturation') labEffectSaturation: number = 1.2;
  @StorageLink('labEffectBrightness') labEffectBrightness: number = 1.0;

  // 主题品牌色（已应用）
  @StorageLink('brandColor') @Watch('onBrandColorChanged') brandColor: string = '#007DFF';

  // 主题色应用版本计数器（RgbColorPicker 应用颜色时自增，用于刷新 SegmentButton 选项）
  @StorageLink('brandColorVersion') brandColorVersion: number = 0;

  // 主题色预览值（抽屉内所有主题色控件实时跟随该值）
  @StorageLink('previewBrandColor') @Watch('onPreviewBrandColorChanged') previewBrandColor: string = '#007DFF';

  // 颜色模式：system 跟随系统 / light 浅色 / dark 深色
  @StorageLink('appColorMode') @Watch('onColorModeChanged') appColorMode: string = 'system';

  // 上次自定义主题色（用于默认↔自定义切换时恢复）
  @StorageLink('customBrandColor') customBrandColor: string = '#007DFF';

  // 是否展开自定义颜色选择器
  @State showCustomPicker: boolean = false;

  // 抽屉内暂存的 TabBar 方案选择（关闭抽屉后才真正应用）
  @State pendingUseHDS: boolean = false;

  // SegmentButton 选中索引：0 默认，1 自定义
  @State themeModeIndexes: number[] = [0];

  // SegmentButton 配置项（@State 持有，避免每次 build 新建对象导致 @ObjectLink 警告）
  @State themeModeOptions: SegmentButtonOptions = SegmentButtonOptions.capsule({
    buttons: [{ text: '默认' }, { text: '自定义' }],
    multiply: false,
    fontColor: $r('sys.color.ohos_id_color_primary'),
    selectedFontColor: Color.White,
    backgroundColor: 'rgba(255,255,255,0.2)',
    selectedBackgroundColor: '#007DFF'
  });

  // 颜色模式选中索引：0 跟随系统，1 始终深色，2 始终浅色
  @State colorModeSelectedIndex: number = 0;

  // 颜色模式 Select 按钮显示文本
  @State colorModeSelectedValue: string = '跟随系统';

  // 抽屉控制
  @State isSheetShown: boolean = false;
  @State activeSheet: string = '';

  // 页面滚动错开动效开关
  @StorageLink('scrollStaggerEnabled') scrollStaggerEnabled: boolean = true;

  // 背景流光效果开关
  @StorageLink('bgFlowLightEnabled') bgFlowLightEnabled: boolean = false;

  // 全局 HDR 光效开关（API 24+，提亮 HDS 沉浸光感按压点光源等触摸光效）
  @StorageLink('hdrLightEnabled') hdrLightEnabled: boolean = false;

  // 背景流光动画时长（ms，越小越快）
  @StorageLink('bgFlowLightDuration') @Watch('onFlowLightDurationChanged') bgFlowLightDuration: number = 8000;

  // 流光速度滑条本地值（0~100，越大越快），与 duration 互逆
  @State bgFlowLightSpeedValue: number = 50;

  // 背景流光遮罩透明度（0.1~1.0）
  @StorageLink('bgFlowLightOpacity') @Watch('onFlowLightOpacityChanged') bgFlowLightOpacity: number = DEFAULT_FLOW_LIGHT_OPACITY;

  // 流光透明度滑条本地值（0~100，对应 0~1）
  @State bgFlowLightOpacityValue: number = Math.round(DEFAULT_FLOW_LIGHT_OPACITY * 100);

  // 当前帧滚动偏移量，用于驱动子项错开位移
  @State scrollDeltaY: number = 0;

  // 抽屉内当前帧滚动偏移量，用于驱动抽屉内卡片错开位移
  @State sheetScrollDeltaY: number = 0;

  // 设置入口列表
  private menuItems: Array<MenuItem> = [
    { id: 'ai', symbol: $r('sys.symbol.gearshape'), title: 'AI 相关设置', subtitle: '占位功能' },
    { id: 'sync', symbol: $r('sys.symbol.arrow_2_circlepath'), title: '从其他设备同步', subtitle: '占位功能' },
    { id: 'personalize', symbol: $r('sys.symbol.paintbrush'), title: '个性化选项', subtitle: '主题、背景、导航栏' },
    { id: 'notification', symbol: $r('sys.symbol.bell'), title: '通知选项', subtitle: '占位功能' },
    { id: 'demo', symbol: $r('sys.symbol.play'), title: '演示教学', subtitle: '占位功能' },
    { id: 'about', symbol: $r('sys.symbol.info_circle'), title: '关于应用', subtitle: '占位功能' }
  ];

  aboutToAppear(): void {
    const isDefault = this.brandColor === DEFAULT_BRAND_COLOR;
    this.themeModeIndexes = isDefault ? [0] : [1];
    this.showCustomPicker = !isDefault;
    this.pendingUseHDS = this.useHDS;
    this.colorModeSelectedIndex = this.resolveColorModeIndex();
    this.colorModeSelectedValue = this.resolveColorModeLabel(this.colorModeSelectedIndex);
    this.bgFlowLightSpeedValue = this.durationToSpeed(this.bgFlowLightDuration);
    this.bgFlowLightOpacityValue = Math.round(this.bgFlowLightOpacity * 100);
    previewBrandColor(this.brandColor);
    this.updateThemeModeOptions();
  }

  /**
   * 将动画时长转换为速度滑条值（0~100，越大越快）
   */
  private durationToSpeed(duration: number): number {
    const clamped = Math.max(MIN_FLOW_LIGHT_DURATION, Math.min(MAX_FLOW_LIGHT_DURATION, duration));
    return Math.round(((MAX_FLOW_LIGHT_DURATION - clamped) / (MAX_FLOW_LIGHT_DURATION - MIN_FLOW_LIGHT_DURATION)) * 100);
  }

  /**
   * 将速度滑条值转换为动画时长
   */
  private speedToDuration(speed: number): number {
    const clamped = Math.max(0, Math.min(100, speed));
    return Math.round(MAX_FLOW_LIGHT_DURATION - (clamped / 100) * (MAX_FLOW_LIGHT_DURATION - MIN_FLOW_LIGHT_DURATION));
  }

  /**
   * 持久化时长变化时同步速度滑条显示
   */
  private onFlowLightDurationChanged(): void {
    this.bgFlowLightSpeedValue = this.durationToSpeed(this.bgFlowLightDuration);
  }

  /**
   * 持久化透明度变化时同步透明度滑条显示
   */
  private onFlowLightOpacityChanged(): void {
    this.bgFlowLightOpacityValue = Math.round(this.bgFlowLightOpacity * 100);
  }

  /**
   * 根据当前颜色模式返回 Select 选中索引
   */
  private resolveColorModeIndex(): number {
    switch (getColorMode()) {
      case 'dark':
        return 1;
      case 'light':
        return 2;
      case 'system':
      default:
        return 0;
    }
  }

  /**
   * 根据选中索引返回颜色模式显示文本
   */
  private resolveColorModeLabel(index: number): string {
    const labels = ['跟随系统', '始终深色', '始终浅色'];
    return labels[index] ?? '跟随系统';
  }

  aboutToDisappear(): void {
    const ctx = this.getUIContext().getHostContext() as common.Context;
    if (ctx) {
      TabBarLabConfig.save(ctx, 'labEffectRadius', this.labEffectRadius);
      TabBarLabConfig.save(ctx, 'labEffectSaturation', this.labEffectSaturation);
      TabBarLabConfig.save(ctx, 'labEffectBrightness', this.labEffectBrightness);
    }
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        // 顶部标题
        Text('我的')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.ohos_id_color_primary'))
          .width('100%')
          .padding(16)

        // 入口列表
        Column({ space: 12 }) {
          ForEach(this.menuItems, (item: MenuItem, index: number) => {
            this.ProfileMenuItem(item, index)
          }, (item: MenuItem) => item.id)
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
      .width('100%')
      .padding({ bottom: 32 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
    .scrollBar(BarState.Auto)
    .onScrollFrameBegin((offset: number) => {
      this.scrollDeltaY = offset;
      return { offsetRemain: offset };
    })
    .onScrollStop(() => {
      this.scrollDeltaY = 0;
    })
    .bindSheet(
      this.isSheetShown,
      this.SheetContentBuilder(),
      {
        height: '80%',
        preferType: SheetType.BOTTOM,
        dragBar: true,
        showClose: false,
        blurStyle: BlurStyle.Thin,
        backgroundColor: 'rgba(255,255,255,0.72)',
        maskColor: 'rgba(0,0,0,0.35)',
        onWillDismiss: (action) => {
          // 抽屉关闭时，若 TabBar 方案有变更则延迟应用，避免切换时硬退出抽屉
          if (this.activeSheet === 'personalize' && this.pendingUseHDS !== this.useHDS) {
            const ctx = this.getUIContext().getHostContext() as common.Context;
            TabBarConfig.setUseHDS(this.pendingUseHDS, ctx);
          }
          this.isSheetShown = false;
          action.dismiss();
        }
      }
    )
  }

  // ===== 入口列表项 =====
  @Builder
  ProfileMenuItem(item: MenuItem, index: number) {
    Row({ space: 12 }) {
      SymbolGlyph(item.symbol)
        .fontSize(22)
        .fontColor([$r('sys.color.ohos_id_color_primary')])
        .width(28)

      Column() {
        Text(item.title)
          .fontSize(16)
          .fontColor($r('sys.color.ohos_id_color_primary'))
        Text(item.subtitle)
          .fontSize(12)
          .fontColor($r('sys.color.ohos_id_color_secondary'))
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([$r('sys.color.ohos_id_color_secondary')])
    }
    .width('100%')
    .padding(16)
    .backgroundBlurStyle(BlurStyle.Thin)
    .backgroundColor('rgba(255, 255, 255, 0.15)')
    .borderRadius(12)
    .translate({ y: staggerOffset(this.scrollDeltaY, index, this.scrollStaggerEnabled) })
    .animation({
      duration: 320,
      curve: curves.springMotion(0.28, 0.65)
    })
    .onClick(() => {
      this.activeSheet = item.id;
      this.isSheetShown = true;
    })
  }

  // ===== 抽屉内容分发 =====
  @Builder
  SheetContentBuilder() {
    Column() {
      if (this.activeSheet === 'personalize') {
        this.PersonalizeSheetContent()
      } else {
        this.PlaceholderSheetContent(this.getSheetTitle())
      }
    }
    .width('100%')
    .height('100%')
    .padding({ top: 24 })
  }

  private getSheetTitle(): string {
    const item = this.menuItems.find((it) => it.id === this.activeSheet);
    return item ? item.title : '设置';
  }

  // ===== 占位抽屉 =====
  @Builder
  PlaceholderSheetContent(title: string) {
    Column({ space: 16 }) {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.ohos_id_color_primary'))
        .width('100%')

      Text('该功能正在开发中，敬请期待')
        .fontSize(14)
        .fontColor($r('sys.color.ohos_id_color_secondary'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 40, bottom: 40 })

      Button('知道了', { type: ButtonType.Capsule })
        .width('100%')
        .height(40)
        .backgroundColor(this.previewBrandColor)
        .fontColor(Color.White)
        .onClick(() => {
          this.isSheetShown = false;
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, bottom: 20 })
  }

  // ===== 个性化选项抽屉 =====
  @Builder
  PersonalizeSheetContent() {
    Scroll() {
      Column({ space: 16 }) {
        // 抽屉标题
        Text('个性化选项')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.ohos_id_color_primary'))
          .width('100%')

        // 主题与背景
        Column({ space: 12 }) {
          Text('主题与背景')
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
            .width('100%')

          this.BackgroundSettingsItem(0)
          this.ColorModeSettingsItem(1)
          this.ThemeColorSettingsItem(2)
        }
        .width('100%')

        // 页面与导航
        Column({ space: 12 }) {
          Text('页面与导航')
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
            .width('100%')

          this.TabBarSettingsCard(3)
        }
        .width('100%')

        // 预留空位：后续放动画曲线、流光效果等
        Column({ space: 12 }) {
          Text('更多效果(可能导致续航问题)')
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
            .width('100%')

          this.ScrollAnimationSettingsItem(4)
          this.FlowLightSettingsItem(5)
          this.HdrLightSettingsItem(6)
        }
        .width('100%')
      }
    }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 32 })
      .scrollBar(BarState.Auto)
      .nestedScroll({
        scrollForward: NestedScrollMode.PARENT_FIRST,
        scrollBackward: NestedScrollMode.SELF_FIRST
      })
      .onScrollFrameBegin((offset: number) => {
        this.sheetScrollDeltaY = offset;
        return { offsetRemain: offset };
      })
      .onScrollStop(() => {
        this.sheetScrollDeltaY = 0;
      })
  }

  @Builder
  PlaceholderCard(label: string, index: number = 0) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor($r('sys.color.ohos_id_color_primary'))
        .layoutWeight(1)

      Text('开发中')
        .fontSize(12)
        .fontColor($r('sys.color.ohos_id_color_secondary'))
    }
    .width('100%')
    .padding(16)
    .backgroundBlurStyle(BlurStyle.Thin)
    .backgroundColor('rgba(255,255,255,0.5)')
    .borderRadius(12)
    .translate({ y: staggerOffset(this.sheetScrollDeltaY, index, this.scrollStaggerEnabled) })
    .animation({
      duration: 320,
      curve: curves.springMotion(0.35, 0.35)
    })
  }

  // ===== 页面滚动动效开关 =====
  @Builder
  ScrollAnimationSettingsItem(index: number = 0) {
    Row() {
      Column() {
        Text('更夸张的页面滚动动效')
          .fontSize(16)
          .fontColor($r('sys.color.ohos_id_color_primary'))
        Text('滑动时，每个小组件将错开，并带惯性的回弹')
          .fontSize(12)
          .fontColor($r('sys.color.ohos_id_color_secondary'))
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.scrollStaggerEnabled })
        .selectedColor(this.previewBrandColor)
        .onChange((isOn: boolean) => {
          const ctx = this.getUIContext().getHostContext() as common.Context;
          ScrollAnimationConfig.setEnabled(isOn, ctx);
        })
    }
    .width('100%')
    .padding(16)
    .backgroundBlurStyle(BlurStyle.Thin)
    .backgroundColor('rgba(255,255,255,0.5)')
    .borderRadius(12)
    .translate({ y: staggerOffset(this.sheetScrollDeltaY, index, this.scrollStaggerEnabled) })
    .animation({
      duration: 320,
      curve: curves.springMotion(0.28, 0.65)
    })
  }

  // ===== 背景流光效果开关 =====
  @Builder
  FlowLightSettingsItem(index: number = 0) {
    Column({ space: 12 }) {
      Row() {
        Column() {
          Text('背景流光效果')
            .fontSize(16)
            .fontColor($r('sys.color.ohos_id_color_primary'))
          Text('在背景图上叠加动态多色流动光效，主要颜色之一跟随主题色')
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.bgFlowLightEnabled })
          .selectedColor(this.previewBrandColor)
          .onChange((isOn: boolean) => {
            const ctx = this.getUIContext().getHostContext() as common.Context;
            FlowLightConfig.setEnabled(isOn, ctx);
          })
      }
      .width('100%')

      if (this.bgFlowLightEnabled) {
        Column({ space: 6 }) {
          Row() {
            Text('流光速度')
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_primary'))
              .layoutWeight(1)
            Text(`${(this.bgFlowLightDuration / 1000).toFixed(1)}s / 圈`)
              .fontSize(14)
              .fontColor(this.previewBrandColor)
          }
          .width('100%')

          Slider({
            value: this.bgFlowLightSpeedValue,
            min: 0,
            max: 100,
            step: 5,
            style: SliderStyle.OutSet
          })
            .width('100%')
            .selectedColor(this.previewBrandColor)
            .onChange((value: number) => {
              this.bgFlowLightSpeedValue = value;
              const ctx = this.getUIContext().getHostContext() as common.Context;
              FlowLightConfig.setDuration(this.speedToDuration(value), ctx);
            })

          Row() {
            Text('流光透明度')
              .fontSize(14)
              .fontColor($r('sys.color.ohos_id_color_primary'))
              .layoutWeight(1)
            Text(`${Math.round(this.bgFlowLightOpacity * 100)}%`)
              .fontSize(14)
              .fontColor(this.previewBrandColor)
          }
          .width('100%')

          Slider({
            value: this.bgFlowLightOpacityValue,
            min: Math.round(MIN_FLOW_LIGHT_OPACITY * 100),
            max: Math.round(MAX_FLOW_LIGHT_OPACITY * 100),
            step: 5,
            style: SliderStyle.OutSet
          })
            .width('100%')
            .selectedColor(this.previewBrandColor)
            .onChange((value: number) => {
              this.bgFlowLightOpacityValue = value;
              const ctx = this.getUIContext().getHostContext() as common.Context;
              FlowLightConfig.setOpacity(value / 100, ctx);
            })
        }
        .width('100%')
        .transition(this.expandTransition())
      }
    }
    .width('100%')
    .padding(16)
    .backgroundBlurStyle(BlurStyle.Thin)
    .backgroundColor('rgba(255,255,255,0.5)')
    .borderRadius(12)
    .translate({ y: staggerOffset(this.sheetScrollDeltaY, index, this.scrollStaggerEnabled) })
    .animation({
      duration: 320,
      curve: curves.springMotion(0.28, 0.65)
    })
  }

  // ===== 全局 HDR 光效开关 =====
  @Builder
  HdrLightSettingsItem(index: number = 0) {
    Row() {
      Column() {
        Text('全局 HDR 光效')
          .fontSize(16)
          .fontColor($r('sys.color.ohos_id_color_primary'))
        Text('触摸光效以HDR展示，亮度显著提升（需要设备支持HDR且API24以上）')
          .fontSize(12)
          .fontColor($r('sys.color.ohos_id_color_secondary'))
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.hdrLightEnabled })
        .selectedColor(this.previewBrandColor)
        .onChange((isOn: boolean) => {
          const ctx = this.getUIContext().getHostContext() as common.Context;
          HdrLightConfig.setEnabled(isOn, ctx);
        })
    }
    .width('100%')
    .padding(16)
    .backgroundBlurStyle(BlurStyle.Thin)
    .backgroundColor('rgba(255,255,255,0.5)')
    .borderRadius(12)
    .translate({ y: staggerOffset(this.sheetScrollDeltaY, index, this.scrollStaggerEnabled) })
    .animation({
      duration: 320,
      curve: curves.springMotion(0.28, 0.65)
    })
  }

  // ===== 颜色模式设置 =====
  @Builder
  ColorModeSettingsItem(index: number = 0) {
    Row() {
      Text('深浅色主题')
        .fontSize(16)
        .fontColor($r('sys.color.ohos_id_color_primary'))
        .layoutWeight(1)

      Select([
        { value: '跟随系统' },
        { value: '始终深色' },
        { value: '始终浅色' }
      ])
        .selected(this.colorModeSelectedIndex)
        .value(this.colorModeSelectedValue)
        .fontColor($r('sys.color.ohos_id_color_primary'))
        .selectedOptionBgColor(this.previewBrandColor)
        .selectedOptionFontColor(Color.White)
        .optionBgColor('rgba(255,255,255,0.9)')
        .optionFontColor($r('sys.color.ohos_id_color_primary'))
        .backgroundColor('rgba(240,240,240,0.8)')
        .borderRadius(16)
        .height(36)
        .padding({ left: 12, right: 8 })
        .onSelect((index: number) => {
          const ctx = this.getUIContext().getHostContext() as common.Context;
          this.colorModeSelectedValue = this.resolveColorModeLabel(index);
          switch (index) {
            case 0:
              setColorMode('system', ctx);
              break;
            case 1:
              setColorMode('dark', ctx);
              break;
            case 2:
              setColorMode('light', ctx);
              break;
          }
        })
    }
    .width('100%')
    .padding(16)
    .backgroundBlurStyle(BlurStyle.Thin)
    .backgroundColor('rgba(255, 255, 255, 0.15)')
    .borderRadius(12)
    .translate({ y: staggerOffset(this.sheetScrollDeltaY, index, this.scrollStaggerEnabled) })
    .animation({
      duration: 320,
      curve: curves.springMotion(0.28, 0.65)
    })
  }

  // ===== 主题色设置 =====
  @Builder
  ThemeColorSettingsItem(index: number = 0) {
    Column({ space: 12 }) {
      // 标题行 + 右上角实时预览圆点
      Row() {
        Column() {
          Text('主题色')
            .fontSize(16)
            .fontColor($r('sys.color.ohos_id_color_primary'))
          Text('影响开关、按钮、TabBar选中色等')
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column()
          .width(24)
          .height(24)
          .borderRadius(12)
          .backgroundColor(this.previewBrandColor)
          .border({ width: 2, color: 'rgba(255,255,255,0.5)' })
      }
      .width('100%')

      // 默认 / 自定义 分段开关
      SegmentButton({
        options: this.themeModeOptions,
        selectedIndexes: this.themeModeIndexes,
        onItemClicked: (index: number) => {
          this.handleThemeModeChange(index);
        }
      })
        .width('100%')

      // 自定义颜色选择器（展开时显示）
      if (this.showCustomPicker) {
        Column({ space: 10 }) {
          RgbColorPicker()
            .width('100%')
        }
        .width('100%')
        .padding({ top: 8 })
        .transition(this.expandTransition())
      }
    }
    .width('100%')
    .padding(16)
    .backgroundBlurStyle(BlurStyle.Thin)
    .backgroundColor('rgba(255, 255, 255, 0.15)')
    .borderRadius(12)
    .translate({ y: staggerOffset(this.sheetScrollDeltaY, index, this.scrollStaggerEnabled) })
    .animation({
      duration: 320,
      curve: curves.springMotion(0.28, 0.65)
    })
  }

  /**
   * 毛玻璃卡片展开/收起通用转场效果
   * 出现：从上方 20vp 处透明滑入
   * 消失：向下方 20vp 处透明滑出
   */
  private expandTransition(): TransitionEffect {
    return TransitionEffect.asymmetric(
      TransitionEffect.OPACITY
        .combine(TransitionEffect.translate({ y: -20 }))
        .animation({ curve: curves.springMotion(0.35, 0.8), duration: 300 }),
      TransitionEffect.OPACITY
        .combine(TransitionEffect.translate({ y: 20 }))
        .animation({ curve: curves.springMotion(0.35, 0.8), duration: 250 })
    );
  }

  /**
   * 更新主题色模式 SegmentButton 选项
   * 在预览色变化时刷新选中背景色，抽屉内所有主题色控件跟随预览色实时变化
   */
  private updateThemeModeOptions(): void {
    this.themeModeOptions = SegmentButtonOptions.capsule({
      buttons: [{ text: '默认' }, { text: '自定义' }],
      multiply: false,
      fontColor: $r('sys.color.ohos_id_color_primary'),
      selectedFontColor: Color.White,
      backgroundColor: 'rgba(255,255,255,0.2)',
      selectedBackgroundColor: this.previewBrandColor
    });
  }

  /**
   * 品牌色变化时刷新 SegmentButton 配置
   */
  private onBrandColorChanged(): void {
    this.updateThemeModeOptions();
  }

  /**
   * 预览色变化时刷新抽屉内依赖主题色的控件
   */
  private onPreviewBrandColorChanged(): void {
    this.updateThemeModeOptions();
  }

  /**
   * 颜色模式变化时同步 Select 选中索引与显示文本
   */
  private onColorModeChanged(): void {
    this.colorModeSelectedIndex = this.resolveColorModeIndex();
    this.colorModeSelectedValue = this.resolveColorModeLabel(this.colorModeSelectedIndex);
  }

  /**
   * 处理主题色模式切换
   * 0: 默认（华为蓝），1: 自定义
   */
  private handleThemeModeChange(index: number): void {
    const ctx = this.getUIContext().getHostContext() as common.Context;
    this.themeModeIndexes = [index];

    if (index === 0) {
      this.getUIContext().animateTo({ curve: curves.springMotion(0.35, 0.8) }, () => {
        this.showCustomPicker = false;
      });
      applyBrandColor(ctx, DEFAULT_BRAND_COLOR);
    } else {
      // 优先恢复上次记忆的自定义色；若记忆值非法，则回退到当前已应用色
      const restoreColor = isValidHexColor(this.customBrandColor) && this.customBrandColor !== DEFAULT_BRAND_COLOR
        ? this.customBrandColor
        : this.brandColor;
      this.getUIContext().animateTo({ curve: curves.springMotion(0.35, 0.8) }, () => {
        this.showCustomPicker = true;
      });
      applyBrandColor(ctx, restoreColor);
    }
  }

  // ===== 背景图设置 =====
  @Builder
  BackgroundSettingsItem(index: number = 0) {
    Column({ space: 8 }) {
      Row() {
        Column() {
          Text('更换背景图')
            .fontSize(16)
            .fontColor($r('sys.color.ohos_id_color_primary'))
          Text(this.bgUseDefault ? '使用默认背景' : '已自定义背景')
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button(this.bgUseDefault ? '选择' : '更换', { type: ButtonType.Capsule })
          .fontSize(12)
          .height(32)
          .backgroundColor(this.previewBrandColor)
          .fontColor(Color.White)
          .onClick(() => { this.handlePickBackground(); })
      }
      .width('100%')
      .padding(16)
      .backgroundBlurStyle(BlurStyle.Thin)
      .backgroundColor('rgba(255, 255, 255, 0.15)')
      .borderRadius(12)

      if (!this.bgUseDefault) {
        Button('恢复默认背景')
          .fontSize(12)
          .fontColor($r('sys.color.ohos_id_color_secondary'))
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            const ctx = this.getUIContext().getHostContext() as common.Context;
            BackgroundConfig.resetToDefault(ctx);
          })
      }
    }
    .width('100%')
    .translate({ y: staggerOffset(this.sheetScrollDeltaY, index, this.scrollStaggerEnabled) })
    .animation({
      duration: 320,
      curve: curves.springMotion(0.28, 0.65)
    })
  }

  // ===== TabBar 外观统一设置卡片 =====
  @Builder
  TabBarSettingsCard(index: number = 0) {
    Column({ space: 12 }) {
      // 卡片标题
      Row() {
        Column() {
          Text('导航栏外观')
            .fontSize(16)
            .fontColor($r('sys.color.ohos_id_color_primary'))
          Text(this.pendingUseHDS ? '官方悬浮导航栏' : '兼容导航栏')
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_secondary'))
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // HDS 切换开关（仅API23+设备显示）
      if (this.canUseHDS) {
        Row() {
          Column() {
            Text('使用官方悬浮导航栏')
              .fontSize(15)
              .fontColor($r('sys.color.ohos_id_color_primary'))
            Text('关闭后切换为兼容样式')
              .fontSize(11)
              .fontColor($r('sys.color.ohos_id_color_secondary'))
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: this.pendingUseHDS })
            .selectedColor(this.previewBrandColor)
            .onChange((isOn: boolean) => {
              this.pendingUseHDS = isOn;
            })
        }
        .width('100%')
        .padding(12)
        .backgroundColor('rgba(255,255,255,0.08)')
        .borderRadius(8)
      }

      // 动态内容：HDS时显示材质设置，Classic时显示视觉调节
      if (this.pendingUseHDS) {
        Column({ space: 10 }) {
          this.MaterialSettingsContent()
        }
        .width('100%')
        .transition(this.expandTransition())
      } else {
        Column({ space: 10 }) {
          this.ClassicTabSettingsContent()
        }
        .width('100%')
        .transition(this.expandTransition())
      }
    }
    .width('100%')
    .padding(16)
    .backgroundBlurStyle(BlurStyle.Thin)
    .backgroundColor('rgba(255, 255, 255, 0.15)')
    .borderRadius(12)
    .translate({ y: staggerOffset(this.sheetScrollDeltaY, index, this.scrollStaggerEnabled) })
    .animation({
      duration: 320,
      curve: curves.springMotion(0.28, 0.65)
    })
  }

  // ===== 沉浸光感材质内容 =====
  @Builder
  MaterialSettingsContent() {
    Column({ space: 10 }) {
      Text('沉浸光感材质')
        .fontSize(14)
        .fontColor($r('sys.color.ohos_id_color_secondary'))
        .width('100%')

      Row({ space: 8 }) {
        Text('材质等级')
          .fontSize(13)
          .fontColor($r('sys.color.ohos_id_color_secondary'))
          .layoutWeight(1)
        this.MaterialLevelButton('ADAPTIVE', '自适应')
        this.MaterialLevelButton('EXQUISITE', '精美')
        this.MaterialLevelButton('GENTLE', '轻柔')
        this.MaterialLevelButton('SMOOTH', '流畅')
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  MaterialLevelButton(value: string, label: string) {
    Button(label, { type: ButtonType.Capsule })
      .fontSize(11)
      .height(26)
      .padding({ left: 10, right: 10 })
      .backgroundColor(this.materialLevel === value ? this.previewBrandColor : 'rgba(255,255,255,0.3)')
      .fontColor(this.materialLevel === value ? Color.White : $r('sys.color.ohos_id_color_primary'))
      .onClick(() => {
        const ctx = this.getUIContext().getHostContext() as common.Context;
        TabBarConfig.setMaterialLevel(value, ctx);
      })
  }

  // ===== ClassicTabs 核心视觉调节内容 =====
  @Builder
  ClassicTabSettingsContent() {
    Column({ space: 10 }) {
      Row() {
        Text('特效调节')
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_secondary'))
          .layoutWeight(1)

        Button('重置', { type: ButtonType.Capsule })
          .fontSize(11)
          .height(26)
          .padding({ left: 10, right: 10 })
          .backgroundColor('rgba(255,255,255,0.3)')
          .fontColor($r('sys.color.ohos_id_color_primary'))
          .onClick(() => {
            const ctx = this.getUIContext().getHostContext() as common.Context;
            TabBarLabConfig.resetToDefaults(ctx);
          })
      }
      .width('100%')

      this.EffectRadiusSlider()
      this.EffectSaturationSlider()
      this.EffectBrightnessSlider()
    }
    .width('100%')
  }

  @Builder
  EffectRadiusSlider() {
    Column({ space: 2 }) {
      Row() {
        Text('特效模糊半径')
          .fontSize(13)
          .fontColor($r('sys.color.ohos_id_color_secondary'))
          .layoutWeight(1)
        Text(this.labEffectRadius.toString())
          .fontSize(13)
          .fontColor($r('sys.color.ohos_id_color_primary'))
      }
      .width('100%')
      Slider({ value: this.labEffectRadius, min: 0, max: 50, step: 1 })
        .width('100%')
        .selectedColor(this.previewBrandColor)
        .onChange((v: number) => { this.labEffectRadius = v; })
    }
    .width('100%')
  }

  @Builder
  EffectSaturationSlider() {
    Column({ space: 2 }) {
      Row() {
        Text('特效饱和度')
          .fontSize(13)
          .fontColor($r('sys.color.ohos_id_color_secondary'))
          .layoutWeight(1)
        Text(this.labEffectSaturation.toFixed(1))
          .fontSize(13)
          .fontColor($r('sys.color.ohos_id_color_primary'))
      }
      .width('100%')
      Slider({ value: this.labEffectSaturation, min: 0.5, max: 2.0, step: 0.1 })
        .width('100%')
        .selectedColor(this.previewBrandColor)
        .onChange((v: number) => { this.labEffectSaturation = v; })
    }
    .width('100%')
  }

  @Builder
  EffectBrightnessSlider() {
    Column({ space: 2 }) {
      Row() {
        Text('特效亮度')
          .fontSize(13)
          .fontColor($r('sys.color.ohos_id_color_secondary'))
          .layoutWeight(1)
        Text(this.labEffectBrightness.toFixed(1))
          .fontSize(13)
          .fontColor($r('sys.color.ohos_id_color_primary'))
      }
      .width('100%')
      Slider({ value: this.labEffectBrightness, min: 0.5, max: 1.5, step: 0.1 })
        .width('100%')
        .selectedColor(this.previewBrandColor)
        .onChange((v: number) => { this.labEffectBrightness = v; })
    }
    .width('100%')
  }

  async handlePickBackground(): Promise<void> {
    const ctx = this.getUIContext().getHostContext() as common.Context;
    const uri = await BackgroundConfig.pickBackgroundImage(ctx);
    if (uri) {
      await BackgroundConfig.saveBackgroundUri(ctx, uri);
    }
  }
}
