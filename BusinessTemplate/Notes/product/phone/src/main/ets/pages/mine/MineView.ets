import { COMMON_SERVICE, MinePageCommonService } from '@ohos_agcit/notes_datasource';
import { showToast, AccountUtil, StringUtil, CommonConstants } from '@ohos_agcit/notes_utils';

@Builder
export function MineViewBuilder() {
  MineView();
}

class DividerTmp {
  strokeWidth: Length = 1
  startMargin: Length = 60
  endMargin: Length = 10
  color: ResourceColor = '#ffe9f0f0'

  constructor(strokeWidth: Length, startMargin: Length, endMargin: Length, color: ResourceColor) {
    this.strokeWidth = strokeWidth
    this.startMargin = startMargin
    this.endMargin = endMargin
    this.color = color
  }
}

@ComponentV2
export struct MineView {
  logTag: string = 'PrepareLoginPage';
  domainId: number = 0x0000;
  topRectHeight: number = AppStorage.get('topRectHeight') || 0;
  scroller: Scroller = new Scroller();
  @Consumer('appPathStack') appPathStack: NavPathStack = new NavPathStack();
  @Local egDivider: DividerTmp = new DividerTmp(1, 40, 0, '#ffe9f0f0');

  // 跳转登录页面
  private jumpLoginPage(quickLoginAnonymousPhone: string | undefined) {
    if (quickLoginAnonymousPhone) {
      const params: Record<string, Object> = { 'anonymousPhone': quickLoginAnonymousPhone };
      this.appPathStack.pushPathByName('QuickLoginPage', params, true);
    } else {
      const hint: string = getContext().resourceManager.getStringSync($r('app.string.get_mobile_number_error'));
      showToast(hint);
    }
  }

  // 显示开发中提示
  private showDevelopingToast() {
    showToast('此功能开发中');
  }

  // 构建功能模块项
  @Builder
  FunctionItem(commonService: MinePageCommonService) {
    Row() {
      Image($r(commonService.icon))
        .width(24)
        .height(24)
        .margin({ left: 12 })
      Text(commonService.label)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ left: 16 })
      Blank()
      Image($r('app.media.ic_right_arrow_lined'))
        .width(7)
        .height(14)
        .fillColor('rgba(0,0,0,0.2)')
        .margin({ right: 12 })
    }
    .width(CommonConstants.FULL_PERCENT)
    .height(46)
    .justifyContent(FlexAlign.Start)
    .onClick(() => {
      if (StringUtil.isEmpty(commonService.nextPage)) {
        this.showDevelopingToast();
        return;
      }
      this.appPathStack.pushPathByName(commonService.nextPage, undefined);
    })
  }

  build() {
    NavDestination() {
      Scroll(this.scroller) {
        Column() {
          // 用户信息模块
          Row() {
            Image(AccountUtil.getUserInfo().avatar)
              .width(56)
              .height(56)
              .borderRadius(28)
              .margin({ left: 12 })

            Text(AccountUtil.getUserInfo().nickname)
              .fontSize(18)
              .fontFamily('鸿蒙黑体')
              .fontWeight(FontWeight.Medium)
              .margin({ left: 12 })
          }
          .width(CommonConstants.FULL_PERCENT)
          .height(72)
          .backgroundColor(Color.White)
          .borderRadius(16)
          .margin({ top: 5 })
          .onClick(async () => {
            if (AccountUtil.getAccountInfo().idToken === '') {
              await AccountUtil.quickLogin();
              this.jumpLoginPage(AccountUtil.getAccountInfo().quickLoginAnonymousPhone);
            } else {
              this.appPathStack.pushPathByName('UserInfoPage', true);
            }
          });

          List(){
            ForEach(COMMON_SERVICE, (item: MinePageCommonService) => {
              ListItem(){
                Column() {
                  this.FunctionItem(item)
                }
                .width(CommonConstants.FULL_PERCENT)
                .height(46)
                .backgroundColor(Color.White)
                .borderRadius(16)
                .margin({ top: 12 })
              }
            }, (item: MinePageCommonService) => item.label)
          }
        }
        .height(CommonConstants.FULL_PERCENT)
        .padding({
          left:16,
          right:16
        })
      }
      .scrollable(ScrollDirection.Vertical)
      .edgeEffect(EdgeEffect.Spring)
    }
    .title('我的')
    .padding({
      top: px2vp(this.topRectHeight) + 10,
    })
    .width(CommonConstants.FULL_PERCENT)
    .linearGradient({
      angle: 180,
      colors: [['#FFF0D4', 0], ['#E4E1D1', 0.08],['#F1F3F5', 0.2],['#F1F3F5', 1]],
    })
  }
}