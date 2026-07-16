import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const PREF_NAME = 'ColorModePref';
const KEY_COLOR_MODE = 'appColorMode';

/**
 * 应用颜色模式类型
 */
export type AppColorMode = 'system' | 'light' | 'dark';

/**
 * 初始化颜色模式
 * 从 Preferences 读取用户选择，若未设置则跟随系统
 */
export function initColorMode(context: common.Context): void {
  try {
    const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
    const saved = pref.getSync(KEY_COLOR_MODE, 'system') as string;
    applyColorMode(context, saved as AppColorMode);
    AppStorage.setOrCreate('appColorMode', saved);
  } catch {
    AppStorage.setOrCreate('appColorMode', 'system');
  }
}

/**
 * 设置并持久化颜色模式
 * @param mode 'system' 跟随系统 / 'light' 浅色 / 'dark' 深色
 * @param context 应用上下文
 */
export function setColorMode(mode: AppColorMode, context: common.Context): void {
  try {
    const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
    pref.putSync(KEY_COLOR_MODE, mode);
    pref.flush();
    applyColorMode(context, mode);
    AppStorage.setOrCreate('appColorMode', mode);
  } catch {
    // 静默失败
  }
}

/**
 * 将模式字符串映射为系统 ConfigurationConstant 并应用
 */
function applyColorMode(context: common.Context, mode: AppColorMode): void {
  let systemMode: ConfigurationConstant.ColorMode;
  switch (mode) {
    case 'light':
      systemMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
      break;
    case 'dark':
      systemMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
      break;
    case 'system':
    default:
      systemMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
      break;
  }
  try {
    context.getApplicationContext().setColorMode(systemMode);
  } catch {
    // 静默失败
  }
}

/**
 * 获取当前颜色模式
 * @returns 'system' | 'light' | 'dark'
 */
export function getColorMode(): AppColorMode {
  const mode = String(AppStorage.get('appColorMode') ?? '');
  if (mode === 'light' || mode === 'dark' || mode === 'system') {
    return mode as AppColorMode;
  }
  return 'system';
}
