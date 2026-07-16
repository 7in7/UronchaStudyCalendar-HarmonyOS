import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const PREF_NAME = 'ScrollAnimationPref';
const KEY_SCROLL_STAGGER = 'scrollStaggerEnabled';

/**
 * 页面滚动错开动效配置
 * 管理“页面内上下滑动时子项错开、带惯性”效果的全局开关与持久化
 */
export class ScrollAnimationConfig {
  /**
   * 初始化滚动错开动效开关
   * 应在 EntryAbility.onCreate 中调用一次
   * @param context 应用上下文
   */
  static init(context: common.Context): void {
    try {
      const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
      const saved = pref.getSync(KEY_SCROLL_STAGGER, true) as boolean;
      AppStorage.setOrCreate(KEY_SCROLL_STAGGER, saved);
    } catch (e) {
      AppStorage.setOrCreate(KEY_SCROLL_STAGGER, true);
    }
  }

  /**
   * 当前是否启用滚动错开动效
   */
  static isEnabled(): boolean {
    return AppStorage.get<boolean>(KEY_SCROLL_STAGGER) ?? true;
  }

  /**
   * 设置滚动错开动效开关并持久化
   * @param value 是否启用
   * @param context 应用上下文，用于持久化
   */
  static setEnabled(value: boolean, context?: common.Context): void {
    AppStorage.setOrCreate(KEY_SCROLL_STAGGER, value);
    if (context) {
      try {
        const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
        pref.putSync(KEY_SCROLL_STAGGER, value);
        pref.flush();
      } catch (e) {
        console.error('[ScrollAnimationConfig] Failed to save scrollStaggerEnabled to prefs');
      }
    }
  }
}

/**
 * 计算单个列表项的错开偏移系数
 * 索引越大、偏移量越大，形成上下错开的惯性感
 * @param index 子项索引
 * @param baseFactor 基础系数，默认 0.18
 */
export function staggerFactor(index: number, baseFactor: number = 0.35): number {
  return Math.min((index + 1) * baseFactor, 5.5);
}

/**
 * 将滚动帧偏移量映射为错开位移
 * @param deltaY 当前帧纵向滚动偏移量（vp）
 * @param index 子项索引
 * @param enabled 是否启用效果
 */
export function staggerOffset(deltaY: number, index: number, enabled: boolean = true): number {
  if (!enabled) {
    return 0;
  }
  const offset = deltaY * staggerFactor(index);
  // 限制最大位移，避免极速滚动时卡片过度重叠
  return Math.max(-80, Math.min(80, offset));
}
