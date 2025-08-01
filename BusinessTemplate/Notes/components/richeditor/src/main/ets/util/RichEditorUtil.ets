export class RichEditorUtil {
  // 获取选区内的段落范围数据
  static getParagraphRange(controller: RichEditorController, range: [number, number]): RichEditorRange {
    let start = range[0];
    let end = range[1];
    if (start === end) { // 单独光标，无选区，走搜索
      let paras = controller.getParagraphs({ start: 0 });
      for (let i = 0; i < paras.length; i++) {
        let para = paras[i];
        // 当光标落在段落内时，返回该段落范围
        // 位于全文本末端时特判，归属最后一个段落
        if (para.range[0] <= start && end < para.range[1] || end === para.range[1] && i === paras.length - 1) {
          return {
            start: para.range[0],
            end: para.range[1]
          };
        }
      }
      // 无匹配时，默认全部范围
      return {
        start: 0
      };
    } else {
      // 有选区时，默认选区范围
      return {
        start: start,
        end: end
      };
    }
  }

  // 更新选区内段落样式
  static updateParagraphStyle(controller: RichEditorController, selection: RichEditorSelection,
    style: RichEditorParagraphStyle): void {
    let range = RichEditorUtil.getParagraphRange(controller, [selection.selection[0], selection.selection[1]]);
    controller.updateParagraphStyle({
      start: range.start,
      end: range.end,
      style: style
    });
  }

  // 获取选区内首个段落样式
  static getFirstParagraphStyle(controller: RichEditorController,
    range: RichEditorRange): RichEditorParagraphResult | undefined {
    let start = range.start ?? 0;
    let end = range.end ?? -1;
    if (start === end) { // 单独光标，无选区，走搜索
      let paras = controller.getParagraphs({ start: 0, end: -1 });
      for (let i = 0; i < paras.length; i++) {
        let para = paras[i];
        // 当光标落在段落内时，返回该段落范围
        // 位于全文本末端时特判，归属最后一个段落
        if (para.range[0] <= start && end < para.range[1] || end === para.range[1] && i === paras.length - 1) {
          return para;
        }
      }
      // 无匹配时，默认全部范围
      return undefined;
    } else {
      // 有选区时，默认选区范围
      let paras = controller.getParagraphs(range);
      if (paras) {
        return paras[0];
      } else {
        return undefined;
      }
    }
  }

  static updateSpanStyle(controller: RichEditorController, range: RichEditorSelection,
    style: RichEditorUpdateTextSpanStyleOptions) {
    let start = range.selection[0];
    let end = range.selection[1];
    if (start === end) {
      // 无选区，仅光标，更新输入样式
      controller.setTypingStyle(style.textStyle);
    } else {
      controller.updateSpanStyle(style);
    }
  }

  static getFirstTextSpanStyle(controller: RichEditorController,
    range: RichEditorRange): RichEditorTextSpanResult | undefined {
    let start = range.start ?? 0;
    let end = range.end ?? -1;
    if (start === end) { // 单独光标，无选区，走搜索匹配
      let spans = controller.getSpans({ start: start - 1, end: range.end });
      for (let i = 0; i < spans.length; i++) {
        let span = spans[i] as RichEditorTextSpanResult;
        if (span.textStyle !== undefined) {
          return span;
        }
      }
    } else {
      // 有选区时，默认选区范围
      let spans = controller.getSpans(range);
      if (spans) {
        for (let i = 0; i < spans.length; i++) {
          let span = spans[i] as RichEditorTextSpanResult;
          if (span.textStyle !== undefined) {
            return span;
          }
        }
      }
    }
    // 无匹配
    return undefined;
  }
}