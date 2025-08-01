import { PickerUtil } from '../util/PickerUtil';
import { COLOR_LIST, HIGHLIGHT_COLOR_FILTER, ORIGIN_COLOR_FILTER } from '../common/Constants';
import { AlignmentInfo } from '../model/AlignmentInfo';
import { RichEditorUtil } from '../util/RichEditorUtil';
import { BussController, Dt } from '../util/ControllerUtil';
import { componentSnapshot } from '@kit.ArkUI';
import { PopupUtils } from '../util/PopupUtils';
import { CommonUtils } from '../util/CommonUtils';
import { ImageUtils } from '../util/ImageUtils';
import { image } from '@kit.ImageKit';
import { SnapshotPreview } from './SnapshotPreview';

const LIST_ID = 'LIST_ID';
const RICH_ID = 'RICH_ID';

@ComponentV2
export struct RichEditorArea {
  // 当前输入样式
  @Local currentStyle: RichEditorTextStyle = {};
  // 当前编辑态
  @Local editing: boolean = false;
  // 当前笔记颜色
  @Local currentColor: number = 0;
  // 当前段落对齐样式
  @Local currentAlignment: number = 0;
  // 当前文本是否加粗
  @Local currentBold: boolean = false;
  // 当前文本是否斜体
  @Local currentItalics: boolean = false;
  // 当前文本是否有阴影
  @Local currentShadow: boolean = false;
  // 当前文本装饰线
  @Local currentDecoration: TextDecorationType = TextDecorationType.None;
  // 显示的拓展工具栏索引号 0-关闭扩展工具栏 1-显示调色盘选项栏 2-显示段落样式选项栏
  @Local showToolBarIndex: number = 0;
  selectStart: number = -1;
  selectEnd: number = -1;
  private yOffsetBefore: number = 0;
  private curYOffset: number = 0;
  @Local componentMaskImage: PixelMap | undefined = undefined;
  private scroller: Scroller = new Scroller();
  @Local snapPopupPosition: Position | undefined = { x: 0, y: 0 };
  @Local isShowPreview: boolean = false;
  private scrollYOffsets: number[] = [];
  private listComponentWidth: number = 0;
  private listComponentHeight: number = 0;
  private areaArray: image.PositionArea[] = [];
  private scrollHeight: number = 0;
  @Local mergedImage: PixelMap | undefined = undefined;
  @Local isLargePreview: boolean = false;
  @Local showScrollBar: BarState = BarState.On;
  screenWidth: number = AppStorage.get('screenWidth') || 0;
  screenHeight: number = AppStorage.get('screenHeight') || 0;
  @Local richEditorLayoutWeight: number = 0;
  @Param @Require richEditorController: RichEditorController;
  @Param bussController: BussController = new BussController();
  @Event onEditorChange: (hasChange: boolean) => void = () => {
  };
  @Event titleChange: (title: string) => void = () => {
  };
  @Param @Once @Require noteTitle: string;
  @Param @Once @Require noteContent: string;

  aboutToAppear(): void {
    this.bussController.shareData = this.onceSnapshot;
  }

  // 段落对齐样式以及点击回调
  private paragraphAlignments: AlignmentInfo[] = [
    {
      icon: $r('app.media.ic_alignment_left'),
      click: () => {
        RichEditorUtil.updateParagraphStyle(this.richEditorController, this.richEditorController.getSelection(),
          { textAlign: TextAlign.Start });
        this.currentAlignment = 0;
        animateTo({
          duration: 200,
          curve: Curve.Ease,
        }, () => {
          this.showToolBarIndex = 0;
        });

      },
    },
    {
      icon: $r('app.media.ic_alignment_center'),
      click: () => {
        RichEditorUtil.updateParagraphStyle(this.richEditorController, this.richEditorController.getSelection(),
          { textAlign: TextAlign.Center });
        this.currentAlignment = 1;
        animateTo({
          duration: 200,
          curve: Curve.Ease,
        }, () => {
          this.showToolBarIndex = 0;
        });
      },
    },
    {
      icon: $r('app.media.ic_alignment_right'),
      click: () => {
        RichEditorUtil.updateParagraphStyle(this.richEditorController, this.richEditorController.getSelection(),
          { textAlign: TextAlign.End });
        this.currentAlignment = 2;
        animateTo({
          duration: 200,
          curve: Curve.Ease,
        }, () => {
          this.showToolBarIndex = 0;
        });
      },
    },
    {
      icon: $r('app.media.ic_alignment_justify'),
      click: () => {
        RichEditorUtil.updateParagraphStyle(this.richEditorController, this.richEditorController.getSelection(),
          { textAlign: TextAlign.JUSTIFY });
        this.currentAlignment = 3;
        animateTo({
          duration: 200,
          curve: Curve.Ease,
        }, () => {
          this.showToolBarIndex = 0;
        });
      },
    },
  ];

