//
//  BaseDB.m
//  Connect
//
//  Created by MoHuilin on 16/7/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseDB.h"
#import <FMDBMigrationManager/FMDBMigrationManager.h>
#import "LMHistoryCacheManager.h"

@implementation BaseDB

- (BOOL)executeSql:(NSString *)sql {
    NSString *dbName = [self getCurrentDBName];
    if (!dbName) {
        return NO;
    }
    if (GJCFStringIsNull(sql)) {
        return NO;
    }
    NSString *dbPath = [MMGlobal getDBFile:dbName];
    BOOL __block result;
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        result = [db executeUpdate:sql];
    }];
    [queue close];
    return result;
}

- (BOOL)executeUpdataOrInsertWithTable:(NSString *)tableName fields:(NSArray *)fields batchValues:(NSArray *)batchValues {
    NSMutableString *palce = [NSMutableString stringWithFormat:@"("];
    NSMutableString *fieldString = [NSMutableString stringWithFormat:@"("];
    for (NSString *field in fields) {
        if ([field isEqualToString:[fields lastObject]]) {
            [palce appendString:@"?)"];
            [fieldString appendFormat:@"%@)", field];
        } else {
            [palce appendString:@"?,"];
            [fieldString appendFormat:@"%@,", field];
        }
    }

    NSMutableString *sql = [NSMutableString stringWithFormat:@"INSERT OR REPLACE INTO %@ %@ VALUES %@ ;", tableName, fieldString, palce];
    DDLogInfo(@"instertSql %@", sql);
    __block BOOL result = NO;
    NSString *dbPath = [MMGlobal getDBFile:[self getCurrentDBName]];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {;
        if (batchValues && batchValues.count > 0) {
            for (NSArray *values in batchValues) {
                result = [db executeUpdate:sql withArgumentsInArray:values];
            }
        } else {
            result = [db executeUpdate:sql];
        }
    }];
    return result;
}


- (NSArray *)queryWithSql:(NSString *)sql {
    NSString *dbName = [self getCurrentDBName];
    if (!dbName) {
        DDLogInfo(@"Save the database as empty");
        return nil;
    }
    if (GJCFStringIsNull(sql)) {
        return nil;
    }
    NSMutableArray __block *arrayM = @[].mutableCopy;
    NSString *dbPath = [MMGlobal getDBFile:dbName];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inDatabase:^(FMDatabase *db) {
        FMResultSet *result = [db executeQuery:sql];
        while ([result next]) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            for (int i = 0; i < result.columnCount; i++) {
                NSString *name = [result columnNameForIndex:i];
                [dict setObject:[result objectForColumnIndex:i] forKey:name];
            }
            [arrayM objectAddObject:dict];
        }
    }];
    [queue close];
    return arrayM.copy;
}

- (NSArray *)getAllDatasFromTableName:(NSString *)tableName fields:(NSArray *)fields {
    return [self getDatasFromTableName:tableName conditions:nil fields:fields];
}

- (void)getDatasFromTableName:(NSString *)tableName conditions:(NSDictionary *)conditions fields:(NSArray *)fields complete:(void (^)(NSArray *dates))complete {
    tableName = [DBTableNameFormart formartTableName:tableName];
    NSMutableArray __block *resultArr = [NSMutableArray array];
    NSString *dbPath = [MMGlobal getDBFile:[self getCurrentDBName]];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [GCDQueue executeInGlobalQueue:^{
        [queue inDatabase:^(FMDatabase *db) {
            NSMutableString *fieldM = [NSMutableString string];
            if (fields.count) {
                for (NSString *field in fields) {
                    if ([field isEqualToString:[fields lastObject]]) {
                        [fieldM appendString:field];
                    } else {
                        [fieldM appendFormat:@"%@,", field];
                    }
                }
            } else {
                [fieldM appendString:@" * "];
            }

            NSMutableString *conditionM = [NSMutableString string];
            if (conditions && conditions.allValues.count) {
                [conditionM appendString:@" WHERE "];
                for (NSString *key in conditions.allKeys) {
                    [conditionM appendFormat:@"%@= \"%@\" ", key, [conditions objectForKey:key]];
                    if (![key isEqualToString:[conditions.allKeys lastObject]]) {
                        [conditionM appendString:@" AND "];
                    }
                }
            }

            NSMutableString *selectSql = [NSMutableString stringWithFormat:@"SELECT %@ FROM %@ %@ ;", fieldM, tableName, conditionM];
            FMResultSet *rs = [db executeQuery:selectSql];
            NSMutableDictionary *dictRow = nil;
            while ([rs next]) {
                dictRow = [[NSMutableDictionary alloc] init];
                for (NSString *key in fields) {
                    if (![rs columnIsNull:key]) {
                        [dictRow setObject:[rs stringForColumn:key] forKey:key];
                    }
                }
                [resultArr objectAddObject:dictRow];
            }
        }];

        if (complete) {
            complete(resultArr.copy);
        }
        [queue close];
    }];
}


