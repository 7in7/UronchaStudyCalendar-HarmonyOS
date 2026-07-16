import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const PREF_NAME = 'FlowLightPref';
const KEY_BG_FLOW_LIGHT = 'bgFlowLightEnabled';
const KEY_BG_FLOW_LIGHT_DURATION = 'bgFlowLightDuration';
const KEY_BG_FLOW_LIGHT_OPACITY = 'bgFlowLightOpacity';

// 流光动画默认时长：8000ms（数值越小流动越快）
export const DEFAULT_FLOW_LIGHT_DURATION = 8000;
// 流光速度范围：2000ms ~ 20000ms
export const MIN_FLOW_LIGHT_DURATION = 2000;
export const MAX_FLOW_LIGHT_DURATION = 20000;

// 流光遮罩默认透明度：0.65
export const DEFAULT_FLOW_LIGHT_OPACITY = 0.65;
// 流光透明度范围：0.1 ~ 1.0
export const MIN_FLOW_LIGHT_OPACITY = 0.1;
export const MAX_FLOW_LIGHT_OPACITY = 1.0;

/**
 * 背景流光效果配置
 * 管理全局背景 UV_BACKGROUND_FLOW_LIGHT 效果开关、速度与透明度的持久化
 * 依赖 @kit.UIDesignKit 的 hdsEffect，需 API 20+（HarmonyOS 6.0.0）
 */
export class FlowLightConfig {
  /**
   * 初始化背景流光开关、速度与透明度
   * 应在 EntryAbility.onCreate 中调用一次
   * @param context 应用上下文
   */
  static init(context: common.Context): void {
    try {
      const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
      const savedEnabled = pref.getSync(KEY_BG_FLOW_LIGHT, false) as boolean;
      const savedDuration = pref.getSync(KEY_BG_FLOW_LIGHT_DURATION, DEFAULT_FLOW_LIGHT_DURATION) as number;
      const savedOpacity = pref.getSync(KEY_BG_FLOW_LIGHT_OPACITY, DEFAULT_FLOW_LIGHT_OPACITY) as number;
      AppStorage.setOrCreate(KEY_BG_FLOW_LIGHT, savedEnabled);
      AppStorage.setOrCreate(KEY_BG_FLOW_LIGHT_DURATION, savedDuration);
      AppStorage.setOrCreate(KEY_BG_FLOW_LIGHT_OPACITY, savedOpacity);
    } catch (e) {
      AppStorage.setOrCreate(KEY_BG_FLOW_LIGHT, false);
      AppStorage.setOrCreate(KEY_BG_FLOW_LIGHT_DURATION, DEFAULT_FLOW_LIGHT_DURATION);
      AppStorage.setOrCreate(KEY_BG_FLOW_LIGHT_OPACITY, DEFAULT_FLOW_LIGHT_OPACITY);
    }
  }

  /**
   * 当前是否启用背景流光效果
   */
  static isEnabled(): boolean {
    return AppStorage.get<boolean>(KEY_BG_FLOW_LIGHT) ?? false;
  }

  /**
   * 设置背景流光开关并持久化
   * @param value 是否启用
   * @param context 应用上下文，用于持久化
   */
  static setEnabled(value: boolean, context?: common.Context): void {
    AppStorage.setOrCreate(KEY_BG_FLOW_LIGHT, value);
    if (context) {
      try {
        const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
        pref.putSync(KEY_BG_FLOW_LIGHT, value);
        pref.flush();
      } catch (e) {
        console.error('[FlowLightConfig] Failed to save bgFlowLightEnabled to prefs');
      }
    }
  }

  /**
   * 当前流光动画时长（ms）
   */
  static getDuration(): number {
    return AppStorage.get<number>(KEY_BG_FLOW_LIGHT_DURATION) ?? DEFAULT_FLOW_LIGHT_DURATION;
  }

  /**
   * 设置流光动画时长并持久化
   * @param duration 动画时长（ms），范围 2000~20000
   * @param context 应用上下文，用于持久化
   */
  static setDuration(duration: number, context?: common.Context): void {
    const clamped = Math.max(MIN_FLOW_LIGHT_DURATION, Math.min(MAX_FLOW_LIGHT_DURATION, duration));
    AppStorage.setOrCreate(KEY_BG_FLOW_LIGHT_DURATION, clamped);
    if (context) {
      try {
        const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
        pref.putSync(KEY_BG_FLOW_LIGHT_DURATION, clamped);
        pref.flush();
      } catch (e) {
        console.error('[FlowLightConfig] Failed to save bgFlowLightDuration to prefs');
      }
    }
  }

  /**
   * 当前流光遮罩透明度（0~1）
   */
  static getOpacity(): number {
    return AppStorage.get<number>(KEY_BG_FLOW_LIGHT_OPACITY) ?? DEFAULT_FLOW_LIGHT_OPACITY;
  }

  /**
   * 设置流光遮罩透明度并持久化
   * @param opacity 透明度，范围 0.1~1.0
   * @param context 应用上下文，用于持久化
   */
  static setOpacity(opacity: number, context?: common.Context): void {
    const clamped = Math.max(MIN_FLOW_LIGHT_OPACITY, Math.min(MAX_FLOW_LIGHT_OPACITY, opacity));
    AppStorage.setOrCreate(KEY_BG_FLOW_LIGHT_OPACITY, clamped);
    if (context) {
      try {
        const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
        pref.putSync(KEY_BG_FLOW_LIGHT_OPACITY, clamped);
        pref.flush();
      } catch (e) {
        console.error('[FlowLightConfig] Failed to save bgFlowLightOpacity to prefs');
      }
    }
  }
}
