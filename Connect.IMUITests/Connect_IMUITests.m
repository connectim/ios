//
//  Connect_IMUITests.m
//  Connect.IMUITests
//
//  Created by MoHuilin on 2017/3/6.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface Connect_IMUITests : XCTestCase

@end

@implementation Connect_IMUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    XCUIElement *element = [[[[[[[[[[[[app childrenMatchingType:XCUIElementTypeWindow] elementBoundByIndex:0] childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther] elementBoundByIndex:0];
    XCUIElement *button = [element childrenMatchingType:XCUIElementTypeButton].element;
    [button pressForDuration:10.f];
    
    XCUIElement *textView = [[[element childrenMatchingType:XCUIElementTypeOther] elementBoundByIndex:2] childrenMatchingType:XCUIElementTypeTextView].element;
    [textView tap];
    [textView typeText:@"qqqqqww"];
    [textView typeText:@"\n"];
    
    
    XCUIElement *elementMore = [[[app childrenMatchingType:XCUIElementTypeWindow] elementBoundByIndex:0] childrenMatchingType:XCUIElementTypeOther].element;
    [[[[[[[[[[[[[[elementMore childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther] elementBoundByIndex:0] childrenMatchingType:XCUIElementTypeOther] elementBoundByIndex:1] childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeButton].element tap];
    
    XCUIElementQuery *elementsQuery = app.scrollViews.otherElements;
    [elementsQuery.buttons[@"Photo libary"] tap];
    [[[[app.collectionViews childrenMatchingType:XCUIElementTypeCell] elementBoundByIndex:21].otherElements childrenMatchingType:XCUIElementTypeButton].element tap];
    [app.buttons[@"Send"] tap];
    
    XCUIElement *sightButton = elementsQuery.buttons[@"Sight"];
    [sightButton tap];
    
    XCUIElement *retakePhotoButton = app.buttons[@"retake photo"];
    [retakePhotoButton tap];
    [app.buttons[@"send photo"] tap];
    
    
    [sightButton tap];
    [retakePhotoButton pressForDuration:10.f];
    [app.buttons[@"send photo"] tap];
    
    [elementsQuery.buttons[@"Name Card"] tap];
    [app.tables.staticTexts[@"123"] tap];
    [app.alerts.buttons[@"Send"] tap];
    
    
    [elementsQuery.buttons[@"Request"] tap];
    [app.buttons[@"By"] tap];
}

- (void)testLogin {
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    XCUIElementQuery *tablesQuery = app.tables;
    [tablesQuery.staticTexts[@"About"] tap];
    [tablesQuery.staticTexts[@"Open Source"] tap];
    [app.navigationBars[@"Connect"].buttons[@"back white"] tap];
    [tablesQuery.staticTexts[@"Check Update"] tap];
    [app.alerts[@"Tips"].buttons[@"OK"] tap];
    [app.navigationBars[@"About"].buttons[@"back white"] tap];
    [tablesQuery.buttons[@"Log Out"] tap];
    [app.alerts.buttons[@"Cancel"] tap];
}

@end