- (NSArray *)getDatasFromTableName:(NSString *)tableName conditions:(NSDictionary *)conditions fields:(NSArray *)fields {

    tableName = [DBTableNameFormart formartTableName:tableName];

    NSMutableArray __block *resultArr = [NSMutableArray array];
    NSString *dbPath = [MMGlobal getDBFile:[self getCurrentDBName]];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inDatabase:^(FMDatabase *db) {
        NSMutableString *fieldM = [NSMutableString string];
        if (fields.count) {
            for (NSString *field in fields) {
                if ([field isEqualToString:[fields lastObject]]) {
                    [fieldM appendString:field];
                } else {
                    [fieldM appendFormat:@"%@,", field];
                }
            }
        } else {
            [fieldM appendString:@" * "];
        }

        NSMutableString *conditionM = [NSMutableString string];
        if (conditions && conditions.allValues.count) {
            [conditionM appendString:@" WHERE "];
            for (NSString *key in conditions.allKeys) {
                [conditionM appendFormat:@"%@= \"%@\" ", key, [conditions objectForKey:key]];
                if (![key isEqualToString:[conditions.allKeys lastObject]]) {
                    [conditionM appendString:@" AND "];
                }
            }
        }

        NSMutableString *selectSql = [NSMutableString stringWithFormat:@"SELECT %@ FROM %@ %@ ;", fieldM, tableName, conditionM];
        FMResultSet *rs = [db executeQuery:selectSql];
        NSMutableDictionary *dictRow = nil;
        while ([rs next]) {
            dictRow = [[NSMutableDictionary alloc] init];
            for (NSString *key in fields) {
                if (![rs columnIsNull:key]) {
                    [dictRow setObject:[rs stringForColumn:key] forKey:key];
                }
            }
            [resultArr objectAddObject:dictRow];
        }
    }];
    [queue close];
    return resultArr;

}

- (BOOL)saveToCuttrentDBTableName:(NSString *)tableName fieldsValues:(NSDictionary *)fieldsValues {

    NSArray *fields = fieldsValues.allKeys;
    NSArray *values = fieldsValues.allValues;
    return [self batchInsertTableName:tableName fields:fields batchValues:@[values]];

}

- (BOOL)updateTableName:(NSString *)tableName fieldsValues:(NSDictionary *)fieldsValues conditions:(NSDictionary *)conditions {
    BOOL __block result;

    NSArray *fields = fieldsValues.allKeys;
    NSArray *values = fieldsValues.allValues;

    if (fields.count != values.count) {
        return NO;
    }

    tableName = [DBTableNameFormart formartTableName:tableName];

    NSString *dbPath = [MMGlobal getDBFile:[self getCurrentDBName]];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSMutableString *setM = [NSMutableString string];
        if (fields.count) {
            for (int i = 0; i < fields.count; i++) {
                NSString *field = fields[i];
                NSString *value = values[i];
                if ([field isEqualToString:[fields lastObject]]) {
                    [setM appendFormat:@"%@ = \"%@\" ", field, value];
                } else {
                    [setM appendFormat:@"%@ = \"%@\" ,", field, value];
                }
            }
        }

        NSMutableString *conditionM = [NSMutableString string];
        if (conditions && conditions.allValues.count) {
            [conditionM appendString:@" WHERE "];
            for (NSString *key in conditions.allKeys) {
                [conditionM appendFormat:@" %@ = \"%@\" ", key, [conditions objectForKey:key]];
                if (![key isEqualToString:[conditions.allKeys lastObject]]) {
                    [conditionM appendString:@" AND "];
                }
            }
        }
        NSMutableString *updateSql = [NSMutableString stringWithFormat:@"UPDATE %@ SET %@ %@ ;", tableName, setM, conditionM];
        result = [db executeUpdate:updateSql];
    }];
    [queue close];
    return result;

}

