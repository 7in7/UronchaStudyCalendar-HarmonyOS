import { Course } from '../models/Course';
import { CourseRepository } from '../repository/CourseRepository';
import { common } from '@kit.AbilityKit';
import { webview } from '@kit.ArkWeb';


/**
 * WebView 页面事件
 */
interface WebPageEvent {
  url: string;
}

/**
 * 教务系统课程导入页面
 * 使用官方 Web 组件加载学校教务系统，用户登录并进入课表页后，
 * 通过 javaScriptProxy + runJavaScript 注入适配脚本抓取课表数据。
 */
@Entry
@Component
export struct CourseImportPage {
  /** WebView 控制器 */
  @State webController: webview.WebviewController = new webview.WebviewController();
  /** 当前加载的 URL */
  @State currentUrl: string = 'https://ehall.swun.edu.cn/';
  /** 是否正在提取 */
  @State isExtracting: boolean = false;
  /** 页面标题 */
  @State pageTitle: string = '教务导入';
  /** 主题色 */
  @StorageLink('brandColor') brandColor: string = '#007DFF';
  /** 当前学期 ID */
  @State semesterId: string = '';
  /** 总周数，用于校验 */
  @State totalWeeks: number = 20;

  aboutToAppear(): void {
    const params = this.getUIContext()?.getRouter()?.getParams() as Record<string, object> | null;
    this.semesterId = String(params?.['semesterId'] ?? '');
    this.totalWeeks = Number(params?.['totalWeeks'] ?? 20);
  }

