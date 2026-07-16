

import { HdsTabs, hdsMaterial } from '@kit.UIDesignKit';
import { TabItem } from '../../common/TabBarTypes';
import { SymbolGlyphModifier, curves } from '@kit.ArkUI';
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { uiEffect } from '@kit.ArkGraphics2D';
import { HdrLightConfig, HDR_BRIGHTNESS_RATIO } from '../../common/HdrLightConfig';

/**
 * TabBar条件分发组件
 * 根据AppStorage中useHDS的值，自动渲染HdsTabs（API23+悬浮沉浸光感）
 * 或经典Tabs（全宽平铺毛玻璃兼容样式）
 */
@Component
export struct TabBarSwitcher {
  /** 是否使用HDS（AppStorage双向绑定） */
  @StorageLink('useHDS') useHDS: boolean = false;

  /** 沉浸光感材质等级 */
  @StorageLink('hdsMaterialLevel') materialLevel: string = 'ADAPTIVE';

  /** ClassicTabs 核心可调视觉属性 */
  @StorageLink('labEffectRadius') labEffectRadius: number = 20;
  @StorageLink('labEffectSaturation') labEffectSaturation: number = 1.2;
  @StorageLink('labEffectBrightness') labEffectBrightness: number = 1.0;

  /** 主题品牌色（用于TabBar选中高亮） */
  @StorageLink('brandColor') brandColor: string = '#FF0000';

  /** 全局 HDR 光效开关（API 24+） */
  @StorageLink('hdrLightEnabled') hdrLightEnabled: boolean = false;

  /** 当前选中索引（与父组件双向绑定） */
  @Link currentIndex: number;

  /** 图标高亮显示索引（与页面索引解耦，避免动画反馈循环） */
  @State displayIndex: number = 0;

  /** Tab页签数据 */
  @Prop tabs: TabItem[] = [];

  /** 页面内容构建器 */
  @BuilderParam pageContent: (index: number) => void = this.defaultPageContent;