- (BOOL)deleteTableName:(NSString *)tableName conditions:(NSDictionary *)conditions {

    BOOL __block result;

    NSString *dbPath = [MMGlobal getDBFile:[self getCurrentDBName]];

    tableName = [DBTableNameFormart formartTableName:tableName];

    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSMutableString *conditionM = [NSMutableString string];
        if (conditions && conditions.allValues.count) {
            [conditionM appendString:@" WHERE "];
            for (NSString *key in conditions.allKeys) {
                [conditionM appendFormat:@" %@ = \"%@\" ", key, [conditions objectForKey:key]];
                if (![key isEqualToString:[conditions.allKeys lastObject]]) {
                    [conditionM appendString:@" AND "];
                }
            }
        }
        NSMutableString *updateSql = [NSMutableString stringWithFormat:@"DELETE FROM %@ %@ ;", tableName, conditionM];
        result = [db executeUpdate:updateSql];
    }];

    [queue close];
    return result;

}

- (BOOL)deleteTableWithTableName:(NSString *)tableName {
    BOOL __block result;

    NSString *dbPath = [MMGlobal getDBFile:[self getCurrentDBName]];

    tableName = [DBTableNameFormart formartTableName:tableName];

    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSMutableString *sql = [NSMutableString stringWithFormat:@"DROP TABLE %@;", tableName];
        result = [db executeUpdate:sql];
    }];
    [queue close];
    return result;
}


- (BOOL)dropTableWithTableName:(NSString *)tableName {

    BOOL __block result;

    NSString *dbPath = [MMGlobal getDBFile:[self getCurrentDBName]];

    tableName = [DBTableNameFormart formartTableName:tableName];

    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSMutableString *sql = [NSMutableString stringWithFormat:@"DROP TABLE %@;", tableName];
        result = [db executeUpdate:sql];
    }];
    [queue close];
    return result;

}

- (BOOL)batchDeleteTableName:(NSString *)tableName whenFiled:(NSString *)field inConditions:(NSArray *)conditions {

    BOOL __block result;

    tableName = [DBTableNameFormart formartTableName:tableName];


    NSString *dbPath = [MMGlobal getDBFile:[self getCurrentDBName]];

    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {

        NSMutableString *inCondition = [NSMutableString string];
        for (int i = 0; i < conditions.count; i++) {
            NSString *con = [conditions objectAtIndexCheck:i];
            if (i == 0) {
                [inCondition appendFormat:@"%@", con];
            } else {
                [inCondition appendFormat:@", %@", con];
            }
        }

        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ IN (%@)", tableName, field, inCondition];

        result = [db executeUpdate:sql];
    }];

    return result;
}

- (BOOL)batchInsertTableName:(NSString *)tableName fields:(NSArray *)fields batchValues:(NSArray *)batchValues {

    NSMutableString *palce = [NSMutableString stringWithFormat:@"("];
    NSMutableString *fieldString = [NSMutableString stringWithFormat:@"("];
    for (NSString *field in fields) {
        if ([field isEqualToString:[fields lastObject]]) {
            [palce appendString:@"?)"];
            [fieldString appendFormat:@"%@)", field];
        } else {
            [palce appendString:@"?,"];
            [fieldString appendFormat:@"%@,", field];
        }
    }

    tableName = [DBTableNameFormart formartTableName:tableName];
    NSString *dbPath = [MMGlobal getDBFile:[self getCurrentDBName]];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    NSMutableString *sql = [NSMutableString stringWithFormat:@"INSERT OR REPLACE INTO %@ %@ VALUES %@ ;", tableName, fieldString, palce];
    DDLogInfo(@"instertSql %@", sql);
    __block BOOL result = NO;
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {;
        if (batchValues && batchValues.count > 0) {
            for (NSArray *values in batchValues) {
                result = [db executeUpdate:sql withArgumentsInArray:values];
            }
        } else {
            result = [db executeUpdate:sql];
        }
    }];
    return result;

}


