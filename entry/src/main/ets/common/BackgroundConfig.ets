import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

const PREF_NAME = 'app_settings';
const KEY_BG_IMAGE = 'background_image_uri';
const KEY_BG_DEFAULT = 'background_use_default';
const BG_DIR = 'backgrounds';

/**
 * 应用背景图配置管理
 * 负责背景图的持久化存储、相册选图及沙箱文件管理
 * 使用 PhotoViewPicker（无需权限）拉起系统相册
 */
export class BackgroundConfig {
  /**
   * 初始化背景配置，从Preferences恢复上次设置到AppStorage
   */
  static async init(context: common.Context): Promise<void> {
    try {
      const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
      const uri = pref.getSync(KEY_BG_IMAGE, '') as string;
      const useDefault = pref.getSync(KEY_BG_DEFAULT, true) as boolean;

      AppStorage.setOrCreate('bgImageUri', uri);
      AppStorage.setOrCreate('bgUseDefault', useDefault);

      console.info(`[BackgroundConfig] restored: useDefault=${useDefault}`);
    } catch (err) {
      console.error('[BackgroundConfig] init failed', (err as BusinessError).message);
    }
  }

  /**
   * 从相册选择背景图并拷贝到应用沙箱
   * 返回沙箱路径，失败或取消返回null
   */
  static async pickBackgroundImage(context: common.Context): Promise<string | null> {
    try {
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;

      const picker = new photoAccessHelper.PhotoViewPicker();
      const result = await picker.select(options);

      if (result.photoUris.length === 0) {
        return null;
      }

      const sourceUri = result.photoUris[0];
      return await BackgroundConfig.copyToSandbox(context, sourceUri);
    } catch (err) {
      console.error('[BackgroundConfig] pick failed', (err as BusinessError).message);
      return null;
    }
  }

  /**
   * 保存背景图沙箱路径到Preferences并同步AppStorage
   * 同时清理旧背景图文件
   */
  static async saveBackgroundUri(context: common.Context, uri: string): Promise<void> {
    const oldUri = AppStorage.get<string>('bgImageUri') ?? '';

    try {
      const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
      pref.putSync(KEY_BG_IMAGE, uri);
      pref.putSync(KEY_BG_DEFAULT, false);
      await pref.flush();

      AppStorage.setOrCreate('bgImageUri', uri);
      AppStorage.setOrCreate('bgUseDefault', false);
    } catch (err) {
      console.error('[BackgroundConfig] save failed', (err as BusinessError).message);
      return;
    }

    // 清理旧背景图文件，避免沙箱膨胀
    if (oldUri && oldUri !== uri) {
      try {
        fileIo.unlinkSync(oldUri);
      } catch (e) {
        console.warn('[BackgroundConfig] cleanup old file failed', e);
      }
    }

    console.info(`[BackgroundConfig] saved: ${uri}`);
  }

  /**
   * 恢复默认背景（清除自定义背景图设置并删除沙箱文件）
   */
  static async resetToDefault(context: common.Context): Promise<void> {
    const oldUri = AppStorage.get<string>('bgImageUri') ?? '';

    try {
      const pref = preferences.getPreferencesSync(context, { name: PREF_NAME });
      pref.putSync(KEY_BG_IMAGE, '');
      pref.putSync(KEY_BG_DEFAULT, true);
      await pref.flush();

      AppStorage.setOrCreate('bgImageUri', '');
      AppStorage.setOrCreate('bgUseDefault', true);
    } catch (err) {
      console.error('[BackgroundConfig] reset failed', (err as BusinessError).message);
      return;
    }

    if (oldUri) {
      try {
        fileIo.unlinkSync(oldUri);
      } catch (e) {
        console.warn('[BackgroundConfig] cleanup file failed', e);
      }
    }

    console.info('[BackgroundConfig] reset to default');
  }

  /**
   * 将图库URI拷贝到应用沙箱filesDir/backgrounds目录
   */
  private static async copyToSandbox(context: common.Context, sourceUri: string): Promise<string> {
    const bgDir = context.filesDir + '/' + BG_DIR;
    try {
      fileIo.mkdirSync(bgDir, true);
    } catch (e) {
      // 目录已存在时忽略错误
    }

    let resFile: fileIo.File | undefined;
    try {
      resFile = fileIo.openSync(sourceUri, fileIo.OpenMode.READ_ONLY);
      const fileName = `bg_${Date.now()}.jpg`;
      const destPath = bgDir + '/' + fileName;

      fileIo.copyFileSync(resFile.fd, destPath);

      // 加上 file:// 前缀，确保Image组件能正确识别沙箱路径
      return 'file://' + destPath;
    } catch (err) {
      const message = (err as BusinessError).message;
      console.error('[BackgroundConfig] copy to sandbox failed', message);
      throw new Error(message);
    } finally {
      if (resFile !== undefined) {
        try {
          fileIo.closeSync(resFile);
        } catch (e) {
          console.warn('[BackgroundConfig] close file failed', e);
        }
      }
    }
  }
}
