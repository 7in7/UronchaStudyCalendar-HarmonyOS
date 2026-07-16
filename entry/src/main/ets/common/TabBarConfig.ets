import { deviceInfo } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const HDS_MIN_API = 23;
const PREF_NAME = 'tabbar_prefs';
const KEY_CAN_USE_HDS = 'canUseHDS';
const KEY_USE_HDS = 'useHDS';
const KEY_HDS_MATERIAL_LEVEL = 'hdsMaterialLevel';

/**
 * TabBar全局配置管理
 * 负责运行时API版本检测、HDS能力判定、沉浸光感材质配置及用户偏好持久化
 */
export class TabBarConfig {
  /**
   * 初始化TabBar配置
   * 应在EntryAbility.onCreate中调用一次
   * @param context 应用上下文，用于Preferences持久化读写
   */
  static init(context: common.Context): void {
    const apiVersion = deviceInfo.sdkApiVersion;
    const canUseHDS = apiVersion >= HDS_MIN_API;

    AppStorage.setOrCreate(KEY_CAN_USE_HDS, canUseHDS);

    // 从Preferences恢复用户上次的选择，若无记录则按设备能力给默认值
    try {
      const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
      const savedUseHDS = pref.getSync(KEY_USE_HDS, canUseHDS) as boolean;
      AppStorage.setOrCreate(KEY_USE_HDS, savedUseHDS);
    } catch (e) {
      AppStorage.setOrCreate(KEY_USE_HDS, canUseHDS);
    }

    // 从Preferences恢复材质等级，默认ADAPTIVE
    try {
      const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
      const savedLevel = pref.getSync(KEY_HDS_MATERIAL_LEVEL, 'ADAPTIVE') as string;
      AppStorage.setOrCreate(KEY_HDS_MATERIAL_LEVEL, savedLevel);
      console.info(`[TabBarConfig] Restored materialLevel from prefs: ${savedLevel}`);
    } catch (e) {
      console.error('[TabBarConfig] Failed to read prefs, fallback to ADAPTIVE');
      AppStorage.setOrCreate(KEY_HDS_MATERIAL_LEVEL, 'ADAPTIVE');
    }

    console.info(`[TabBarConfig] SDK API: ${apiVersion}, canUseHDS: ${canUseHDS}, useHDS: ${AppStorage.get(KEY_USE_HDS)}`);
  }

  /**
   * 当前设备是否支持HDS TabBar（API23+）
   */
  static isHDSSupported(): boolean {
    return AppStorage.get<boolean>(KEY_CAN_USE_HDS) ?? false;
  }

  /**
   * 当前是否使用HDS TabBar
   */
  static isUsingHDS(): boolean {
    return AppStorage.get<boolean>(KEY_USE_HDS) ?? false;
  }

  /**
   * 设置是否使用HDS TabBar
   */
  static setUseHDS(value: boolean, context?: common.Context): void {
    AppStorage.setOrCreate(KEY_USE_HDS, value);
    if (context) {
      try {
        const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
        pref.putSync(KEY_USE_HDS, value);
        pref.flush();
      } catch (e) {
        console.error('[TabBarConfig] Failed to save useHDS to prefs');
      }
    }
  }

  /**
   * 获取当前材质等级（默认ADAPTIVE）
   */
  static getMaterialLevel(): string {
    return AppStorage.get<string>(KEY_HDS_MATERIAL_LEVEL) ?? 'ADAPTIVE';
  }

  /**
   * 设置材质等级，同时持久化到Preferences
   * @param value 材质等级字符串
   * @param context 可选上下文，若提供则立即刷入Preferences
   */
  static setMaterialLevel(value: string, context?: common.Context): void {
    AppStorage.setOrCreate(KEY_HDS_MATERIAL_LEVEL, value);
    if (context) {
      try {
        const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
        pref.putSync(KEY_HDS_MATERIAL_LEVEL, value);
        pref.flush();
        console.info(`[TabBarConfig] Saved materialLevel to prefs: ${value}`);
      } catch (e) {
        console.error('[TabBarConfig] Failed to save materialLevel to prefs');
      }
    }
  }
}
