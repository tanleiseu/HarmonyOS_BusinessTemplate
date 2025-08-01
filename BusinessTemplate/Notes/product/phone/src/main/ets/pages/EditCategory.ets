import { Category, CategoryService, Note, NoteService } from '@ohos_agcit/notes_datasource';
import { JSON } from '@kit.ArkTS';
import { CommonConstants, StringUtil } from '@ohos_agcit/notes_utils';
import { promptAction } from '@kit.ArkUI';
import { Callback } from '@kit.BasicServicesKit';

@Builder
export function EditCategoryBuilder() {
  EditCategory();
}


@ComponentV2
export struct EditCategory {
  @Consumer('appPathStack') appPathStack: NavPathStack = new NavPathStack();
  categoryService: CategoryService = CategoryService.instance;
  noteService: NoteService = NoteService.instance;
  @Local categoryList: Array<Category> = [];
  @Local categoryId: string = '';
  @Local isEditCategoryName: boolean = true;
  @Local isEditCategory: boolean = true;
  @Local currentCategory: Category = this.categoryService.getFirstCategory();;
  @Local currentNote: Note | undefined;
  editDialogController: CustomDialogController = new CustomDialogController({
    builder: () => {
      this.editCategoryDialog(
        this.isEditCategoryName,
        this.categoryService.getCategoryById(this.categoryId),
        '',
        () => {
          this.editDialogController.close();
        },
      );
    },
    alignment: DialogAlignment.Center,
    cornerRadius: 16,
  });
  deleteDialogController: CustomDialogController = new CustomDialogController({
    builder: () => {
      this.deleteCategoryDialog();
    },
    alignment: DialogAlignment.Center,
    cornerRadius: 16,
    width: '80%',
  });


   selectFontColor(item: Category){
     if (this.isEditCategory) {
         return this.currentCategory.id === item.id ? 'rgba(0,0,0,0.90)' : 'rgba(0,0,0,0.60)';
     }
    return this.currentNote?.categoryId === item.id ? 'rgba(0,0,0,0.40)' : 'rgba(0,0,0,0.60)';
  }

  selectFontWeight(item: Category){
    if (this.isEditCategory) {
      return this.currentCategory.id === item.id ? FontWeight.Medium : FontWeight.Regular;
    }
    return this.currentNote?.categoryId === item.id ? FontWeight.Medium : FontWeight.Regular;
  }

  build() {
    NavDestination() {
      Scroll(){
        Column({space: 15}) {
          List({ space: 12 }) {
            ForEach(this.categoryList, (item: Category, index: number) => {
              ListItem() {
                Row() {
                  Text(item.name)
                    .fontSize(18)
                    .fontColor(this.selectFontColor(item))
                    .fontWeight(this.selectFontColor(item))
                  Blank();

                  Row({ space: 18 }) {
                    Text(String(item.totalCount))
                      .fontSize(18)
                      .fontWeight(FontWeight.Medium);
                    if (index !== 0 && this.isEditCategory) {
                      Image($r('app.media.edit_category'))
                        .width(24)
                        .height(24)
                        .onClick(() => {
                          this.isEditCategoryName = true;
                          this.categoryId = item.id;
                          this.editDialogController.open();
                        });

                      Image($r('app.media.delete_category'))
                        .width(24)
                        .height(24)
                        .onClick(() => {
                          this.categoryId = item.id;
                          this.deleteDialogController.open();
                        });
                    }
                  };
                }
                .borderRadius(16)
                .backgroundColor(!this.isEditCategory && this.currentNote?.categoryId === item.id ?
                  'rgba(255,255,255,0.20)' : Color.White)
                .height(48)
                .width(CommonConstants.FULL_PERCENT)
                .padding({
                  left: 12,
                  right: 12,
                })
              }
              .onClick(() => {
                // 非编辑模式
                if (!this.isEditCategory && this.currentNote) {
                  // 移动分类
                  this.categoryService.moveCategory(this.currentNote.categoryId, item.id);
                  this.currentNote.categoryId = item.id;
                  this.noteService.updateNote(this.currentNote);
                  this.appPathStack.pop();
                }
              })
            }, (item: Category) => item.id);
          }

          Row({ space: 8 }) {
            Image($r('app.media.create_category'))
              .width(24)
              .height(24)
            Text('新建分类')
              .fontSize(18);
          }
          .justifyContent(FlexAlign.Center)
          .backgroundColor(Color.White)
          .borderRadius(16)
          .height(48)
          .width(CommonConstants.FULL_PERCENT)
          .onClick(() => {
            this.isEditCategoryName = false;
            this.editDialogController.open();
          });
        }
        .width(CommonConstants.FULL_PERCENT)
        .padding({
          top: 10,
          right: 16,
          left: 16,
          bottom: 50
        });
      }
      .scrollBar(BarState.Off)
    }
    .onReady((cxt: NavDestinationContext) => {
      this.categoryList = this.categoryService.getCategoryList();
      let params = cxt.pathInfo.param as Record<string, Object>;
      this.isEditCategory = params.isEditCategory as boolean;
      this.currentCategory = params.currentCategory as Category;
      if (!this.isEditCategory) {
        this.currentNote = params.currentNote as  Note;
      }
    })
    .title('笔记分类')
    .onBackPressed(() => {
      this.appPathStack.pop();
      return true;
    })
    .linearGradient({
      angle: 180,
      colors: [['#FFF0D4', 0], ['#E4E1D1', 0.08],['#F1F3F5', 0.2],['#F1F3F5', 1]],
    })
    .backgroundColor('#FFF0D4');
  }

