import { SecretLockSwitch } from 'secretlock';

@Builder
export function SecretSettingBuilder() {
  SecretSetting();
}

@ComponentV2
export struct SecretSetting {
  @Consumer('appPathStack') appPathStack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      SecretLockSwitch({
        appPathStack: this.appPathStack
      });
    }
    .title('保密设置');
  }
}
