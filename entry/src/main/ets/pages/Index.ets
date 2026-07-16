import { TabItem } from '../common/TabBarTypes';
import { generateFlowLightColors, generateFlowLightTarget } from '../common/AppTheme';
import { TabBarSwitcher } from '../components/tabbar/TabBarSwitcher';
import { HomePage } from './HomePage';
import { LongPlanPage } from './LongPlanPage';
import { CourseSchedulePage } from './CourseSchedulePage';
import { ProfilePage } from './ProfilePage';
import { hdsEffect } from '@kit.UIDesignKit';

/**
 * 四个底部页签配置
 */
const TAB_DATA: TabItem[] = [
  { id: 'home', label: '首页', symbol: $r('sys.symbol.house_fill') },
  { id: 'long_plan', label: '长期规划', symbol: $r('sys.symbol.list_bullet') },
  { id: 'schedule', label: '课程表', symbol: $r('sys.symbol.calendar') },
  { id: 'profile', label: '我的', symbol: $r('sys.symbol.person_crop_circle_fill_1') }
];

/**
 * 主入口页面
 * 负责全局背景图展示及TabBarSwitcher挂载
 */
@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @StorageLink('bgImageUri') bgImageUri: string = '';
  @StorageLink('bgUseDefault') bgUseDefault: boolean = true;
  @StorageLink('bgFlowLightEnabled') bgFlowLightEnabled: boolean = false;
  @StorageLink('bgFlowLightDuration') bgFlowLightDuration: number = 8000;
  @StorageLink('bgFlowLightOpacity') bgFlowLightOpacity: number = 0.65;
  @StorageLink('brandColor') @Watch('onBrandColorChanged') brandColor: string = '#007DFF';
  @State flowLightController: hdsEffect.ShaderEffectController = new hdsEffect.ShaderEffectController();

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 全局背景图层（自定义背景时显示）
      if (!this.bgUseDefault && this.bgImageUri) {
        Image(this.bgImageUri.startsWith('file://') ? this.bgImageUri : 'file://' + this.bgImageUri)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
      }

      // 背景流光层（开启时作为动态彩色遮罩叠加在背景之上）
      if (this.bgFlowLightEnabled) {
        Stack()
          .width('100%')
          .height('100%')
          .opacity(this.bgFlowLightOpacity)
          .visualEffect(new hdsEffect.HdsEffectBuilder()
            .shaderEffect({
              effectType: hdsEffect.EffectType.UV_BACKGROUND_FLOW_LIGHT,
              animation: {
                duration: this.bgFlowLightDuration,
                iterations: -1,
                autoPlay: true
              },
              controller: this.flowLightController,
              params: {
                colorSource: generateFlowLightColors(this.brandColor),
                colorTarget: generateFlowLightTarget(this.brandColor)
              }
            })
            .buildEffect())
      }

      // 页面内容层（Tab导航 + 各页面内容）
      TabBarSwitcher({
        currentIndex: $currentIndex,
        tabs: TAB_DATA,
        pageContent: (index: number) => {
          this.PageContent(index)
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.bgUseDefault && !this.bgFlowLightEnabled ? $r('sys.color.ohos_id_color_sub_background') : Color.Transparent)
  }

  onBrandColorChanged(): void {
    if (this.bgFlowLightEnabled) {
      // 先关闭流光层（组件从树中移除）
      this.bgFlowLightEnabled = false;
      // 下一帧重新开启，触发组件重建，shader 使用新主题色参数
      setTimeout(() => {
        this.bgFlowLightEnabled = true;
      }, 0);
    }
  }

  @Builder
  PageContent(index: number) {
    if (index === 0) {
      HomePage()
    } else if (index === 1) {
      LongPlanPage()
    } else if (index === 2) {
      CourseSchedulePage()
    } else {
      ProfilePage()
    }
  }
}
