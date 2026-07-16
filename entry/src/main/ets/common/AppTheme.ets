import { CustomColors, CustomTheme, ThemeControl } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const PREF_NAME = 'AppThemePref';
const KEY_BRAND_COLOR = 'brandColor';
const KEY_CUSTOM_BRAND_COLOR = 'customBrandColor';
export const DEFAULT_BRAND_COLOR = '#007DFF';

/**
 * RGB 分量结构
 */
export interface RgbColor {
  r: number;
  g: number;
  b: number;
}

/**
 * 应用自定义主题色
 * 定义品牌主色、警示色等令牌，支持深浅色模式
 */
export class AppColors implements CustomColors {
  // 品牌主色（用户可自定义，默认红色用于测试）
  public brand: ResourceColor = DEFAULT_BRAND_COLOR;

  // 警示色
  public warning: ResourceColor = '#FF4D4F';

  // 字体主色（跟随系统）
  public fontPrimary: ResourceColor = $r('sys.color.ohos_id_color_text_primary');
}

/**
 * 应用主题对象
 */
export class AppTheme implements CustomTheme {
  public colors: AppColors = new AppColors();
}

/**
 * 全局主题实例
 * 通过修改 gAppTheme.colors.brand 并重新 setDefaultTheme 实现动态换肤
 */
export let gAppTheme: CustomTheme = new AppTheme();

/**
 * 获取当前激活的主题色
 * 优先返回实时预览色（previewBrandColor），若无效则返回已应用色（brandColor），最后回退默认色
 * 适用于所有需要跟随主题色变化的 UI 组件
 */
export function getActiveThemeColor(): string {
  const preview = String(AppStorage.get('previewBrandColor') ?? '');
  if (preview.length > 0 && isValidHexColor(preview)) {
    return preview;
  }
  const brand = String(AppStorage.get('brandColor') ?? '');
  if (brand.length > 0 && isValidHexColor(brand)) {
    return brand;
  }
  return DEFAULT_BRAND_COLOR;
}

/**
 * 校验是否为合法的不带透明度的十六进制颜色
 * @param color 待校验字符串
 * @returns 是否合法
 */
export function isValidHexColor(color: string): boolean {
  return /^#[0-9A-Fa-f]{6}$/.test(color);
}

/**
 * 将十六进制颜色转换为 RGB 分量
 * @param hex 合法十六进制颜色，如 #FF3366
 * @returns RGB 分量对象，非法时返回 null
 */
export function hexToRgb(hex: string): RgbColor | null {
  if (!isValidHexColor(hex)) {
    return null;
  }
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return { r, g, b };
}

/**
 * 将 RGB 分量转换为十六进制颜色字符串
 * @param r 红色分量 0-255
 * @param g 绿色分量 0-255
 * @param b 蓝色分量 0-255
 * @returns 大写十六进制字符串，如 #FF3366
 */
export function rgbToHex(r: number, g: number, b: number): string {
  const clamp = (value: number): number => Math.max(0, Math.min(255, Math.round(value)));
  const toHex = (value: number): string => clamp(value).toString(16).padStart(2, '0');
  return `#${toHex(r)}${toHex(g)}${toHex(b)}`.toUpperCase();
}

/**
 * 将两种十六进制颜色按权重混合
 * @param base 基色
 * @param mix 混入色
 * @param ratio 混入比例 0-1
 * @returns 混合后的十六进制颜色
 */
export function blendColors(base: string, mix: string, ratio: number): string {
  const c1 = hexToRgb(base);
  const c2 = hexToRgb(mix);
  if (!c1 || !c2) {
    return base;
  }
  const r = c1.r * (1 - ratio) + c2.r * ratio;
  const g = c1.g * (1 - ratio) + c2.g * ratio;
  const b = c1.b * (1 - ratio) + c2.b * ratio;
  return rgbToHex(r, g, b);
}

/**
 * 根据主题色生成背景流光使用的多色源数组
 * 以主题色为主，搭配高饱和度的金色、青色、粉色，模拟 SSR 闪卡流动感
 * @param brandColor 主题色十六进制字符串
 * @returns 背景流光颜色数组
 */