- (NSArray *)getDatasFromTableName:(NSString *)tableName conditions:(NSDictionary *)conditions fields:(NSArray *)fields orderBy:(NSString *)orderby sortWay:(DBSortWayType)sort {

    tableName = [DBTableNameFormart formartTableName:tableName];

    NSMutableArray __block *resultArr = [NSMutableArray array];
    NSString *dbPath = [MMGlobal getDBFile:[self getCurrentDBName]];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inDatabase:^(FMDatabase *db) {

        NSMutableString *fieldM = [NSMutableString string];
        if (fields.count) {
            for (NSString *field in fields) {
                if ([field isEqualToString:[fields lastObject]]) {
                    [fieldM appendString:field];
                } else {
                    [fieldM appendFormat:@"%@,", field];
                }
            }
        } else {
            [fieldM appendString:@" * "];
        }

        NSMutableString *conditionM = [NSMutableString string];
        if (conditions && conditions.allValues.count) {
            [conditionM appendString:@" WHERE "];
            for (NSString *key in conditions.allKeys) {
                [conditionM appendFormat:@"%@= \"%@\" ", key, [conditions objectForKey:key]];
                if (![key isEqualToString:[conditions.allKeys lastObject]]) {
                    [conditionM appendString:@" AND "];
                }
            }
        }

        NSMutableString *order = [NSMutableString string];
        if (orderby && orderby.length > 0) {
            [order appendString:@" ORDER BY "];
            [order appendString:orderby];

            if (sort == 1) { //ASC 代表結果會以由小往大的順序列出，而 DESC 代表結果會以由大往小的順序列出
                [order appendString:@" DESC "];
            } else if (sort == 2) {
                [order appendString:@" ASC "];
            } else {
                [order appendString:@" DESC "];
            }
        }

        NSMutableString *selectSql = [NSMutableString stringWithFormat:@"SELECT %@ FROM %@ %@ %@ ;", fieldM, tableName, conditionM, order];
        FMResultSet *rs = [db executeQuery:selectSql];
        NSMutableDictionary *dictRow = nil;
        while ([rs next]) {
            dictRow = [[NSMutableDictionary alloc] init];
            for (NSString *key in fields) {
                if (![rs columnIsNull:key]) {
                    [dictRow setObject:[rs stringForColumn:key] forKey:key];
                }
            }
            [resultArr objectAddObject:dictRow];
        }
    }];
    [queue close];
    return resultArr;

}


- (NSArray *)getDatasFromTableName:(NSString *)tableName fields:(NSArray *)fields conditions:(NSDictionary *)conditions limit:(int)limit orderBy:(NSString *)orderby sortWay:(DBSortWayType)sort {

    tableName = [DBTableNameFormart formartTableName:tableName];

    int long long count = [self getCountFromCurrentDBWithTableName:tableName condition:conditions];

    if (count == 0) {
        return @[].copy;
    }
    if (limit == -1) {
        limit = (int) count;
    }

    NSMutableArray __block *resultArr = [NSMutableArray array];
    NSString *dbPath = [MMGlobal getDBFile:[self getCurrentDBName]];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inDatabase:^(FMDatabase *db) {

        NSMutableString *fieldM = [NSMutableString string];
        if (fields.count) {
            for (NSString *field in fields) {
                if ([field isEqualToString:[fields lastObject]]) {
                    [fieldM appendString:field];
                } else {
                    [fieldM appendFormat:@"%@,", field];
                }
            }
        } else {
            [fieldM appendString:@" * "];
        }

        NSMutableString *conditionM = [NSMutableString string];
        if (conditions && conditions.allValues.count) {
            [conditionM appendString:@" WHERE "];
            for (NSString *key in conditions.allKeys) {
                [conditionM appendFormat:@"%@ \"%@\" ", key, [conditions objectForKey:key]];
                if (![key isEqualToString:[conditions.allKeys lastObject]]) {
                    [conditionM appendString:@" AND "];
                }
            }
        }


        NSMutableString *order = [NSMutableString string];
        if (orderby && orderby.length > 0) {
            [order appendString:@" ORDER BY "];
            [order appendString:orderby];

            switch (sort) {
                case DBSortWayTypeASC: //ASC 代表結果會以由小往大的順序列出，而 DESC 代表結果會以由大往小的順序列出
                    [order appendString:@" ASC "];
                    break;
                default:
                    [order appendString:@" DESC "];
                    break;
            }
        }
        int long long offsetIndex = count - limit;
        int long long limitIndex = limit;
        if (count < limit) {
            offsetIndex = 0;
            limitIndex = count;
        }
        NSMutableString *selectSql = [NSMutableString stringWithFormat:@"SELECT %@ FROM %@  %@ %@ LIMIT %lld OFFSET %lld ;", fieldM, tableName, conditionM, order, limitIndex, offsetIndex];
        //DDLogInfo(selectSql);
        NSLog(@"%@", selectSql);
        FMResultSet *rs = [db executeQuery:selectSql];
        NSMutableDictionary *dictRow = nil;
        while ([rs next]) {
            dictRow = [[NSMutableDictionary alloc] init];
            for (NSString *key in fields) {
                if (![rs columnIsNull:key]) {
                    [dictRow setObject:[rs stringForColumn:key] forKey:key];
                }
            }
            [resultArr objectAddObject:dictRow];
        }
    }];
    [queue close];
    return resultArr;
}