  // 段落样式选项栏
  @Builder
  paragraphFormat() {
    Flex({
      justifyContent: FlexAlign.SpaceAround,
      alignItems: ItemAlign.Center,
    }) {
      ForEach(this.paragraphAlignments, (item: AlignmentInfo, index: number) => {
        Image(item.icon)
          .width(24)
          .colorFilter(this.currentAlignment === index ? HIGHLIGHT_COLOR_FILTER : ORIGIN_COLOR_FILTER)// 当前段落样式高亮
          .onClick(item.click);
      }, (item: AlignmentInfo) => JSON.stringify(item));
    }
    .width('100%')
    .height(56);
  }

  // 调色盘选项栏
  @Builder
  colorPalette() {
    Flex({
      justifyContent: FlexAlign.SpaceAround,
      alignItems: ItemAlign.Center,
    }) {
      ForEach(COLOR_LIST, (color: ResourceColor, index: number) => {
        Stack() {
          Circle({ width: 16, height: 16 })
            .fill(color);

          Circle({ width: 24, height: 24 })
            .fillOpacity(0)
            .borderWidth(2)
            .borderRadius(12)
            .borderColor(this.currentColor === index ? Color.Red : Color.Black);
        }
        .onClick(() => {
          this.currentColor = index;
          this.currentStyle.fontColor = color;
          let selection = this.richEditorController.getSelection();
          RichEditorUtil.updateSpanStyle(this.richEditorController, this.richEditorController.getSelection(), {
            start: selection.selection[0],
            end: selection.selection[1],
            textStyle: this.currentStyle,
          });
          animateTo({
            duration: 200,
            curve: Curve.Ease,
          }, () => {
            this.showToolBarIndex = 0;
          });
        });
      }, (color: ResourceColor) => JSON.stringify(color));
    }
    .width('100%')
    .height(56);
  }

