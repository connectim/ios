//
//  CellItem.h
//  HashNest
//
//  Created by MoHuilin on 16/3/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^Operation)();
typedef void(^OperationWithUserInfo)(id userInfo);

typedef NS_ENUM(NSInteger ,CellItemType) {
    CellItemTypeNone = 0,
    CellItemTypeArrow,
    CellItemTypeSwitch,
    CellItemTypeLabel,
    CellItemTypeTextFieldWithLabel,
    CellItemTypeTextField,
    CellItemTypeValue1,
    CellItemTypeImageValue1,
    CellItemTypeButtonCell,
    CellItemTypeSubtitleNoArrow,
    CellItemTypeRoundTextField,
    CellItemTypeTextFieldWithButton,
    CellItemTypeCommonLbale,
    CellItemTypeGroupVerify,

    /**
     *  特殊的cell
     */
    
    CellItemTypeGroupMemberCell,
    CellItemTypeMyInfoCell,
    CellItemTypeLogoutCell,
    CellItemTypeSetAvatarCell,
    
    CellItemTypeUserDetailCell,
    CellItemTypeUserSetAliasCell,
    CellItemTypeContactSyscCell,


    
    
};

@interface CellItem : NSObject

@property (nonatomic) CellItemType type;

@property (nonatomic ,copy) NSString *icon;

@property (nonatomic ,copy) NSString *title;

@property (nonatomic ,copy) NSString *subTitle;

@property (nonatomic ,copy) Operation operation; //点击操作

@property (nonatomic ,copy) OperationWithUserInfo operationWithInfo; //

@property (nonatomic ,copy) Operation innerOperation; //cell内部事件的某些回调

@property (nonatomic ,strong) NSArray *array; //数组

@property (nonatomic ,strong) id userInfo;

@property (nonatomic ,assign) BOOL isSelect; //是否是选中

// UILabel 属性
@property (nonatomic, strong) UIColor *titleColor;

@property (nonatomic) NSTextAlignment textAlignment;

//UISwitch 属性
@property (nonatomic) BOOL switchIsOn;

//UITextField 属性
@property (nonatomic ,copy) NSString *placeholder;
@property (nonatomic) BOOL securty;

//buttonCell
@property (nonatomic ,strong) UIColor *buttonBackgroudColor;


@property (nonatomic ,assign) int tag;

/**
 *  便利构造器
 *
 *  @param title     cell的标题
 *  @param type      类型
 *  @param operation 点击cell后的操作Block
 *
 *  @return cell实例
 */
+ (instancetype)itemWithTitle:(NSString *)title type:(CellItemType)type operation:(Operation)operation;

/**
 *  便利构造器
 *
 *  @param icon      cell icon
 *  @param title     cell的标题
 *  @param type      类型
 *  @param operation 点击cell后的操作Block
 *
 *  @return cell实例
 */
+ (instancetype)itemWithIcon:(NSString *)icon title:(NSString *)title type:(CellItemType)type operation:(Operation)operation;


+ (instancetype)itemWithTitle:(NSString *)title subTitle:(NSString *)subTitle type:(CellItemType)type operation:(Operation)operation;
@end