- (NSArray *)getDatasFromTableName:(NSString *)tableName fields:(NSArray *)fields conditions:(NSDictionary *)conditions conditionSymbol:(int)symbol limit:(int)limit orderBy:(NSString *)orderby sortWay:(int)sort {

    tableName = [DBTableNameFormart formartTableName:tableName];

    int long long count = [self getCountFromCurrentDBWithTableName:tableName condition:conditions symbol:symbol];

    if (count == 0) {
        return @[].copy;
    }
    if (limit == -1) {
        limit = (int) count;
    }
    if (count <= limit) {
        return [self getAllDatasFromTableName:tableName fields:fields];
    }

    NSMutableArray __block *resultArr = [NSMutableArray array];
    NSString *dbPath = [MMGlobal getDBFile:[self getCurrentDBName]];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inDatabase:^(FMDatabase *db) {

        NSMutableString *fieldM = [NSMutableString string];
        if (fields.count) {
            for (NSString *field in fields) {
                if ([field isEqualToString:[fields lastObject]]) {
                    [fieldM appendString:field];
                } else {
                    [fieldM appendFormat:@"%@,", field];
                }
            }
        } else {
            [fieldM appendString:@" * "];
        }


        NSMutableString *conditionM = [NSMutableString string];
        if (conditions && conditions.allValues.count) {
            [conditionM appendString:@" WHERE "];
            for (NSString *key in conditions.allKeys) {
                NSString *symbolStr = @"=";
                if (symbol < 0) {
                    symbolStr = @"<";
                } else if (symbol == 0) {
                    symbolStr = @"=";
                } else {
                    symbolStr = @">";
                }
                [conditionM appendFormat:@"%@ %@\"%@\"", key, symbolStr, [conditions objectForKey:key]];
                if (![key isEqualToString:[conditions.allKeys lastObject]]) {
                    [conditionM appendString:@" AND "];
                }
            }
        }


        NSMutableString *order = [NSMutableString string];
        if (orderby && orderby.length > 0) {
            [order appendString:@" ORDER BY "];
            [order appendString:orderby];

            if (sort == 1) { //ASC 代表結果會以由小往大的順序列出，而 DESC 代表結果會以由大往小的順序列出
                [order appendString:@" DESC "];
            } else if (sort == 2) {
                [order appendString:@" ASC "];
            } else {
                [order appendString:@" DESC "];
            }
        }
//        int long long offsetIndex = 0;
        int long long offsetIndex = count - limit;
        int long long limitIndex = limit;
        NSMutableString *selectSql = [NSMutableString stringWithFormat:@"SELECT %@ FROM %@  %@ %@ LIMIT %lld OFFSET %lld ;", fieldM, tableName, conditionM, order, limitIndex, offsetIndex];
        //DDLogInfo(selectSql);
        NSLog(@"%@", selectSql);
        FMResultSet *rs = [db executeQuery:selectSql];
        NSMutableDictionary *dictRow = nil;
        while ([rs next]) {
            dictRow = [[NSMutableDictionary alloc] init];
            for (NSString *key in fields) {
                if (![rs columnIsNull:key]) {
                    [dictRow setObject:[rs stringForColumn:key] forKey:key];
                }
            }
            [resultArr objectAddObject:dictRow];
        }
    }];
    [queue close];
    return resultArr;
}

