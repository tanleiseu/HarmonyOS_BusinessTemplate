import { Category, MinePageCommonService } from './Model';

export function initCategoryList(): Array<Category>{
  let categoryList: Array<Category> = [];
  categoryList.push(new Category('全部笔记', 0, '-1',));
  return categoryList;
}


export const COMMON_SERVICE: Array<MinePageCommonService> = [
  {
    icon: 'app.media.trash',
    label: '回收站',
    nextPage: 'Trash'
  },
  {
    icon: 'app.media.setting',
    label: '设置',
    nextPage: 'Setting'
  }
]