//
//  BaseDB.h
//  Connect
//
//  Created by MoHuilin on 16/7/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>
#import "MMGlobal.h"
#import "DBTableNameFormart.h"
#import "KeyHandle.h"
#import "NSString+Hash.h"
#import "NSDictionary+LMSafety.h"

@interface BaseDB : NSObject

/**
 * execute sql
 * @param sql
 * @return
 */
- (BOOL)executeSql:(NSString *)sql;

/**
 * batch inseart or update
 * @param tableName
 * @param fields
 * @param batchValues
 * @return
 */
- (BOOL)executeUpdataOrInsertWithTable:(NSString *)tableName fields:(NSArray *)fields batchValues:(NSArray *)batchValues;

/**
 * execute query
 * @param sql
 * @return
 */
- (NSArray *)queryWithSql:(NSString *)sql;

/**
 * get data from table
 * @param tableName
 * @param conditions
 * @param fields
 * @return
 */
- (NSArray *)getDatasFromTableName:(NSString *)tableName conditions:(NSDictionary *)conditions fields:(NSArray *)fields;

/**
 * get all data
 * @param tableName
 * @param fields
 * @return
 */
- (NSArray *)getAllDatasFromTableName:(NSString *)tableName fields:(NSArray *)fields;

/**
 * get count from table
 * @param tableName
 * @param conditions
 * @param symbol
 * @return
 */
- (long long int)getCountFromCurrentDBWithTableName:(NSString *)tableName condition:(NSDictionary *)conditions symbol:(int)symbol;

/**
 * get data from table
 * @param tableName
 * @param conditions
 * @param fields
 * @param orderby
 * @param sort
 * @return
 */
- (NSArray *)getDatasFromTableName:(NSString *)tableName conditions:(NSDictionary *)conditions fields:(NSArray *)fields orderBy:(NSString *)orderby sortWay:(int)sort;

/**
 * getDatasFrom Table
 * @param tableName
 * @param fields
 * @param conditions
 * @param limit
 * @param orderby
 * @param sort
 * @return
 */
- (NSArray *)getDatasFromTableName:(NSString *)tableName fields:(NSArray *)fields conditions:(NSDictionary *)conditions limit:(int)limit orderBy:(NSString *)orderby sortWay:(int)sort;

/**
 * save data to db
 * @param tableName
 * @param fieldsValues
 * @return
 */
- (BOOL)saveToCuttrentDBTableName:(NSString *)tableName fieldsValues:(NSDictionary *)fieldsValues;

/**
 * updade data
 * @param tableName
 * @param fieldsValues
 * @param conditions
 * @return
 */
- (BOOL)updateTableName:(NSString *)tableName fieldsValues:(NSDictionary *)fieldsValues conditions:(NSDictionary *)conditions;


/**
 * detete data
 * @param tableName
 * @param conditions
 * @return
 */
- (BOOL)deleteTableName:(NSString *)tableName conditions:(NSDictionary *)conditions;

/**
 * drop db table
 * @param tableName
 * @return
 */
- (BOOL)dropTableWithTableName:(NSString *)tableName;

/**
 * batch insert or repalce data
 * @param tableName
 * @param fields
 * @param batchValues
 * @return
 */
- (BOOL)batchInsertTableName:(NSString *)tableName fields:(NSArray *)fields batchValues:(NSArray *)batchValues;

/**
 * batch delete data
 * @param tableName
 * @param field
 * @param conditions
 * @return
 */
- (BOOL)batchDeleteTableName:(NSString *)tableName whenFiled:(NSString *)field inConditions:(NSArray *)conditions;

/**
 * db migration
 * @param publickey
 * @return
 */
+ (BOOL)migrationWithUserPublicKey:(NSString *)publickey;

@end