  @Builder
  defaultPageContent(index: number) {
    Column() {
      Text(`页面 ${index + 1}`)
        .fontSize(16)
        .fontColor('#666666')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    if (this.useHDS) {
      this.HDSBuilder()
    } else {
      this.ClassicBuilder()
    }
  }

  /**
   * API23+ HDS悬浮导航栏（沉浸光感）
   * 圆角边距悬浮样式，支持用户自定义材质类型与等级
   */
  @Builder
  HDSBuilder() {
    HdsTabs({ index: this.currentIndex }) {
      ForEach(this.tabs, (tab: TabItem, index: number) => {
        TabContent() {
          this.pageContent(index)
        }
        .backgroundColor(Color.Transparent)
        .tabBar(new BottomTabBarStyle({
          normal: new SymbolGlyphModifier(tab.symbol).fontColor([$r('sys.color.ohos_id_color_secondary')]),
          selected: new SymbolGlyphModifier(tab.symbol).fontColor([this.brandColor])
        }, tab.label)
          .labelStyle({
            selectedColor: this.brandColor,
            unselectedColor: $r('sys.color.ohos_id_color_secondary')
          }))
      }, (tab: TabItem) => tab.id)
    }
    .barPosition(BarPosition.End)
    .barOverlap(true)
    .backgroundColor(Color.Transparent)
    .barFloatingStyle({
      barBottomMargin: 16,
      lightColor: this.brandColor,
      systemMaterialEffect: {
        materialType: hdsMaterial.MaterialType.ADAPTIVE,
        materialLevel: this.resolveMaterialLevel()
      }
    })
    .barBackgroundEffect({
      radius: 20,
      saturation: 1,
      brightness: 1,
      color: Color.Red
    })
    .onTabBarClick((index: number) => {
      this.triggerHapticFeedback();
    })
    .onChange((index: number) => {
      this.displayIndex = index;
      this.currentIndex = index;
    })
    .foregroundFilter(this.resolveHdrFilter())
  }

  /**
   * 根据 HDR 开关与系统 API 版本解析滤镜
   * hdrBrightnessRatio 为 API 24+ 能力，低版本设备回退到普通滤镜
   */
  private resolveHdrFilter(): uiEffect.Filter {
    if (!this.hdrLightEnabled) {
      return uiEffect.createFilter();
    }
    try {
      if (Number(deviceInfo.sdkApiVersion) >= 24) {
        return uiEffect.createFilter().hdrBrightnessRatio(HDR_BRIGHTNESS_RATIO);
      }
    } catch (e) {
      console.warn('[TabBarSwitcher] hdrBrightnessRatio not available');
    }
    return uiEffect.createFilter();
  }

  /**
   * 切换页签时触发轻量震动反馈
   */
  private triggerHapticFeedback(): void {
    vibrator.startVibration({
      type: 'time',
      duration: 15
    }, {
      usage: 'physicalFeedback'
    }, (error: BusinessError<void>) => {
      if (error) {
        console.error(`TabBar haptic feedback failed: ${error.code}`);
      }
    });
  }

  /**
   * 将存储的材质等级字符串转为hdsMaterial枚举
   * 开启 HDR 且设备为 API23 时，强制使用 EXQUISITE 以提升按压点光源亮度
   */
  private resolveMaterialLevel(): hdsMaterial.MaterialLevel {
    if (this.hdrLightEnabled && Number(deviceInfo.sdkApiVersion) < 24) {
      return hdsMaterial.MaterialLevel.EXQUISITE;
    }
    switch (this.materialLevel) {
      case 'EXQUISITE':
        return hdsMaterial.MaterialLevel.EXQUISITE;
      case 'GENTLE':
        return hdsMaterial.MaterialLevel.GENTLE;
      case 'SMOOTH':
        return hdsMaterial.MaterialLevel.SMOOTH;
      case 'ADAPTIVE':
      default:
        return hdsMaterial.MaterialLevel.ADAPTIVE;
    }
  }

  /**
   * 兼容版平铺毛玻璃导航栏（API23以下默认回退）
   * 所有外观属性通过调试实验室实时可调
   */
  @Builder
  ClassicBuilder() {
    Tabs({
      barPosition: BarPosition.End,
      index: this.currentIndex
    }) {
      ForEach(this.tabs, (tab: TabItem, index: number) => {
        TabContent() {
          this.pageContent(index)
        }
        .backgroundColor(Color.Transparent)
        .tabBar(this.classicTabBarItem(tab, index))
      }, (tab: TabItem) => tab.id)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Transparent)
    .barHeight(56)
    .barMode(BarMode.Fixed)
    .scrollable(true)
    .animationDuration(300)
    .barOverlap(true)
    .barBackgroundBlurStyle(BlurStyle.Thin)
    .barBackgroundEffect({
      radius: this.labEffectRadius,
      saturation: this.labEffectSaturation,
      brightness: this.labEffectBrightness
    })
    .divider(null)
    .fadingEdge(true)
    .edgeEffect(EdgeEffect.Spring)
    .onAnimationStart((index: number, targetIndex: number) => {
      this.displayIndex = targetIndex;
    })
    .onTabBarClick((index: number) => {
      this.triggerHapticFeedback();
    })
    .onChange((index: number) => {
      this.displayIndex = index;
      this.currentIndex = index;
    })
  }

  /**
   * 自定义TabBar单项（图标+文字）
   * 选中颜色使用主题品牌色，未选中使用系统次要色
   */
  @Builder
  classicTabBarItem(tab: TabItem, index: number) {
    Column() {
      SymbolGlyph(tab.symbol)
        .fontSize(24)
        .fontColor([this.displayIndex === index ? this.brandColor : $r('sys.color.ohos_id_color_secondary')])

      Text(tab.label)
        .fontSize(12)
        .fontColor(this.displayIndex === index ? this.brandColor : $r('sys.color.ohos_id_color_secondary'))
        .margin({ top: 2 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