- (id)defaultValue:(id)value {

    return nil;
}

- (long long int)getCountFromCurrentDBWithTableName:(NSString *)tableName {

    tableName = [DBTableNameFormart formartTableName:tableName];

    NSString *dbPath = [MMGlobal getDBFile:[self getCurrentDBName]];
    int long long __block count = 0;
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inDatabase:^(FMDatabase *db) {
        NSMutableString *sql = [NSMutableString stringWithFormat:@"SELECT COUNT(*) FROM %@;", tableName];
        DDLogInfo(@"sql %@",sql);
        FMResultSet *resultSet = [db executeQuery:sql];
        if ([resultSet next]) {
            count = [resultSet intForColumnIndex:0];
        }
    }];
    [queue close];
    return count;
}

- (long long int)getCountFromCurrentDBWithTableName:(NSString *)tableName condition:(NSDictionary *)conditions symbol:(int)symbol {

    tableName = [DBTableNameFormart formartTableName:tableName];

    NSString *dbPath = [MMGlobal getDBFile:[self getCurrentDBName]];
    int long long __block count = 0;
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inDatabase:^(FMDatabase *db) {
        NSMutableString *conditionM = [NSMutableString string];
        if (conditions && conditions.allValues.count) {
            [conditionM appendString:@" WHERE "];
            for (NSString *key in conditions.allKeys) {
                NSString *symbolStr = @"=";
                if (symbol < 0) {
                    symbolStr = @"<";
                } else if (symbol == 0) {
                    symbolStr = @"=";
                } else {
                    symbolStr = @">";
                }
                [conditionM appendFormat:@"%@ %@\"%@\"", key, symbolStr, [conditions objectForKey:key]];
                if (![key isEqualToString:[conditions.allKeys lastObject]]) {
                    [conditionM appendString:@" AND "];
                }
            }
        }


        NSMutableString *sql = [NSMutableString stringWithFormat:@"SELECT COUNT(*) FROM %@ %@;", tableName, conditionM];
        DDLogInfo(@"sql %@",sql);
        FMResultSet *resultSet = [db executeQuery:sql];
        if ([resultSet next]) {
            count = [resultSet intForColumnIndex:0];
        }
    }];
    [queue close];
    return count;
}

- (long long int)getCountFromCurrentDBWithTableName:(NSString *)tableName condition:(NSDictionary *)conditions {

    tableName = [DBTableNameFormart formartTableName:tableName];

    NSString *dbPath = [MMGlobal getDBFile:[self getCurrentDBName]];
    int long long __block count = 0;
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    [queue inDatabase:^(FMDatabase *db) {
        NSMutableString *conditionM = [NSMutableString string];
        if (conditions && conditions.allValues.count) {
            [conditionM appendString:@" WHERE "];
            for (NSString *key in conditions.allKeys) {
                [conditionM appendFormat:@"%@ \"%@\" ", key, [conditions objectForKey:key]];
                if (![key isEqualToString:[conditions.allKeys lastObject]]) {
                    [conditionM appendString:@" AND "];
                }
            }
        }

        NSMutableString *sql = [NSMutableString stringWithFormat:@"SELECT COUNT(*) FROM %@ %@;", tableName, conditionM];
        DDLogInfo(@"sql %@",sql);
        FMResultSet *resultSet = [db executeQuery:sql];
        if ([resultSet next]) {
            count = [resultSet intForColumnIndex:0];
        }
    }];
    [queue close];
    return count;
}


- (NSString *)getCurrentDBName {
    return [[LKUserCenter shareCenter] currentLoginUser].pub_key;
}


+ (BOOL)migrationWithUserPublicKey:(NSString *)publickey {
    if (GJCFStringIsNull(publickey)) {
        return NO;
    }
    NSString *dbPath = [MMGlobal getDBFile:publickey];

    FMDBMigrationManager *manager = [FMDBMigrationManager managerWithDatabaseAtPath:dbPath migrationsBundle:[NSBundle mainBundle]];
    BOOL resultState = NO;
    NSError *error = nil;
    if (!manager.hasMigrationsTable) {
        resultState = [manager createMigrationsTable:&error];
    }
    resultState = [manager migrateDatabaseToVersion:UINT64_MAX progress:nil error:&error];//迁移函数
    return resultState;
}
@end
