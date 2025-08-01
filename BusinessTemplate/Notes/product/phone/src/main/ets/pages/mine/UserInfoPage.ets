import { AccountUtil, CommonConstants } from '@ohos_agcit/notes_utils';
import { rightArrow } from '../../components/RightArrow';
import { CustomContentDialog } from '@kit.ArkUI';
import { FunctionalButton, functionalButtonComponentManager } from '@kit.ScenarioFusionKit';


@Builder
export function UserInfoBuilder() {
  UserInfoPage();
}

@ComponentV2
export struct UserInfoPage {
  @Consumer('appPathStack') appPathStack: NavPathStack = new NavPathStack();
  topRectHeight: number = AppStorage.get('topRectHeight') || 0;

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Row() {
          Text($r('app.string.avatar'))
            .fontSize(16)
            .layoutWeight(1)
            .lineHeight(22)
            .padding({
              left: 12,
            });

          FunctionalButton({
            params: {
              // OpenType.CHOOSE_AVATAR indicates that the button is used to select an avatar.
              openType: functionalButtonComponentManager.OpenType.CHOOSE_AVATAR,
              label: '',
              // Adjust the button style.
              styleOption: {
                styleConfig: new functionalButtonComponentManager.ButtonConfig()
                  .type(ButtonType.Circle)
                  .backgroundImage(AccountUtil.getUserInfo().avatar)
                  .backgroundImageSize(ImageSize.Cover)
                  .borderRadius(20)
                  .width(45)
                  .height(45)
                  .backgroundColor(Color.Transparent)
                  .borderWidth(0)
                  .type(ButtonType.Circle)
                  .backgroundImagePosition(Alignment.Center),
              },
            },
            // When OpenType is set to CHOOSE_AVATAR, the callback must be onChooseAvatar.
            controller: new functionalButtonComponentManager.FunctionalButtonController().onChooseAvatar((err,
              data) => {
              if (err) {
                // Error processing.
                return;
              }
              // Success processing.
              // this.avatar = data.avatarUri!;
              AccountUtil.getUserInfo().avatar = data.avatarUri!;
            }),
          })
            .margin({
              right: 6,
            });


          Row() {
            rightArrow();
          }
          .margin({
            right: 8,
          });
        }
        .backgroundColor($r('sys.color.white'))
        .height(56)
        .borderRadius(16)
        .margin({ top: 16 });

        Row() {
          Text($r('app.string.nickName'))
            .fontSize(16)
            .layoutWeight(1)
            .lineHeight(22)
            .padding({ left: 12 });
          TextInput({
            text: AccountUtil.getUserInfo().nickname,
          })
            .textAlign(TextAlign.End)
            .fontSize(14)
            .layoutWeight(1)
            .backgroundColor(Color.White)
            .selectionMenuHidden(true)
            .padding({ right: 6 })
            .onChange((value) => {
              AccountUtil.getUserInfo().nickname = value;
            });
          Row() {
            rightArrow();
          }
          .margin({
            right: 8,
          });
        }
        .backgroundColor($r('sys.color.white'))
        .height(56)
        .borderRadius(16);
      }
      .backgroundColor('#F1F3F5')
      .height(CommonConstants.FULL_PERCENT)
      .padding({
        left: 16,
        right: 16,
      });
    }
    .title('个人信息')
    .margin({ top: px2vp(this.topRectHeight) })
    .onBackPressed(() => {
      this.appPathStack.pop();
      return true;
    });
  }
}