import { Category, CategoryService, Note, NoteService } from '@ohos_agcit/notes_datasource';
import { CommonConstants, DateConstants, DateUtil } from '@ohos_agcit/notes_utils';
import { CustomContentDialog, PersistenceV2 } from '@kit.ArkUI';
import { unifiedDataChannel } from '@kit.ArkData';
import { Callback, pasteboard } from '@kit.BasicServicesKit';
import { SecretLock } from 'secretlock';
import { Dt } from 'richeditor';

@Entry
@ComponentV2
struct Index {
  @Local rotateAngle: number = 0;
  @Provider('appPathStack') appPathStack: NavPathStack = new NavPathStack();
  categoryService: CategoryService = CategoryService.instance;
  noteService: NoteService = NoteService.instance;
  @Local noteList: Note[] = [];
  @Local sortBy: string = 'createTime'; // 排序方式选择
  @Local currentCategory: Category = this.categoryService.getFirstCategory();
  private currentNote: Note | undefined;
  @Local secretLock: SecretLock = PersistenceV2.connect(SecretLock, () => new SecretLock())!!;
  @Local searchKeyword: string = ''; // 搜索关键词
  @Local isSearching: boolean = false; // 是否正在搜索状态
  private searchController: SearchController = new SearchController();

  aboutToAppear(): void {
    if (this.secretLock.gesture) {
      const params: Record<string, Object> = { 'fromEntrance': true, 'appPathStack': this.appPathStack };
      this.appPathStack.pushPathByName('DrawLock', params);
    }

    this.noteService.getNoteList(this.currentCategory.id, this.sortBy, this.searchKeyword);
  }