  // 编辑工具栏
  @Builder
  toolBar() {
    Flex({
      justifyContent: FlexAlign.SpaceAround,
      alignItems: ItemAlign.Center,
    }) {
      // 调色盘图标
      Stack() {
        Rect({
          width: 16,
          height: 16,
          radius: 2,
        })
          .fill(COLOR_LIST[this.currentColor]);
        Rect({
          width: 22,
          height: 22,
          radius: 4,
        })
          .fillOpacity(0)
          .stroke(Color.Black)
          .strokeWidth(2);
      }
      .onClick(() => {
        animateTo({
          duration: 200,
          curve: Curve.Ease,
        },
          () => {
            if (this.showToolBarIndex !== 1) {
              this.showToolBarIndex = 1;
            } else {
              this.showToolBarIndex = 0;
            }
          });
      });

      // 段落对齐图标
      Image(this.paragraphAlignments[this.currentAlignment].icon)
        .width(24)
        .onClick(() => {
          animateTo({
            duration: 200,
            curve: Curve.Ease,
          }, () => {
            if (this.showToolBarIndex !== 2) {
              this.showToolBarIndex = 2;
            } else {
              this.showToolBarIndex = 0;
            }
          });
        });

      // 文本加粗图标
      Image($r('app.media.ic_bold'))
        .width(24)
        .colorFilter(this.currentBold ? HIGHLIGHT_COLOR_FILTER : ORIGIN_COLOR_FILTER)// 当前图标高亮
        .onClick(() => {
          this.currentBold = !this.currentBold;
          this.currentStyle.fontWeight = this.currentBold ? FontWeight.Bold : FontWeight.Normal;
          let selection = this.richEditorController.getSelection();
          RichEditorUtil.updateSpanStyle(this.richEditorController, this.richEditorController.getSelection(), {
            start: selection.selection[0],
            end: selection.selection[1],
            textStyle: this.currentStyle,
          });
        });

      // 文本斜体图标
      Image($r('app.media.ic_notepad_texttilt'))
        .width(24)
        .colorFilter(this.currentItalics ? HIGHLIGHT_COLOR_FILTER : ORIGIN_COLOR_FILTER)// 当前图标高亮
        .onClick(() => {
          this.currentItalics = !this.currentItalics;
          this.currentStyle.fontStyle = this.currentItalics ? FontStyle.Italic : FontStyle.Normal;
          let selection = this.richEditorController.getSelection();
          RichEditorUtil.updateSpanStyle(this.richEditorController, this.richEditorController.getSelection(), {
            start: selection.selection[0],
            end: selection.selection[1],
            textStyle: this.currentStyle,
          });
        });

      // 文本下划线图标
      Image($r('app.media.ic_underline'))
        .width(24)
        .colorFilter(this.currentDecoration === TextDecorationType.Underline ? HIGHLIGHT_COLOR_FILTER :
          ORIGIN_COLOR_FILTER)// 当前图标高亮
        .onClick(() => {
          let isUnderline = this.currentDecoration === TextDecorationType.Underline;
          this.currentDecoration = isUnderline ? TextDecorationType.None : TextDecorationType.Underline;
          this.currentStyle.decoration = { type: this.currentDecoration };
          let selection = this.richEditorController.getSelection();
          RichEditorUtil.updateSpanStyle(this.richEditorController, this.richEditorController.getSelection(), {
            start: selection.selection[0],
            end: selection.selection[1],
            textStyle: this.currentStyle,
          });
        });

      // 文本删除线图标
      Image($r('app.media.ic_deleteline'))
        .width(24)
        .colorFilter(this.currentDecoration === TextDecorationType.LineThrough ? HIGHLIGHT_COLOR_FILTER :
          ORIGIN_COLOR_FILTER)// 当前图标高亮
        .onClick(() => {
          let isLineThrough = this.currentDecoration === TextDecorationType.LineThrough;
          this.currentDecoration = isLineThrough ? TextDecorationType.None : TextDecorationType.LineThrough;
          this.currentStyle.decoration = { type: this.currentDecoration };
          let selection = this.richEditorController.getSelection();
          RichEditorUtil.updateSpanStyle(this.richEditorController, this.richEditorController.getSelection(), {
            start: selection.selection[0],
            end: selection.selection[1],
            textStyle: this.currentStyle,
          });
        });

      // 文本阴影图标
      Image($r('app.media.ic_shadow'))
        .width(24)
        .colorFilter(this.currentShadow ? HIGHLIGHT_COLOR_FILTER : ORIGIN_COLOR_FILTER)// 当前图标高亮
        .onClick(() => {
          this.currentShadow = !this.currentShadow;
          this.currentStyle.textShadow = this.currentShadow ? {
            radius: 2,
            offsetY: vp2px(1),
            offsetX: vp2px(1),
            type: ShadowType.BLUR,
          } : { radius: 0 };
          let selection = this.richEditorController.getSelection();
          RichEditorUtil.updateSpanStyle(this.richEditorController, this.richEditorController.getSelection(), {
            start: selection.selection[0],
            end: selection.selection[1],
            textStyle: this.currentStyle,
          });
        });

      // 选择图片图标
      SymbolGlyph($r('sys.symbol.picture_fill'))
        .fontSize(24)
        .onClick(() => {
          PickerUtil.selectPhoto({
            maxSelectNumber: 1,
          })
            .then((uris) => {
              let imageUri = uris[0];
              const offset = this.richEditorController.getCaretOffset();
              let option: RichEditorImageSpanOptions = {
                imageStyle: {
                  objectFit: ImageFit.Auto,
                },
                offset: offset,
              };
              this.richEditorController.addImageSpan(imageUri, option);
              this.richEditorController.addTextSpan('\n');
            });
        });

      // 清除所有文本图标
      Image($r('app.media.ic_public_delete'))
        .width(24)
        .onClick(() => {
          this.getUIContext().showAlertDialog(
            {
              message: '是否确认删除所有的文字',
              autoCancel: true,
              alignment: DialogAlignment.Center,
              primaryButton: {
                value: '取消',
                action: () => {
                },
              },
              secondaryButton: {
                enabled: true,
                defaultFocus: true,
                style: DialogButtonStyle.DEFAULT,
                fontColor: Color.Red,
                value: '确认',
                action: () => {
                  this.richEditorController.deleteSpans({ start: 0 });
                  // 清除完后，重置工具栏样式
                  this.currentStyle = {};
                  this.currentColor = 0;
                  this.currentBold = false;
                  this.currentDecoration = TextDecorationType.None;
                  this.currentItalics = false;
                  this.currentShadow = false;
                  this.currentAlignment = 0;
                },
              },
              cancel: () => {
              },
              onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
                if (dismissDialogAction.reason === DismissReason.PRESS_BACK ||
                  dismissDialogAction.reason === DismissReason.TOUCH_OUTSIDE) {
                  dismissDialogAction.dismiss();
                }
              },
            },
          );
        });
    }
    .height(60)
    .width('100%')
    .padding({
      left: 16,
      right: 16,
    })
    .backgroundColor('#F2F2F2');
  }

  onceSnapshot = async () => {
    this.showScrollBar = BarState.Off;
    await this.beforeSnapshot();
    await this.snapAndMerge();
    await this.afterSnapshot();
    this.afterGeneratorImage();
  };

  async beforeSnapshot() {
    this.yOffsetBefore = this.curYOffset;
    // Take a screenshot of the loaded List component as a cover image for the List component
    this.componentMaskImage = await componentSnapshot.get(LIST_ID);
    this.scroller.scrollTo({
      xOffset: 0,
      yOffset: 0,
      animation:
      {
        duration: 200,
      },
    });
    this.snapPopupPosition = PopupUtils.calcPopupCenter(this.screenWidth, this.screenHeight, 100, 200);
    this.isShowPreview = true;
    // Delay ensures that the scroll has reached the top
    await CommonUtils.sleep(200);
  }

  async snapAndMerge() {
    this.scrollYOffsets.push(this.curYOffset);
    // Call the component screenshot interface to obtain the current screenshot
    const pixelMap = await componentSnapshot.get(LIST_ID);
    // Gets the number of bytes per line of image pixels.
    let area: image.PositionArea =
      await ImageUtils.getSnapshotArea(pixelMap, this.scrollYOffsets, this.listComponentWidth,
        this.listComponentHeight);
    this.areaArray.push(area);
    // Determine whether the bottom has been reached during the loop process
    if (!this.scroller.isAtEnd()) {
      CommonUtils.scrollAnimation(this.scroller, 200, this.scrollHeight);
      await CommonUtils.sleep(200);
      await this.snapAndMerge();
    } else {
      this.mergedImage =
        await ImageUtils.mergeImage(this.areaArray, this.scrollYOffsets[this.scrollYOffsets.length - 1],
          this.listComponentWidth, this.listComponentHeight);
    }
  }

  async afterSnapshot() {
    this.scroller.scrollTo({
      xOffset: 0,
      yOffset: this.yOffsetBefore,
      animation: {
        duration: 200,
      },
    });
    await CommonUtils.sleep(200);
  }

  async afterGeneratorImage() {
    // Delay for transition animation
    await CommonUtils.sleep(200);
    this.snapPopupPosition = PopupUtils.calcPopupBottomLeft(this.screenHeight, 200);
    this.componentMaskImage = undefined;
    this.scrollYOffsets.length = 0;
    this.areaArray.length = 0;
    this.showScrollBar = BarState.On;
  }

  @Builder
  previewWindowComponent() {
    Column() {
      SnapshotPreview({
        mergedImage: this.mergedImage,
        snapPopupPosition: this.snapPopupPosition,
        isLargePreview: this.isLargePreview,
        isShowPreview: this.isShowPreview,
        changeMergedImage: (mergedImage) => {
          this.mergedImage = this.mergedImage;
        },
        changeSnapPopupPosition: (snapPopupPosition) => {
          this.snapPopupPosition = snapPopupPosition;
        },
        changeIsShowPreview: (showPreview: boolean) => {
          this.isShowPreview = showPreview;
        },
        changeIsLargePreview: (largePreview: boolean) => {
          this.isLargePreview = largePreview;
        },
      });
    };
  }

  build() {
    Column() {
      Column() {
        Stack() {
          if (this.componentMaskImage) {
            Image(this.componentMaskImage)
              .width('100%')
              .height('100%')
              .zIndex(2)
              .backgroundColor('#FFDCDCDC');
          }
          Scroll(this.scroller) {
            Column() {
              TextInput({
                placeholder: '标题',
                text: this.noteTitle,
              })
                .width('100%')
                .height(24)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .backgroundColor('#fff')
                .borderRadius(0)
                .onChange((value: string) => {
                  this.noteTitle = value;
                  this.titleChange(value);
                })
                .placeholderFont({
                  size: 18,
                  weight: FontWeight.Bold,
                })
                .margin({
                  top: 12,
                })
                .padding({
                  top: 0,
                  bottom: 0,
                });

              RichEditor({ controller: this.richEditorController })
                .layoutWeight(this.richEditorLayoutWeight)
                .placeholder('记录现在的想法...')
                .backgroundColor('#fff')
                .padding({ top: 14, bottom: 14 })
                .onReady(() => {
                  if (this.noteContent !== '') {
                    const dt: [] = JSON.parse(this.noteContent);
                    dt.forEach((item) => {
                      if (typeof (item as RichEditorImageSpanResult).imageStyle !== 'undefined') {
                        const size: number[] = (item as RichEditorImageSpanResult).imageStyle.size;
                        const width: Dimension = `${size[0]}px`;
                        const height: Dimension = `${size[1]}px`;
                        this.richEditorController.addImageSpan((item as RichEditorImageSpanResult).valueResourceStr, {
                          imageStyle: {
                            size: [width, height],
                          },
                        });

                      } else {
                        if (typeof (item as RichEditorTextSpanResult).symbolSpanStyle !== 'undefined') {
                          this.richEditorController.addSymbolSpan((item as RichEditorTextSpanResult).valueResource, {
                            style: {
                              fontSize: (item as RichEditorTextSpanResult).symbolSpanStyle?.fontSize,
                            },
                          });
                        } else {
                          this.richEditorController.addTextSpan((item as RichEditorTextSpanResult).value, {
                            style: (item as RichEditorTextSpanResult).textStyle,
                            paragraphStyle: (item as RichEditorTextSpanResult).paragraphStyle,
                          });
                        }
                      }
                    });

                  }
                  this.onEditorChange(false);
                })
                .onEditingChange((editingStatus) => {
                  this.editing = editingStatus;
                  console.info('editingStatus:' + editingStatus);
                  if (this.editing) {
                    this.richEditorLayoutWeight = 1;
                  } else {
                    this.richEditorLayoutWeight = 0;
                  }
                })
                .onSelectionChange((range) => {
                  // 光标移动时，更新编辑栏状态显示
                  // 更新文本颜色状态
                  let textStyleResult = RichEditorUtil.getFirstTextSpanStyle(this.richEditorController, range);
                  if (textStyleResult?.textStyle.fontColor) {
                    let index = COLOR_LIST.indexOf(textStyleResult?.textStyle.fontColor);
                    if (index !== -1) {
                      this.currentColor = index;
                    } else {
                      this.currentColor = 0;
                    }
                  }

                  // 更新加粗状态
                  // 字重参数，请参考官方文档 RichEditorTextStyleResult
                  this.currentBold = textStyleResult?.textStyle.fontWeight === 9;

                  // 更新装饰线状态
                  if (textStyleResult?.textStyle.decoration.type) {
                    this.currentDecoration = textStyleResult?.textStyle.decoration.type;
                  } else {
                    this.currentDecoration = TextDecorationType.None;
                  }

                  // 更新斜体状态
                  this.currentItalics = textStyleResult?.textStyle.fontStyle === FontStyle.Italic;

                  // 更新阴影状态
                  let shadows = textStyleResult?.textStyle.textShadow;
                  if (shadows && shadows.length) {
                    if (shadows[0].radius !== 0) {
                      this.currentShadow = true;
                    } else {
                      this.currentShadow = false;
                    }
                  } else {
                    this.currentShadow = false;
                  }

                  // 更新段落样式
                  // 延时是因为异步操作，换行时直接获取，会导致获取到的是刚初始化的样式，而不是真实样式，导致显示错误
                  // 与文本样式判定范围有出入（文本样式向前看齐，段落样式向后看齐），所以单独判定
                  setTimeout(() => {
                    let paraStyleResult = RichEditorUtil.getFirstParagraphStyle(this.richEditorController, range);
                    switch (paraStyleResult?.style?.textAlign) {
                      case TextAlign.Center:
                        this.currentAlignment = 1;
                        break;
                      case TextAlign.End:
                        this.currentAlignment = 2;
                        break;
                      case TextAlign.JUSTIFY:
                        this.currentAlignment = 3;
                        break;
                      case TextAlign.Start:
                        this.currentAlignment = 0;
                    }
                  }, 100);

                  this.currentStyle = {
                    fontColor: COLOR_LIST[this.currentColor],
                    fontWeight: this.currentBold ? FontWeight.Bold : FontWeight.Normal,
                    decoration: { type: this.currentDecoration },
                    fontStyle: this.currentItalics ? FontStyle.Italic : FontStyle.Normal,
                    textShadow: this.currentShadow ? {
                      radius: 2,
                      offsetY: vp2px(1),
                      offsetX: vp2px(1),
                      type: ShadowType.BLUR,
                    } : { radius: 0 },
                  };
                })
                .onSelect((value: RichEditorSelection) => {
                  this.selectStart = value.selection[0];
                  this.selectEnd = value.selection[1];
                })
                .onCopy((event: CopyEvent) => {
                  // event.preventDefault!();
                  const copyData = this.richEditorController.getSpans({
                    start: this.selectStart,
                    end: this.selectEnd,
                  });
                  Dt.copyData = JSON.stringify(copyData);
                })
                .onPaste((event: CopyEvent) => {
                  event.preventDefault!();
                  if (Dt.copyData !== '') {
                    const dt: [] = JSON.parse(Dt.copyData);
                    dt.forEach((item) => {
                      if (typeof (item as RichEditorImageSpanResult).imageStyle !== 'undefined') {
                        const size: number[] = (item as RichEditorImageSpanResult).imageStyle.size;
                        const width: Dimension = `${size[0]}px`;
                        const height: Dimension = `${size[1]}px`;
                        this.richEditorController.addImageSpan((item as RichEditorImageSpanResult).valueResourceStr, {
                          imageStyle: {
                            size: [width, height],
                          },
                        });

                      } else {
                        if (typeof (item as RichEditorTextSpanResult).symbolSpanStyle !== 'undefined') {
                          this.richEditorController.addSymbolSpan((item as RichEditorTextSpanResult).valueResource, {
                            style: {
                              fontSize: (item as RichEditorTextSpanResult).symbolSpanStyle?.fontSize,
                            },
                          });
                        } else {
                          this.richEditorController.addTextSpan((item as RichEditorTextSpanResult).value, {
                            style: (item as RichEditorTextSpanResult).textStyle,
                          });
                        }
                      }
                    });

                  }
                })
                .barState(BarState.Off)
                .onDidChange(() => {
                  if (this.noteContent !== '') {
                    const richData = JSON.stringify(this.richEditorController.getSpans());
                    if (richData !== this.noteContent) {
                      this.onEditorChange(true);
                    } else {
                      this.onEditorChange(false);
                    }
                  } else {
                    this.onEditorChange(true);
                  }
                })
                .id(RICH_ID);
            }
            .width('100%');
          }
          .scrollBar(this.showScrollBar)
          .id(LIST_ID)
          .align(Alignment.Top)
          .width('100%')
          .height('100%')
          .onAreaChange((oldValue, newValue) => {
            this.listComponentWidth = newValue.width as number;
            this.listComponentHeight = newValue.height as number;
            this.scrollHeight = this.listComponentHeight;
          })
          .onDidScroll(() => {
            this.curYOffset = this.scroller.currentOffset().yOffset;
          })
          .onClick(() => {
            // 点击空白出RichEditor自动聚焦
            this.getUIContext().getFocusController().requestFocus(RICH_ID);
          });

        }
        .layoutWeight(1)
        .backgroundColor('#fff')
        .width('100%')
        .borderRadius({
          topLeft: 16,
          topRight: 16,
        })
        .bindContentCover(this.isShowPreview, this.previewWindowComponent(), {
          modalTransition: ModalTransition.NONE,
          onWillDismiss: (action: DismissContentCoverAction) => {
            if (action.reason === DismissReason.PRESS_BACK) {
            }
          },
        });
      }
      .width('100%')
      .padding({
        top: 8,
        left: 16,
        right: 16,
      })
      .layoutWeight(1);

      if (this.editing) {
        if (this.showToolBarIndex === 1) {
          this.colorPalette();
        } else if (this.showToolBarIndex === 2) {
          this.paragraphFormat();
        }
        this.toolBar();
      }
    }
    .height('100%')
    .width('100%');
  }
}