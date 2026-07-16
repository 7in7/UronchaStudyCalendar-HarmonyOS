import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const PREF_NAME = 'HdrLightPref';
const KEY_HDR_LIGHT_ENABLED = 'hdrLightEnabled';

/**
 * 全局 HDR 光效配置
 * 管理触摸光效（如 HDS 沉浸光感按压点光源）的 HDR 提亮开关与持久化
 *
 * 实现策略：
 * - API 24+（HarmonyOS 6.1.1）：使用 @kit.ArkGraphics2D 的 uiEffect.Filter.hdrBrightnessRatio 物理提亮
 * - API 23（HarmonyOS 6.1.0）：HDS 沉浸光感本身已包含按压点光源，开启 HDR 时强制材质等级为 EXQUISITE，
 *   以获得最亮的按压光晕与最完整的光影细节
 *
 * 需要在 module.json5 中声明 ohos.permission.HDR_BRIGHTNESS 权限（API 24+ 路径使用）
 */
export class HdrLightConfig {
  /**
   * 初始化 HDR 光效开关
   * 应在 EntryAbility.onCreate 中调用一次
   * @param context 应用上下文
   */
  static init(context: common.Context): void {
    try {
      const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
      const saved = pref.getSync(KEY_HDR_LIGHT_ENABLED, false) as boolean;
      AppStorage.setOrCreate(KEY_HDR_LIGHT_ENABLED, saved);
    } catch (e) {
      AppStorage.setOrCreate(KEY_HDR_LIGHT_ENABLED, false);
    }
  }

  /**
   * 当前是否启用 HDR 光效
   */
  static isEnabled(): boolean {
    return AppStorage.get<boolean>(KEY_HDR_LIGHT_ENABLED) ?? false;
  }

  /**
   * 设置 HDR 光效开关并持久化
   * @param value 是否启用
   * @param context 应用上下文，用于持久化
   */
  static setEnabled(value: boolean, context?: common.Context): void {
    AppStorage.setOrCreate(KEY_HDR_LIGHT_ENABLED, value);
    if (context) {
      try {
        const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
        pref.putSync(KEY_HDR_LIGHT_ENABLED, value);
        pref.flush();
      } catch (e) {
        console.error('[HdrLightConfig] Failed to save hdrLightEnabled to prefs');
      }
    }
  }
}

/**
 * HDR 提亮倍率
 * 1.0 表示标准 SDR 白；大于 1.0 时物理提亮按压光效
 * 实际最大倍率受设备 MaxBrightness / SDRWhite 限制
 */
export const HDR_BRIGHTNESS_RATIO = 1.5;