  @Builder
  editCategoryDialog(isEdit: boolean, category: Category | undefined, newName: string,
    cancelClick: Callback<void>) {
    Column() {
      Text(isEdit ? '重命名' : '新建分类')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .padding({
          top: 11,
          bottom: 12,
        });

      TextInput({
        text: isEdit ? category?.name : '',
      })
        .height(48)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .borderRadius(16)
        .margin({
          left: '3%',
          right: '3%',
        })
        .onChange((value) => {
          newName = value;
        });

      Row() {
        Row() {
          Text('取消')
            .editCategoryButtonStyle();
        }
        .justifyContent(FlexAlign.Center)
        .height(70)
        .width('50%')
        .onClick(() => {
          cancelClick();
        });

        Row() {
          Text('确定')
            .editCategoryButtonStyle();
        }
        .justifyContent(FlexAlign.Center)
        .height(70)
        .width('50%')
        .onClick(() => {
          if (isEdit) {
            if (category) {
              category.name = newName;
            }
            cancelClick();
            return;
          }
          if (StringUtil.isBlank(newName)) {
            promptAction.showToast({
              message: '分类名称为空, 请重新填写 ~',
              duration: 1500,
              alignment: Alignment.Center,
            });
            return;
          }
          if (this.categoryService.addCategory(new Category(newName, 0))) {
            cancelClick();
          }

        });
      };
    }
    .height(158);
  }

  @Builder
  deleteCategoryDialog() {
    Column({ space: 30 }) {
      Row() {
        Text('仅删除分类')
          .fontSize(16)
          .onClick(() => {
            this.noteService.moveNotesCategory(this.categoryId);
            this.categoryService.deleteCategoryById(this.categoryId);

            promptAction.showToast({
              message: '删除成功 ~',
              alignment: Alignment.Center,
              duration: 1500,
            });
            this.deleteDialogController.close();
          });
      }
      .justifyContent(FlexAlign.Center)
      .width(CommonConstants.FULL_PERCENT)
      .height(20);

      Row() {
        Text('删除分类和笔记')
          .fontSize(16)
          .fontColor(Color.Red)
          .onClick(() => {
            // 删除笔记
            let notes = this.noteService.getNoteList(this.categoryId);
            notes.forEach((item) => {
              this.noteService.deleteNote(item.id);
            });
            // 删除分类
            this.categoryService.deleteCategoryById(this.categoryId);
            promptAction.showToast({
              message: '删除成功 ~',
              alignment: Alignment.Center,
              duration: 1500,
            });
            this.deleteDialogController.close();
          });
      }
      .justifyContent(FlexAlign.Center)
      .width(CommonConstants.FULL_PERCENT)
      .height(20);

      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor(Color.Grey)
          .onClick(() => {
            this.deleteDialogController.close();
          });
      }
      .justifyContent(FlexAlign.Center)
      .width(CommonConstants.FULL_PERCENT)
      .height(20);
    }
    .padding({
      top: 30,
      bottom: 30,
    });
  }
}

@Extend(Text)
function editCategoryButtonStyle() {
  .fontSize(16)
  .fontColor('#0A59F7')
  .fontWeight(FontWeight.Medium);
}
