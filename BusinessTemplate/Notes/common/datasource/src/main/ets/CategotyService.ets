import { initCategoryList } from './Data';
import { Category } from './Model';
import { promptAction } from '@kit.ArkUI';

@ObservedV2
export class CategoryService {
  private static _instance: CategoryService;

  public static get instance() {
    if (!CategoryService._instance) {
      CategoryService._instance = new CategoryService();
    }
    return CategoryService._instance;
  }

  /**
   * 初始化分类数据
   */
  @Trace private categoryList: Array<Category> = initCategoryList();

  /**
   * 获取所有分类列表
   * @returns 所有分类列表
   */
  getCategoryList(): Array<Category> {
    return this.categoryList;
  }

  /**
   * 获取所有分类列表
   * @returns 所有分类列表
   */
  getCategoryById(id: string): Category | undefined {
    return this.categoryList.find((item) => item.id === id);
  }

  getFirstCategory(): Category {
    return this.categoryList[0];
  }
  /**
   * 增加分类
   * @param category 待新增的分类
   */
  addCategory(category: Category): boolean {
    let sameNameCategory = this.categoryList.find((item) => item.name === category.name);
    if (sameNameCategory) {
      promptAction.showToast({
        message: '已存在相同名称的分类，请重新创建 ~',
        duration: 1500,
        alignment: Alignment.Center
      })
      return false;
    }
    this.categoryList.push(category);
    return true;
  }

  /**
   * 删除分类id指定位置的分类
   * @param index 索引位置
   */
  deleteCategoryById(categoryId: string): void {
    let index = this.categoryList.findIndex((item) => item.id === categoryId);
    this.categoryList.splice(index, 1);
  }

  /**
   * 移动分类
   * @param originalCategoryId 源分类Id
   * @param targetCategoryId 目标分类Id
   */
  moveCategory(originalCategoryId: string, targetCategoryId: string){
    if (originalCategoryId === targetCategoryId) {
      return;
    }

    if (originalCategoryId !== '-1') {
      let originalCategory = this.getCategoryById(originalCategoryId);
      if (originalCategory) {
        originalCategory.totalCount--;
      }
    }

    let targetCategory = this.getCategoryById(targetCategoryId);
    if (targetCategory) {
      if (targetCategory.id !== '-1') {
        targetCategory.totalCount++;
      }
    }
  }

}