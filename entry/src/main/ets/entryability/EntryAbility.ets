import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window, ThemeControl } from '@kit.ArkUI';
import { TabBarConfig } from '../common/TabBarConfig';
import { BackgroundConfig } from '../common/BackgroundConfig';
import { TabBarLabConfig } from '../common/TabBarLabConfig';
import { loadBrandColor, gAppTheme } from '../common/AppTheme';
import { initColorMode } from '../common/ColorModeConfig';
import { ScrollAnimationConfig } from '../common/ScrollAnimationConfig';
import { FlowLightConfig } from '../common/FlowLightConfig';
import { HdrLightConfig } from '../common/HdrLightConfig';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 初始化颜色模式（从 Preferences 恢复用户上次的强制设置，默认跟随系统）
    initColorMode(this.context);

    // 初始化TabBar配置（API版本检测、用户偏好及材质等级持久化恢复）
    TabBarConfig.init(this.context);

    // 初始化页面滚动错开动效开关
    ScrollAnimationConfig.init(this.context);

    // 初始化背景流光效果开关
    FlowLightConfig.init(this.context);

    // 初始化全局 HDR 光效开关
    HdrLightConfig.init(this.context);

    // 初始化TabBar调试实验室配置
    TabBarLabConfig.init(this.context);

    // 异步初始化背景图配置（从Preferences恢复上次设置）
    BackgroundConfig.init(this.context).catch((err: Error) => {
      hilog.error(DOMAIN, 'testTag', 'BackgroundConfig init failed: %{public}s', err.message);
    });

    // 从持久化加载品牌色，然后设置全局默认主题
    loadBrandColor(this.context).then(() => {
      ThemeControl.setDefaultTheme(gAppTheme);
    }).catch(() => {
      ThemeControl.setDefaultTheme(gAppTheme);
    });

    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 配置全屏沉浸模式
    windowStage.getMainWindow((err, win) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to get main window. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      try {
        // 开启全屏沉浸，内容可延伸到状态栏和导航栏区域
        win.setWindowLayoutFullScreen(true);

        // 获取顶部状态栏高度，存入 AppStorage 供页面使用
        const systemAvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        AppStorage.setOrCreate('statusBarHeight', px2vp(systemAvoidArea.topRect.height));

        // 获取底部导航指示条高度
        const naviAvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
        AppStorage.setOrCreate('bottomNaviHeight', px2vp(naviAvoidArea.bottomRect.height));
      } catch (e) {
        hilog.error(DOMAIN, 'testTag', 'Failed to setup immersive window. Cause: %{public}s', JSON.stringify(e));
      }
    });

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}

// px转vp工具函数
function px2vp(px: number): number {
  return px / 3; // 近似换算，实际开发建议用 display.getDefaultDisplaySync()
}
