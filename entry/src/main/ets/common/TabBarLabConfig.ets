/**
 * TabBar 调试实验室配置
 * 所有属性通过 AppStorage 实时绑定，修改即时生效
 * 支持从 Preferences 持久化读取与保存
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const LAB_PREF_NAME = 'tabbar_lab_prefs';

interface LabDefaultItem {
  key: string;
  value: string | number | boolean;
}

const LAB_KEYS: string[] = [
  'labEffectRadius', 'labEffectSaturation', 'labEffectBrightness',
];

export class TabBarLabConfig {
  /**
   * 初始化所有调试属性
   * 优先从 Preferences 恢复上次保存的值，若无则使用默认值
   */
  static init(context: common.Context): void {
    const defaults: LabDefaultItem[] = [
      { key: 'labEffectRadius', value: 20 },
      { key: 'labEffectSaturation', value: 1.2 },
      { key: 'labEffectBrightness', value: 1.0 },
    ];

    let savedValues: Record<string, string | number | boolean> = {};
    try {
      const pref = preferences.getPreferencesSync(context, { name: LAB_PREF_NAME });
      LAB_KEYS.forEach((key) => {
        const val = pref.getSync(key, null);
        if (val !== null) {
          savedValues[key] = val as string | number | boolean;
        }
      });
    } catch (e) {
      console.error('[TabBarLabConfig] Failed to read prefs');
    }

    defaults.forEach((item: LabDefaultItem) => {
      const stored: string | number | boolean | undefined = AppStorage.get(item.key);
      if (stored === undefined || stored === null) {
        const savedValue = savedValues[item.key];
        AppStorage.setOrCreate(item.key, savedValue !== undefined ? savedValue : item.value);
      }
    });
  }

  /**
   * 保存单个调试属性到 Preferences
   */
  static save(context: common.Context, key: string, value: string | number | boolean): void {
    try {
      const pref = preferences.getPreferencesSync(context, { name: LAB_PREF_NAME });
      pref.putSync(key, value);
      pref.flush();
    } catch (e) {
      console.error(`[TabBarLabConfig] Failed to save ${key}`);
    }
  }

  /**
   * 一键恢复所有调试属性为默认值，并清空 Preferences
   */
  static resetToDefaults(context: common.Context): void {
    AppStorage.setOrCreate('labEffectRadius', 20);
    AppStorage.setOrCreate('labEffectSaturation', 1.2);
    AppStorage.setOrCreate('labEffectBrightness', 1.0);

    try {
      const pref = preferences.getPreferencesSync(context, { name: LAB_PREF_NAME });
      LAB_KEYS.forEach((key) => pref.deleteSync(key));
      pref.flush();
    } catch (e) {
      console.error('[TabBarLabConfig] Failed to clear prefs');
    }
  }
}