  build() {
    Column() {
      // 顶部导航栏
      this.HeaderBuilder()

      // 地址栏
      this.UrlBarBuilder()

      // WebView 主体
      Web({ src: this.currentUrl, controller: this.webController })
        .width('100%')
        .layoutWeight(1)
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .fileAccess(true)
        .imageAccess(true)
        .onlineImageAccess(true)
        .mixedMode(MixedMode.All)
        .onControllerAttached(() => {
          try {
            const userAgent = this.webController.getUserAgent() + ' HMSchedule/1.0';
            this.webController.setCustomUserAgent(userAgent);
          } catch (e) {
            console.error(`[CourseImportPage] setCustomUserAgent failed: ${String(e)}`);
          }
        })
        .javaScriptProxy({
          object: {
            sendRawData: (rawData: string) => {
              this.handleRawData(rawData);
            }
          },
          name: 'nativeBridge',
          methodList: ['sendRawData'],
          controller: this.webController
        })
        .onPageBegin((event?: WebPageEvent) => {
          if (event) {
            this.currentUrl = event.url;
          }
        })
        .onPageEnd((event?: WebPageEvent) => {
          if (event) {
            this.currentUrl = event.url;
          }
          this.pageTitle = this.webController.getTitle() || '教务导入';
        })
        .onErrorReceive((event) => {
          if (event) {
            console.error(`[CourseImportPage] WebView error: ${event.error.getErrorInfo()}`);
          }
        })

      // 底部操作栏
      this.FooterBuilder()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }

  /**
   * 顶部导航栏
   */
  @Builder
  HeaderBuilder() {
    Row() {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontSize(24)
        .fontColor([$r('sys.color.ohos_id_color_primary')])
        .onClick(() => {
          this.getUIContext()?.getRouter()?.back();
        })

      Text(this.pageTitle)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.ohos_id_color_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 占位保持居中
      Blank().width(24)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor('rgba(255, 255, 255, 0.25)')
    .backgroundBlurStyle(BlurStyle.Thin)
  }

  /**
   * 地址栏
   */
  @Builder
  UrlBarBuilder() {
    Row({ space: 8 }) {
      TextInput({ text: $$this.currentUrl, placeholder: '输入教务系统网址' })
        .fontSize(13)
        .height(40)
        .layoutWeight(1)
        .backgroundColor('rgba(255, 255, 255, 0.35)')
        .onSubmit(() => {
          this.navigateToUrl(this.currentUrl);
        })

      Button('进入')
        .fontSize(13)
        .height(40)
        .backgroundColor(this.brandColor)
        .onClick(() => {
          this.navigateToUrl(this.currentUrl);
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('rgba(255, 255, 255, 0.18)')
  }

  /**
   * 底部操作栏
   */
  @Builder
  FooterBuilder() {
    Row({ space: 12 }) {
      Button(this.isExtracting ? '提取中...' : '提取课表')
        .fontSize(14)
        .height(44)
        .layoutWeight(1)
        .backgroundColor(this.brandColor)
        .enabled(!this.isExtracting)
        .onClick(() => {
          this.extractCourses();
        })

      Button('保存页面')
        .fontSize(14)
        .height(44)
        .layoutWeight(1)
        .fontColor($r('sys.color.ohos_id_color_primary'))
        .backgroundColor('rgba(255, 255, 255, 0.35)')
        .onClick(() => {
          this.savePageForDebug();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 24 })
    .backgroundColor('rgba(255, 255, 255, 0.18)')
  }

  /**
   * 导航到指定 URL
   */
  private navigateToUrl(url: string): void {
    let target = url.trim();
    if (!target) {
      return;
    }
    if (!target.startsWith('http://') && !target.startsWith('https://')) {
      target = 'https://' + target;
    }
    try {
      this.webController.loadUrl(target);
    } catch (e) {
      this.showToast('跳转失败：' + String(e));
    }
  }

  /**
   * 提取课表
   */
  private extractCourses(): void {
    this.isExtracting = true;
    const script = this.buildProviderScript();
    try {
      this.webController.runJavaScript(script);
    } catch (e) {
      this.isExtracting = false;
      this.showToast('提取失败：' + String(e));
    }
  }

  /**
   * 构建正方教务系统 Provider 脚本
   * 优先调用课表 API，失败时回退到 HTML DOM 解析。
   */
  private buildProviderScript(): string {
    return `
      (async function() {
        try {
          var xnmEl = document.getElementById('xnm');
          var xqmEl = document.getElementById('xqm');
          var xnm = xnmEl ? xnmEl.value : '';
          var xqm = xqmEl ? xqmEl.value : '';

          if (!xnm || !xqm) {
            nativeBridge.sendRawData(JSON.stringify({
              error: '未找到学年学期信息，请确保已登录并进入个人课表页面。'
            }));
            return;
          }

          // 正方教务标准课表 API
          var body = 'xnm=' + encodeURIComponent(xnm) +
                     '&xqm=' + encodeURIComponent(xqm) +
                     '&kzlx=ck&xsdm=';

          var response = await fetch('/jwglxt/kbcx/xskbcx_cxXsgrkb.html', {
            credentials: 'include',
            headers: {
              'Accept': '*/*',
              'Content-Type': 'application/x-www-form-urlencoded;charset=utf-8',
              'X-Requested-With': 'XMLHttpRequest'
            },
            body: body,
            method: 'POST',
            mode: 'cors'
          });

          var text = await response.text();
          nativeBridge.sendRawData(text);
        } catch (e) {
          nativeBridge.sendRawData(JSON.stringify({ error: String(e) }));
        }
      })();
    `;
  }

  /**
   * 处理 WebView 回传的原始数据
   */
  private handleRawData(rawData: string): void {
    this.isExtracting = false;
    if (!rawData || rawData.trim().length === 0) {
      this.showToast('未获取到课表数据');
      return;
    }

    try {
      // 先尝试按 JSON 解析（API 返回）
      const parsed: object = JSON.parse(rawData);
      const parsedObj = parsed as Record<string, string>;
      if (parsedObj && parsedObj['error']) {
        this.showToast('提取失败：' + parsedObj['error']);
        return;
      }
      const courses = this.parseApiResponse(parsed);
      this.showImportConfirm(courses);
    } catch (e) {
      // JSON 解析失败，尝试 HTML 解析
      const courses = this.parseHtmlResponse(rawData);
      if (courses.length === 0) {
        this.showToast('未能解析课表，请确认已在课表页面');
        return;
      }
      this.showImportConfirm(courses);
    }
  }

  /**
   * 解析正方教务 API 返回的 JSON
   */
  private parseApiResponse(response: object | object[]): Course[] {
    let items: object[] = [];
    if (Array.isArray(response)) {
      items = response;
    } else if (response && typeof response === 'object') {
      // 有些接口返回 { kbList: [...] }
      const anyResp = response as Record<string, object[]>;
      if (anyResp['kbList'] && Array.isArray(anyResp['kbList'])) {
        items = anyResp['kbList'];
      } else {
        // 可能是 { xxx: [...] } 单键对象
        const keys = Object.keys(anyResp);
        for (const key of keys) {
          if (Array.isArray(anyResp[key])) {
            items = anyResp[key];
            break;
          }
        }
      }
    }

    const courses: Course[] = [];
    const now = new Date().toISOString();
    for (const item of items) {
      const raw = item as Record<string, string | number>;
      const course = this.buildCourseFromRaw(raw, now);
      if (course) {
        courses.push(course);
      }
    }
    return courses;
  }

  /**
   * 解析 HTML 页面中的课表（fallback）
   */
  private parseHtmlResponse(html: string): Course[] {
    // 在 ArkTS 端做简单 HTML 解析成本较高，这里仅做基础演示。
    // 实际更推荐把 HTML 传给 WebView 再执行一段 DOM Parser 脚本返回结构化 JSON。
    const courses: Course[] = [];
    const now = new Date().toISOString();

    // 匹配 td.td_wrap 中的课程块（非常简化版）
    const cellRegex = /<td[^>]*class="td_wrap"[^>]*id="([^"]+)"[\s\S]*?<\/td>/gi;
    let match: RegExpExecArray | null = null;
    let idCounter = 1;

    while ((match = cellRegex.exec(html)) !== null) {
      const cellHtml = match[0];
      const id = match[1];
      const idParts = id.split('-');
      if (idParts.length < 1) continue;

      const dayOfWeek = parseInt(idParts[0], 10);
      if (isNaN(dayOfWeek)) continue;

      const titleMatch = cellHtml.match(/<div[^>]*class="title"[^>]*>([\s\S]*?)<\/div>/i);
      const name = titleMatch ? this.stripHtml(titleMatch[1]).trim() : '';
      if (!name) continue;

      const timeText = this.extractTextByKeywords(cellHtml, ['节', '周']);
      const locationText = this.extractTextByKeywords(cellHtml, ['校区', '楼', '室']);
      const teacherText = this.extractTeacher(cellHtml);

      const sectionMatch = timeText.match(/(\d+)-(\d+)节/);
      const startSection = sectionMatch ? parseInt(sectionMatch[1], 10) : 0;
      const endSection = sectionMatch ? parseInt(sectionMatch[2], 10) : 0;

      const weeks = this.parseWeeksFromText(timeText);

      if (startSection > 0 && endSection > 0 && weeks.length > 0) {
        courses.push({
          id: `import_${now}_${idCounter++}`,
          name,
          location: locationText,
          teacher: teacherText,
          dayOfWeek,
          startSection,
          endSection,
          weeks,
          description: '',
          semesterId: this.semesterId,
          createdAt: now,
          updatedAt: now
        });
      }
    }

    return courses;
  }

  /**
   * 从 API 原始字段构建 Course
   */
  private buildCourseFromRaw(raw: Record<string, string | number>, now: string): Course | null {
    const name = String(raw['kcmc'] || '').trim();
    if (!name) {
      return null;
    }

    const dayOfWeek = parseInt(String(raw['xqj'] || '0'), 10);
    if (isNaN(dayOfWeek) || dayOfWeek < 1 || dayOfWeek > 7) {
      return null;
    }

    const jc = String(raw['jc'] || '');
    let startSection = 0;
    let endSection = 0;
    const jcMatch = jc.match(/(\d+)-(\d+)/);
    if (jcMatch) {
      startSection = parseInt(jcMatch[1], 10);
      endSection = parseInt(jcMatch[2], 10);
    } else {
      const single = parseInt(jc, 10);
      if (!isNaN(single)) {
        startSection = single;
        endSection = single;
      }
    }
    if (startSection <= 0 || endSection <= 0) {
      return null;
    }

    const weeks = this.parseWeeksFromText(String(raw['zcd'] || ''));
    if (weeks.length === 0) {
      return null;
    }

    return {
      id: `import_${now}_${Math.random().toString(36).slice(2, 10)}`,
      name,
      location: String(raw['cdmc'] || ''),
      teacher: String(raw['xm'] || ''),
      dayOfWeek,
      startSection,
      endSection,
      weeks,
      description: '',
      semesterId: this.semesterId,
      createdAt: now,
      updatedAt: now
    };
  }

  /**
   * 从周次文本解析周次数组
   * 支持：1-16周、1-8,10-16周、单周等
   */
  private parseWeeksFromText(text: string): number[] {
    const weeks: number[] = [];
    if (!text) return weeks;

    const parts = text.split(',');
    for (const part of parts) {
      const trimmed = part.trim();
      if (!trimmed) continue;

      const rangeMatch = trimmed.match(/(\d+)-(\d+)/);
      if (rangeMatch) {
        const start = parseInt(rangeMatch[1], 10);
        const end = parseInt(rangeMatch[2], 10);
        for (let w = start; w <= end && w <= this.totalWeeks; w++) {
          weeks.push(w);
        }
      } else {
        const singleMatch = trimmed.match(/(\d+)/);
        if (singleMatch) {
          const week = parseInt(singleMatch[1], 10);
          if (week > 0 && week <= this.totalWeeks) {
            weeks.push(week);
          }
        }
      }
    }

    return weeks;
  }

  /**
   * 简单 HTML 标签剥离
   */
  private stripHtml(html: string): string {
    return html.replace(/<[^>]+>/g, '').replace(/&nbsp;/g, ' ');
  }

  /**
   * 从 HTML 块中提取包含关键字的文本
   */
  private extractTextByKeywords(cellHtml: string, keywords: string[]): string {
    const regex = /<p[^>]*>([\s\S]*?)<\/p>/gi;
    let m: RegExpExecArray | null;
    while ((m = regex.exec(cellHtml)) !== null) {
      const text = this.stripHtml(m[1]);
      if (keywords.some(k => text.includes(k))) {
        return text.trim();
      }
    }
    return '';
  }

  /**
   * 从 HTML 块中提取教师（含 glyphicon-user 的 p 标签）
   */
  private extractTeacher(cellHtml: string): string {
    const regex = /<p[^>]*>[\s\S]*?glyphicon-user[\s\S]*?<\/p>/i;
    const match = cellHtml.match(regex);
    if (match) {
      return this.stripHtml(match[0]).trim();
    }
    return '';
  }

  /**
   * 保存页面源码用于调试
   */
  private savePageForDebug(): void {
    try {
      this.webController.runJavaScript(`
        (function() {
          nativeBridge.sendRawData(document.documentElement.outerHTML);
        })();
      `);
      this.showToast('页面源码已输出到日志，请查看控制台');
    } catch (e) {
      console.error(`[CourseImportPage] savePageForDebug failed: ${String(e)}`);
      this.showToast('保存页面源码失败');
    }
  }

  /**
   * 显示导入确认
   */
  private showImportConfirm(courses: Course[]): void {
    if (courses.length === 0) {
      this.showToast('未解析到课程');
      return;
    }

    this.getUIContext()?.showAlertDialog({
      title: '导入确认',
      message: `共解析到 ${courses.length} 门课程，是否追加导入到当前学期？`,
      primaryButton: {
        value: '导入',
        action: () => {
          this.importCourses(courses, false);
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {}
      }
    });
  }

  /**
   * 导入课程到本地数据库
   */
  private async importCourses(courses: Course[], replace: boolean): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      if (replace) {
        const existing = await CourseRepository.getBySemester(context, this.semesterId);
        for (const course of existing) {
          await CourseRepository.delete(context, course.id);
        }
      }
      for (const course of courses) {
        await CourseRepository.insert(context, course);
      }
      this.showToast(`成功导入 ${courses.length} 门课程`);
      this.getUIContext()?.getRouter()?.back();
    } catch (e) {
      this.showToast('导入失败：' + String(e));
    }
  }

  /**
   * 封装 Toast，避免直接调用已弃用的 promptAction
   */
  private showToast(message: string): void {
    try {
      this.getUIContext()?.getPromptAction()?.showToast({ message });
    } catch (e) {
      console.error(`[CourseImportPage] showToast failed: ${String(e)}`);
    }
  }
}
