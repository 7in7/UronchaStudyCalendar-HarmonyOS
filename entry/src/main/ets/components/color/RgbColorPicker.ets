import { hexToRgb, rgbToHex, previewBrandColor, applyBrandColor } from '../../common/AppTheme';
import { common } from '@kit.AbilityKit';

/**
 * RGB 颜色选择器组件
 * 通过 RGB 滑块与数字输入实时调整预览色，确认后才应用为全局主题色
 */
@Component
export struct RgbColorPicker {
  /** 当前预览主题色（实时更新，不直接影响全局组件） */
  @StorageLink('previewBrandColor') @Watch('onPreviewChange') previewColor: string = '#FF0000';

  /** 已确认应用的主题色（用于取消恢复） */
  @StorageLink('brandColor') brandColor: string = '#FF0000';

  /** RGB 各通道当前值，绑定滑块与输入框 */
  @State rValue: number = 255;
  @State gValue: number = 0;
  @State bValue: number = 0;

  aboutToAppear(): void {
    this.syncFromPreview();
  }

  /**
   * 预览色变化时同步到局部输入状态
   */
  private onPreviewChange(): void {
    this.syncFromPreview();
  }

  /**
   * 将 previewColor 解析并写入三个通道状态
   */
  private syncFromPreview(): void {
    const rgb = hexToRgb(this.previewColor);
    this.rValue = rgb?.r ?? 255;
    this.gValue = rgb?.g ?? 0;
    this.bValue = rgb?.b ?? 0;
  }

  /**
   * 根据当前三个通道状态更新预览色
   */
  private updatePreview(): void {
    previewBrandColor(rgbToHex(this.rValue, this.gValue, this.bValue));
  }

  /**
   * 限制输入为 0-255 整数
   */
  private clampInput(value: string): number {
    const num = parseInt(value, 10);
    if (isNaN(num)) {
      return 0;
    }
    return Math.max(0, Math.min(255, num));
  }

  build() {
    Column({ space: 12 }) {
      // R 通道
      this.RChannelSlider()

      // G 通道
      this.GChannelSlider()

      // B 通道
      this.BChannelSlider()

      // 操作按钮
      Row({ space: 12 }) {
        Button('撤销变更', { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(36)
          .backgroundColor('rgba(255,255,255,0.3)')
          .fontColor($r('sys.color.ohos_id_color_primary'))
          .onClick(() => {
            previewBrandColor(this.brandColor);
          })

        Button('确认', { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(36)
          .backgroundColor(this.previewColor)
          .fontColor(Color.White)
          .onClick(() => {
            const ctx = this.getUIContext().getHostContext() as common.Context;
            applyBrandColor(ctx, this.previewColor);
            // 通过 AppStorage 计数器通知外部刷新依赖主题色的 UI
            const version = Number(AppStorage.get('brandColorVersion') ?? 0);
            AppStorage.setOrCreate('brandColorVersion', version + 1);
          })
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
  }

  // ===== 颜色通道滑块（内联 builder，直接引用 @State 保证实时刷新）=====

  @Builder
  RChannelSlider() {
    Row({ space: 8 }) {
      Text('R')
        .fontSize(13)
        .fontColor($r('sys.color.ohos_id_color_secondary'))
        .width(20)

      Slider({ value: this.rValue, min: 0, max: 255, step: 1 })
        .layoutWeight(1)
        .selectedColor(this.previewColor)
        .onChange((v: number) => {
          this.rValue = v;
          this.updatePreview();
        })

      TextInput({ text: this.rValue.toString() })
        .width(56)
        .height(34)
        .fontSize(13)
        .type(InputType.Number)
        .backgroundColor('rgba(255,255,255,0.1)')
        .onChange((text: string) => {
          this.rValue = this.clampInput(text);
          this.updatePreview();
        })
    }
    .width('100%')
  }

  @Builder
  GChannelSlider() {
    Row({ space: 8 }) {
      Text('G')
        .fontSize(13)
        .fontColor($r('sys.color.ohos_id_color_secondary'))
        .width(20)

      Slider({ value: this.gValue, min: 0, max: 255, step: 1 })
        .layoutWeight(1)
        .selectedColor(this.previewColor)
        .onChange((v: number) => {
          this.gValue = v;
          this.updatePreview();
        })

      TextInput({ text: this.gValue.toString() })
        .width(56)
        .height(34)
        .fontSize(13)
        .type(InputType.Number)
        .backgroundColor('rgba(255,255,255,0.1)')
        .onChange((text: string) => {
          this.gValue = this.clampInput(text);
          this.updatePreview();
        })
    }
    .width('100%')
  }

  @Builder
  BChannelSlider() {
    Row({ space: 8 }) {
      Text('B')
        .fontSize(13)
        .fontColor($r('sys.color.ohos_id_color_secondary'))
        .width(20)

      Slider({ value: this.bValue, min: 0, max: 255, step: 1 })
        .layoutWeight(1)
        .selectedColor(this.previewColor)
        .onChange((v: number) => {
          this.bValue = v;
          this.updatePreview();
        })

      TextInput({ text: this.bValue.toString() })
        .width(56)
        .height(34)
        .fontSize(13)
        .type(InputType.Number)
        .backgroundColor('rgba(255,255,255,0.1)')
        .onChange((text: string) => {
          this.bValue = this.clampInput(text);
          this.updatePreview();
        })
    }
    .width('100%')
  }
}