export function generateFlowLightColors(brandColor: string): string[] {
  const primary = isValidHexColor(brandColor) ? brandColor : DEFAULT_BRAND_COLOR;
  return [
    primary,
    '#FFD700',  // 金色 — 高饱和，SSR 标志性光泽
    '#00FFFF',  // 青色 — 极致对比，科幻流光感
    '#FF69B4'   // 粉色 — HotPink，鲜艳夺目
  ];
}

/**
 * 根据主题色生成背景流光的目标渐变数组
 * 颜色数组相对源数组轮转一位，实现流动过程中的颜色过渡
 * @param brandColor 主题色十六进制字符串
 * @returns 目标渐变颜色数组
 */
export function generateFlowLightTarget(brandColor: string): string[] {
  const source = generateFlowLightColors(brandColor);
  return [...source.slice(1), source[0]];
}

/**
 * 更新预览主题色（仅在调色盘内实时预览，不直接影响全局组件）
 * @param color 十六进制颜色字符串
 */
export function previewBrandColor(color: string): void {
  if (isValidHexColor(color)) {
    AppStorage.setOrCreate('previewBrandColor', color);
  }
}

/**
 * 应用主题色：持久化、同步 AppStorage、刷新全局 Theme
 * @param context 应用上下文
 * @param color 十六进制颜色字符串
 */
export async function applyBrandColor(context: common.Context, color: string): Promise<void> {
  if (!isValidHexColor(color)) {
    return;
  }
  try {
    const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
    pref.putSync(KEY_BRAND_COLOR, color);
    // 只要不是默认色，就作为“上次自定义色”记住
    if (color !== DEFAULT_BRAND_COLOR) {
      pref.putSync(KEY_CUSTOM_BRAND_COLOR, color);
    }
    await pref.flush();
    (gAppTheme.colors as AppColors).brand = color;
    AppStorage.setOrCreate('brandColor', color);
    AppStorage.setOrCreate('previewBrandColor', color);
    ThemeControl.setDefaultTheme(gAppTheme);
  } catch {
    // 静默失败
  }
}

/**
 * 从 Preferences 加载品牌色并应用到全局主题
 */
export async function loadBrandColor(context: common.Context): Promise<void> {
  try {
    const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
    const saved = pref.getSync(KEY_BRAND_COLOR, DEFAULT_BRAND_COLOR) as string;
    const customSaved = pref.getSync(KEY_CUSTOM_BRAND_COLOR, '') as string;
    const validColor = isValidHexColor(saved) ? saved : DEFAULT_BRAND_COLOR;
    const validCustomColor = isValidHexColor(customSaved) ? customSaved : validColor;
    (gAppTheme.colors as AppColors).brand = validColor;
    AppStorage.setOrCreate('brandColor', validColor);
    AppStorage.setOrCreate('previewBrandColor', validColor);
    AppStorage.setOrCreate('customBrandColor', validCustomColor);
  } catch {
    (gAppTheme.colors as AppColors).brand = DEFAULT_BRAND_COLOR;
    AppStorage.setOrCreate('brandColor', DEFAULT_BRAND_COLOR);
    AppStorage.setOrCreate('previewBrandColor', DEFAULT_BRAND_COLOR);
    AppStorage.setOrCreate('customBrandColor', DEFAULT_BRAND_COLOR);
  }
}

/**
 * 保存品牌色到 Preferences 并同步到 AppStorage 实现全局响应
 * （兼容旧接口，内部也会同步 previewBrandColor）
 */
export async function saveBrandColor(context: common.Context, color: string): Promise<void> {
  if (!isValidHexColor(color)) {
    return;
  }
  try {
    const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
    pref.putSync(KEY_BRAND_COLOR, color);
    await pref.flush();
    (gAppTheme.colors as AppColors).brand = color;
    AppStorage.setOrCreate('brandColor', color);
    AppStorage.setOrCreate('previewBrandColor', color);
    ThemeControl.setDefaultTheme(gAppTheme);
  } catch {
    // 静默失败
  }
}
