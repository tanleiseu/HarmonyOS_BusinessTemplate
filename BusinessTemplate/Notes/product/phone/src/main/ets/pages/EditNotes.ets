import { BussController, RichEditorArea } from 'richeditor';
import { common } from '@kit.AbilityKit';
import { KeyboardAvoidMode, promptAction } from '@kit.ArkUI';
import { CommonConstants } from '@ohos_agcit/notes_utils';
import { Category, Note, NoteService } from '@ohos_agcit/notes_datasource';

@Builder
export function EditNotesBuilder() {
  EditNotes();
}

@ComponentV2
struct EditNotes {
  context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private richEditorController: RichEditorController = new RichEditorController();
  private bussController: BussController = new BussController();
  @Consumer('appPathStack') appPathStack: NavPathStack = new NavPathStack();
  noteService: NoteService = NoteService.instance;
  @Local currentNote: Note = new Note('');
  @Local noteTitle: string = '';
  @Local hasEdit: boolean = false;
  @Local isEditNote: boolean = false;

  aboutToAppear(): void {
    // 启用压缩模式避让软键盘
    this.context.windowStage.getMainWindowSync()
      .getUIContext()
      .setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE_WITH_CARET);
  }

  aboutToDisappear(): void {
    // 还原默认上抬模式
    this.context.windowStage.getMainWindowSync()
      .getUIContext()
      .setKeyboardAvoidMode(KeyboardAvoidMode.OFFSET);
  }

  @Builder
  toolBar() {
    Row() {
      Image($r('app.media.share'))
        .height(32)
        .width(32)
        .margin({
          right: 12,
        })
        .onClick(() => {
          this.bussController.shareData();
        });
      Image($r('app.media.save'))
        .height(32)
        .width(32)
        .onClick(() => {
          this.saveNote();
        });
    }
    .height(CommonConstants.FULL_PERCENT)
    .width(76)
    .justifyContent(FlexAlign.Center)
    .margin({
      right: 16,
    });
  }

  /**
   * 保存笔记
   */
  saveNote() {
    let content = JSON.stringify(this.richEditorController.getSpans());
    if (this.isEditNote) {
      this.currentNote.updateContent(content, this.noteTitle);
    } else {
      if ((content === undefined && this.noteTitle === undefined) || (content === '[]' && this.noteTitle === '')) {
        promptAction.showToast({
          message: '还没有输入笔记内容哦 ~',
          alignment: Alignment.Center,
          duration: 1500,
        });
        return;
      }
      this.currentNote.content = content;
      this.currentNote.title = this.noteTitle;
      this.currentNote.getDescription();
      this.noteService.addNote(this.currentNote);
    }
    promptAction.showToast({
      message: '保存成功',
      alignment: Alignment.Center,
      duration: 1500,
    });
    this.isEditNote = true;
    this.hasEdit = false;
  }

  sureDialog: CustomDialogController = new CustomDialogController({
    builder: () => {
      this.makeSureDialog();
    },
    alignment: DialogAlignment.Center,
    cornerRadius: {
      topLeft: 16,
      topRight: 16,
      bottomLeft: 16,
      bottomRight: 16,
    },
    width: '90%',
  });

  @Builder
  makeSureDialog() {
    Column({ space: 24 }) {
      Text($r('app.string.save_tip'))
        .fontColor('rgba(0,0,0,0.9)')
        .fontSize(14)
        .width(CommonConstants.FULL_PERCENT)
        .textAlign(TextAlign.Center);
      Text($r('app.string.save'))
        .fontColor('#FFAA00')
        .fontSize(14)
        .width(CommonConstants.FULL_PERCENT)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.saveNote();
          this.appPathStack.pop();
          this.sureDialog.close();
        });
      Text($r('app.string.give_up'))
        .fontColor('rgba(0,0,0,0.9)')
        .fontSize(14)
        .width(CommonConstants.FULL_PERCENT)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.appPathStack.pop();
          this.sureDialog.close();
        });
      Text($r('app.string.cancel'))
        .fontColor('rgba(0,0,0,0.4)')
        .fontSize(14)
        .width(CommonConstants.FULL_PERCENT)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.sureDialog.close();
        });
    }
    .alignItems(HorizontalAlign.Center)
    .padding({
      top: 24,
      bottom: 24,
    });
  }

  build() {
    NavDestination() {
      Column() {
        RichEditorArea({
          richEditorController: this.richEditorController,
          bussController: this.bussController,
          noteContent: this.currentNote.content,
          onEditorChange: (hasChange: boolean) => {
            this.hasEdit = hasChange;
          },
          noteTitle: this.currentNote.title,
          titleChange: (title: string) => {
            this.noteTitle = title;
          },
        })
          .layoutWeight(1)
      }
      .height(CommonConstants.FULL_PERCENT)
      .width(CommonConstants.FULL_PERCENT);
    }
    .title(this.isEditNote ? $r('app.string.editor') : $r('app.string.create_note'))
    .menus(this.toolBar())
    .onReady((cxt: NavDestinationContext) => {
      let params = cxt.pathInfo.param as Record<string, Object>;
      let noteId = params.noteId as string;
      if (noteId === '') {
        this.isEditNote = false;
      } else {
        this.isEditNote = true;
        let note = this.noteService.getNoteById(noteId);
        if (note) {
          this.currentNote = note;
        }
      }
      this.currentNote.categoryId = (params.currentCategory as Category).id;
    })
    .linearGradient({
      angle: 180,
      colors: [['#FFF0D4', 0], ['#E4E1D1', 0.08], ['#F1F3F5', 0.2], ['#F1F3F5', 1]],
    })
    .onBackPressed(() => {
      if (this.hasEdit) {
        this.sureDialog.open();
        return true;
      }
      this.hasEdit = false;
      return false;
    });
  }
}