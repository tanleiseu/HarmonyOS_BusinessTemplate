/**
 * 分类
 */
@ObservedV2
export class Category {
  /**
   * id
   */
  @Trace id: string = '';
  /**
   * 分类名称
   */
  @Trace name: string = '';
  /**
   * 数量
   */
  @Trace totalCount: number = 0;

  constructor(name: string, totalCount: number, id?: string,) {
    this.id = id? id : new Date().getTime().toString();
    this.name = name;
    this.totalCount = totalCount;
  }
}

/**
 * 笔记
 */
export interface Notes {
  /**
   * id
   */
  id: string;
  /**
   * 标题
   */
  title: string;
  /**
   * 分类
   */
  categoryId: string;
  /**
   * 内容
   */
  content: string;
  /**
   * 创建时间
   */
  createTime: string;
  /**
   * 修改时间
   */
  updateTime: string;
  /**
   * 内容描述
   */
  description: string;
}

export interface User {

}


/**
 * 我的页面-各种服务信息
 */
export interface MinePageCommonService{
  /**
   * 图标
   */
  icon: string,
  /**
   * 标签名称
   */
  label: string,
  /**
   * 跳转到下一页
   */
  nextPage: string
}