  categoryDialogController: CustomDialogController = new CustomDialogController({
    builder: () => {
      this.showCategoryDialog(
        this.categoryService.getCategoryList(),
        () => {
          this.categoryDialogController.close();
          const params: Record<string, Object | undefined> =
            { 'isEditCategory': true, 'currentCategory': this.currentCategory, 'currentNote': this.currentNote };
          this.appPathStack.pushPathByName('EditCategory', params);
        },
        () => {
          this.categoryDialogController.close();
        },
      );
    },
    alignment: DialogAlignment.BottomEnd,
    cornerRadius: {
      topLeft: 16,
      topRight: 16,
      bottomLeft: 0,
      bottomRight: 0,
    },
    width: CommonConstants.FULL_PERCENT,
  });
  // 排序对话框控制器
  sortDialogController: CustomDialogController = new CustomDialogController({
    builder: () => {
      this.sortDialog();
    },
    alignment: DialogAlignment.Bottom,
    cornerRadius: {
      topLeft: 16,
      topRight: 16,
      bottomLeft: 0,
      bottomRight: 0,
    },
    width: CommonConstants.FULL_PERCENT,
    backgroundColor: '#F1F3F5',
  });
  noteDialogController: CustomDialogController = new CustomDialogController({
    builder: () => {
      this.editorNoteDialog();
    },
    alignment: DialogAlignment.BottomEnd,
    cornerRadius: {
      topLeft: 16,
      topRight: 16,
      bottomLeft: 0,
      bottomRight: 0,
    },
    width: CommonConstants.FULL_PERCENT,
  });
  deleteNoteController: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.delete_note'),
      contentBuilder: () => {
        this.deleteDialogContent();
      },
      buttons: [
        {
          value: $r('app.string.cancel'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            this.noteDialogController.close();
          },
        },
        {
          value: $r('app.string.confirm'),
          buttonStyle: ButtonStyleMode.TEXTUAL,
          role: ButtonRole.ERROR,
          action: () => {
            this.noteService.deleteNote(this.currentNote?.id, this.currentNote?.categoryId);

            this.noteList =
              this.noteService.getNoteList(this.currentCategory.id, this.sortBy,
                this.searchKeyword);
            this.noteDialogController.close();
          },
        },
      ],
    }),
  });

  // 排序确认方法
  onSortConfirm(sortBy: string) {
    this.sortBy = sortBy;
    this.noteService.getNoteList(this.currentCategory.id, this.sortBy, this.searchKeyword);
    if (this.sortDialogController != null) {
      this.sortDialogController.close();
    }
  }

  // 添加搜索方法
  onSearch(keyword: string) {
    this.searchKeyword = keyword.trim();
    this.isSearching = this.searchKeyword.length > 0;
    // 执行搜索
    this.noteList = this.noteService.getNoteList(this.currentCategory.id, this.sortBy, this.searchKeyword);
  }

  build() {
    Navigation(this.appPathStack) {
      Column() {
        Column() {
          this.topArea();
          // 搜索框
          Search({
            placeholder: $r('app.string.search_note'),
            controller: this.searchController,
          })
            .onSubmit((value: string) => { // 提交搜索
              this.onSearch(value);
            })
            .onChange((value: string) => { // 输入变化时
              if (!value) {
                this.onSearch(''); // 清空搜索时恢复列表
              }
            })
            .margin({ bottom: 12 });

          this.editorNoteList();
          this.showNoteList();
        }
        .margin({
          left: 16,
          right: 16,
          bottom: 20
        })

        Stack({ alignContent: Alignment.Center }) {
          Row()
            .width(50)
            .height(50)
            .borderRadius(44)
            .backgroundColor('#FFAA00');
          SymbolGlyph($r('sys.symbol.plus'))
            .fontColor([Color.White])
            .fontSize(35);
        }
        .position({ right: 30, bottom: 100 })
        .onClick(() => {
          const params: Record<string, Object> = { 'noteId': '', 'currentCategory': this.currentCategory };
          this.appPathStack.pushPathByName('EditNotes', params);
        })
      }
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
      .linearGradient({
        angle: 180,
        colors: [['#FFF0D4', 0], ['#E4E1D1', 0.08],['#F1F3F5', 0.2],['#F1F3F5', 1]],
      })
      .backgroundColor('#F1F3F5')
      .width(CommonConstants.FULL_PERCENT)
      .height(CommonConstants.FULL_PERCENT);
    }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .onNavBarStateChange(() => {
      this.searchKeyword = '';
      this.noteList = this.noteService.getNoteList(this.currentCategory.id, this.sortBy, this.searchKeyword);
    });
  }

  @Builder
  topArea() {
    Row() {
      Text($r('app.string.homepage'))
        .fontSize(24)
        .fontWeight(FontWeight.Medium);
      Blank();
      Image($r('app.media.user_avatar'))
        .width(32)
        .onClick(() => {
          this.appPathStack.pushPathByName('MineView', undefined);
        });
    }
    .width(CommonConstants.FULL_PERCENT)
    .padding({
      top: 12,
      bottom: 20,
    });
  }

  @Builder
  editorNoteList() {
    Row() {
      Row({ space: 4 }) {
        Text(this.currentCategory.name);
        SymbolGlyph($r('sys.symbol.arrowtriangle_down_fill'))
          .fontColor(['rgba(0,0,0,0.60)']);
      }.onClick(() => {
        if (this.categoryDialogController != null) {
          this.categoryDialogController.open();
        }
      });

      Blank();
      Image($r('app.media.icon_more'))
        .height(16)
        .onClick(() => {
          if (this.sortDialogController != null) {
            this.sortDialogController.open();
          }
        });
    }
    .width(CommonConstants.FULL_PERCENT)
    .margin({
      top: 12,
      bottom: 12,
    });
  }

  @Builder
  showNoteList() {
    if (this.isSearching && this.noteList.length === 0) {
      // 搜索无结果提示
      Column() {
        Text($r('app.string.no_match_note'))
          .fontSize(16)
          .fontColor(Color.Gray);
      }
      .width(CommonConstants.FULL_PERCENT)
      .height(100)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center);
    } else {
      Column(){
        List({ space: 12 }) {
          ForEach(this.noteList, (item: Note) => {
            ListItem() {
              Column() {
                Row(){
                  Text(item.title)
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .height(40)

                Row(){
                  Text(item.description)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .fontSize(14)
                    .fontWeight(FontWeight.Regular)
                }
                .height(35)

                Row() {
                  Text(DateUtil.getFormatDateStr(item.createTime, DateConstants.DATE_FORMAT4))
                    .fontSize(12);
                  Blank();
                  Image($r('app.media.note_more'))
                    .width(20)
                    .onClick(() => {
                      this.currentNote = item;
                      this.noteDialogController.open();
                    });
                }
                .width(CommonConstants.FULL_PERCENT)
                .height(30)
              }
              .alignItems(HorizontalAlign.Start)
              .backgroundColor(Color.White)
              .borderRadius(16)
              .width(CommonConstants.FULL_PERCENT)
              .height(105)
              .padding({
                left: 12,
                right: 12,
              })
              .onClick(() => {
                const params: Record<string, Object> = { 'noteId': item.id, 'currentCategory': this.currentCategory };
                this.appPathStack.pushPathByName('EditNotes', params);
              });
            }
            .gesture(
              // 绑定可以重复触发的LongPressGesture
              LongPressGesture({ repeat: false, fingers: 1, duration: 500 })
                .onAction((event: GestureEvent|undefined) => {
                  if(event){
                    this.currentNote = item;
                    this.noteDialogController.open();
                  }
                })
            )
          }, (item: Note) => item.id);
        }
        .scrollBar(BarState.Off);
      }
      .layoutWeight(1)
    }
  }

  @Builder
  showCategoryDialog(categoryList: Array<Category>,
    onNoteCategoryButtonClick: Callback<void>,
    onCloseButtonClick: Callback<void>) {
    Column() {
      Column() {
        Row() {
          Text($r('app.string.note_category'))
            .fontSize(20)
            .fontWeight(FontWeight.Medium);
          Blank();
          Stack({ alignContent: Alignment.Center }) {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontWeight(FontWeight.Bold)
              .fontSize(14)
              .fontColor(['rgba(0,0,0,0.90)']);
            Row()
              .width(40)
              .height(40)
              .borderRadius(40)
              .backgroundColor('rgba(0,0,0,0.05)');
          }
          .onClick(() => {
            onCloseButtonClick();
          });
        }
        .width(CommonConstants.FULL_PERCENT)
        .margin({
          top: 37,
          bottom: 26,
        });

        Column() {
          List() {
            ForEach(categoryList, (category: Category, index: number) => {
              ListItem() {
                Column() {
                  if (index !== 0) {
                    Divider()
                      .color('rgba(0,0,0,0.20)');
                  }
                  Row() {
                    Text(category.name)
                      .fontSize(16)
                      .fontColor(this.currentCategory.id === category.id ? 'rgba(0,0,0,0.90)' : 'rgba(0,0,0,0.60)')
                      .fontWeight(this.currentCategory?.id === category.id ? FontWeight.Medium : FontWeight.Regular)

                    Blank();
                    Text(String(category.totalCount))
                      .fontSize(16);
                  }
                  .width(CommonConstants.FULL_PERCENT)
                  .height(50)
                }
              }
              .backgroundColor(Color.White)
              .padding({
                left: 12,
                right: 12,
              })
              .onClick(() => {
                this.currentCategory = category;
                this.isSearching = false; // 重置搜索状态
                this.searchKeyword = '';
                this.noteList = this.noteService.getNoteList(this.currentCategory.id, this.sortBy, this.searchKeyword);
                this.categoryDialogController.close();
              });
            }, (category: Category) => category.id);
          }
          .borderRadius(8)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.None);
        }
        .height(200);

        Blank();
        Button() {
          Row() {
            Text($r('app.string.go_note_category'))
              .fontSize(16)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium);
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontWeight(FontWeight.Medium)
              .fontSize(18)
              .fontColor([Color.White])
              .padding({
                left: 13,
              })
          }
        }
        .height(40)
        .width(CommonConstants.FULL_PERCENT)
        .backgroundColor('#FFAA00')
        .margin({
          bottom: 30,
        })
        .onClick(() => {
          onNoteCategoryButtonClick();
        });
      }
      .height(400)
      .margin({
        left: '4%',
        right: '4%',
      });
    }
    .backgroundColor('#F1F3F5');
  }

  @Builder
  editorNoteDialog() {
    Column() {
      Column() {
        Row() {
          Text($r('app.string.more'))
            .fontSize(20)
            .fontWeight(FontWeight.Medium);
          Blank();
          Stack({ alignContent: Alignment.Center }) {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontWeight(FontWeight.Bold)
              .fontSize(14)
              .fontColor(['rgba(0,0,0,0.90)']);
            Row()
              .width(40)
              .height(40)
              .borderRadius(40)
              .backgroundColor('rgba(0,0,0,0.05)');
          }
          .onClick(() => {
            this.noteDialogController.close();
          });
        }
        .width(CommonConstants.FULL_PERCENT)
        .margin({
          top: 37,
          bottom: 26,
        });

        Column() {
          List() {
            ListItem() {
              Column() {
                Row({ space: 8 }) {
                  Image($r('app.media.copy_content'))
                    .width(16);
                  Text($r('app.string.copy_content'))
                    .fontSize(16)
                    .fontColor('rgba(0,0,0,0.60)');
                }
                .width(CommonConstants.FULL_PERCENT)
                .height(50);
              };
            }
            .backgroundColor(Color.White)
            .padding({
              left: 12,
              right: 12,
            })
            .onClick(() => {
              let copyText = this.currentNote?.description || '';
              let plainTextData = new unifiedDataChannel.UnifiedData();
              let plainText = new unifiedDataChannel.PlainText();
              plainText.details = {
                key: 'delayPlaintext',
                value: copyText,
              };
              plainText.textContent = copyText;
              plainText.abstract = 'delayTextContent';
              plainTextData.addRecord(plainText);
              let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
              systemPasteboard.setUnifiedData(plainTextData);
              Dt.copyData = this.currentNote?.content || '';
              this.noteDialogController.close();
            });

            ListItem() {
              Column() {
                Divider()
                  .color('rgba(0,0,0,0.20)');
                Row({ space: 8 }) {
                  Image($r('app.media.move_category'))
                    .width(16);

                  Text($r('app.string.move_to_other_category'))
                    .fontSize(16)
                    .fontColor('rgba(0,0,0,0.60)');
                }
                .width(CommonConstants.FULL_PERCENT)
                .height(50);
              };
            }
            .backgroundColor(Color.White)
            .padding({
              left: 12,
              right: 12,
            })
            .onClick(() => {
              const params: Record<string, Object | undefined> =
                { 'isEditCategory': false, 'currentCategory': this.currentCategory, 'currentNote': this.currentNote };
              this.appPathStack.pushPathByName('EditCategory', params);
              this.noteDialogController.close();
            });

            ListItem() {
              Column() {
                Divider()
                  .color('rgba(0,0,0,0.20)');
                Row({ space: 8 }) {
                  Image($r('app.media.delete_category'))
                    .width(16);

                  Text($r('app.string.delete'))
                    .fontSize(16)
                    .fontColor('#E84026');
                }
                .width(CommonConstants.FULL_PERCENT)
                .height(50);
              };
            }
            .backgroundColor(Color.White)
            .padding({
              left: 12,
              right: 12,
            })
            .onClick(() => {
              this.deleteNoteController.open();
            });

          }
          .borderRadius(8)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.None);
        }
        .height(200);
      }
      .height(320)
      .margin({
        left: '4%',
        right: '4%',
      });
    }
    .backgroundColor('#F1F3F5');
  }

  @Builder
  deleteDialogContent() {
    Column() {
      Row() {
        Text($r('app.string.confirm_delete_diary'));
      };
    };
  }

  @Builder
  sortDialog() {
    Column() {
      Text($r('app.string.sort_order'))
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontFamily('HarmonyOS Sans SC')
        .width(CommonConstants.FULL_PERCENT)
        .textAlign(TextAlign.Start)
        .margin({ top: 24, bottom: 24, left: 24 });

      Column({ space: 10 }) {
        // 按创建时间选项
        Row() {
          Text($r('app.string.sort_by_create_time'))
            .fontSize(16);
          Blank();
          Radio({ value: 'createTime', group: 'sortGroup' })
            .checked(this.sortBy === 'createTime')
            .onChange((isChecked: boolean) => {
              if (isChecked === true) {
                this.onSortConfirm('createTime');
              }
            });
        }
        .width(CommonConstants.FULL_PERCENT)
        .padding({ top: 10, left: 12, right: 14 })
        .onClick(() => this.onSortConfirm('createTime'));

        Divider()
          .width('95%');

        Row() {
          Text($r('app.string.sort_by_update_time'))
            .fontSize(16);
          Blank();
          Radio({ value: 'updateTime', group: 'sortGroup' })
            .checked(this.sortBy === 'updateTime')
            .onChange((isChecked: boolean) => {
              if (isChecked === true) {
                this.onSortConfirm('updateTime');
              }
            });
        }
        .width(CommonConstants.FULL_PERCENT)
        .padding({ left: 12, right: 14, bottom: 10 })
        .onClick(() => this.onSortConfirm('updateTime'));
      }
      .backgroundColor(Color.White)
      .margin({
        left: 16,
        right: 16,
        bottom: 50,
      })
      .borderRadius(8);

    }
    .backgroundColor('#F1F3F5')
    .width(CommonConstants.FULL_PERCENT);
  }
}