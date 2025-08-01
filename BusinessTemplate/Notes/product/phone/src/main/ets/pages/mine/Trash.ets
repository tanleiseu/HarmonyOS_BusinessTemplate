import { Note, NoteService } from '@ohos_agcit/notes_datasource';
import { CommonConstants, DateConstants, DateUtil } from '@ohos_agcit/notes_utils';
import { CustomContentDialog } from '@kit.ArkUI';

@Builder
export function TrashBuilder() {
  Trash();
}

@ComponentV2
export struct Trash {
  @Consumer('appPathStack') appPathStack: NavPathStack = new NavPathStack();
  noteService: NoteService = NoteService.instance;
  @Local noteList: Note[] = this.noteService.getDumpstersData();
  private currentNote: Note | undefined = undefined;
  // 彻底删除对话框控制器
  private searchController: SearchController = new SearchController();
  @Local searchKeyword: string = ''; // 搜索关键词
  @Local isSearching: boolean = false; // 是否正在搜索状态

  deleteDialogController: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: '彻底删除',
      contentBuilder: () => {
        this.confirmDeleteContent();
      },
      buttons: [
        {
          value: '取消',
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            this.deleteDialogController.close();
          },
        },
        {
          value: '确定',
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            if (this.currentNote) {
              this.noteService.deletePermanently(this.currentNote.id);
              this.noteList = this.noteService.getDumpstersData();
            }
            this.deleteDialogController.close();
          },
        },
      ],
    }),
    alignment: DialogAlignment.Center,
  });
  // 恢复对话框控制器
  recoverDialogController: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: '恢复笔记',
      contentBuilder: () => {
        this.confirmRecoveryContent();
      },
      buttons: [
        {
          value: '取消',
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            this.recoverDialogController.close();
          },
        },
        {
          value: '确定',
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            if (this.currentNote) {
              this.noteService.recoverNote(this.currentNote.id);
              this.noteList = this.noteService.getDumpstersData();
            }
            this.recoverDialogController.close();
          },
        },
      ],

    }),
    alignment: DialogAlignment.Center,
  });

  aboutToAppear(): void {
    this.noteList = this.noteService.getDumpstersData();
  }

  // 添加搜索方法
  onSearch(keyword: string) {
    this.searchKeyword = keyword.trim();
    this.isSearching = this.searchKeyword.length > 0;
    this.getSortedNoteList(); // 统一调用获取列表方法
  }
  // 获取排序后的笔记列表
  getSortedNoteList() {
    this.noteList = this.isSearching
      ? this.noteService.searchInDumpsters(this.searchKeyword) || []
      : this.noteService.getDumpstersData();
  }

  build() {
    NavDestination() {
      Column() {
        Column() {
          // 搜索框
          Search({
            placeholder: '请输入你想搜索的笔记',
            controller: this.searchController
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
          this.showNoteList();

        }
      }
      .padding({
        left: 16,
        right: 16,
      })
      .width(CommonConstants.FULL_PERCENT)
      .height(CommonConstants.FULL_PERCENT);
    }
    .title('回收站')
    .backgroundColor('#F1F3F5')
  }

  @Builder
  showNoteList() {
    if (this.isSearching && this.noteList.length === 0) {
      // 搜索无结果提示
      Column() {
        Text('没有找到匹配的笔记')
          .fontSize(16)
          .fontColor(Color.Gray);
      }
      .width(CommonConstants.FULL_PERCENT)
      .height(100)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }else {
      List({ space: 12 }) {
        ForEach(this.noteList, (item: Note) => {
          ListItem() {
            Column({ space: 12 }) {
              Text(item.title)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .padding({
                  top: 12,
                });

              Text(item.description)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .fontSize(14)
                .fontWeight(FontWeight.Regular);

              Row() {
                Text(DateUtil.getFormatDateStr(item.createTime, DateConstants.DATE_FORMAT4))
                  .fontSize(12);
                Blank();
                // 恢复按钮
                Image($r('app.media.icon_recover'))
                  .width(24)
                  .margin({ right: 12 })
                  .onClick(() => {
                    this.currentNote = item;
                    this.recoverDialogController.open();
                  });

                // 删除按钮
                Image($r('app.media.icon_delete'))
                  .width(24)
                  .onClick(() => {
                    this.currentNote = item;
                    this.deleteDialogController.open();
                  });
              }
              .width(CommonConstants.FULL_PERCENT);
            }
            .alignItems(HorizontalAlign.Start)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .width(CommonConstants.FULL_PERCENT)
            .height(105)
            .padding({
              left: 12,
              right: 12,
            });
          };
        }, (item: Note) => item.id);
      }
      .scrollBar(BarState.Off);
    }


  }

  @Builder
  confirmDeleteContent() {
    Column() {
      Row() {
        Text('请确认是否彻底删除此笔记？');
      };
    }
    .width(CommonConstants.FULL_PERCENT)
    .borderRadius(16)
    .margin({
      left: '4%',
      right: '4%'
    })
  }

  @Builder
  confirmRecoveryContent() {
    Column() {
      Row() {
        Text('请确认是否恢复此笔记至原分类？');
      };
    }
    .width(CommonConstants.FULL_PERCENT)
    .borderRadius(16)
    .margin({
      left: '4%',
      right: '4%'
    })
  }
}