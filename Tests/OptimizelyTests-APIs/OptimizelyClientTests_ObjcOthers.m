/****************************************************************************
 * Copyright 2019, Optimizely, Inc. and contributors                        *
 *                                                                          *
 * Licensed under the Apache License, Version 2.0 (the "License");          *
 * you may not use this file except in compliance with the License.         *
 * You may obtain a copy of the License at                                  *
 *                                                                          *
 *    http://www.apache.org/licenses/LICENSE-2.0                            *
 *                                                                          *
 * Unless required by applicable law or agreed to in writing, software      *
 * distributed under the License is distributed on an "AS IS" BASIS,        *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
 * See the License for the specific language governing permissions and      *
 * limitations under the License.                                           *
 ***************************************************************************/


#import <XCTest/XCTest.h>
#import "OptimizelyTests_APIs_iOS-Swift.h"

static NSString * const kExperimentKey = @"exp_with_audience";
static NSString * const kVariationKey = @"a";
static NSString * const kVariationOtherKey = @"b";
static NSString * const kEventKey = @"event1";
static NSString * const kFeatureKey = @"feature_1";

static NSString * const kUserId = @"11111";
static NSString * const kSdkKey = @"12345";

@interface OptimizelyClientTests_ObjcOthers : XCTestCase
@property(nonatomic) OptimizelyClient *optimizely;
@property(nonatomic) NSString *datafile;
@property(nonatomic) NSDictionary * attributes;
@end


// MARK: - Custom EventDispatcher

@interface MockOPTEventDispatcher: NSObject <OPTEventsDispatcher>
@property(atomic, assign) int eventCount;
@end

@implementation MockOPTEventDispatcher
- (id)init {
    self = [super init];
    _eventCount = 0;
    return self;
}

- (void)dispatchWithEvent:(EventForDispatch * _Nonnull)event completionHandler:(void (^ _Nullable)(NSData * _Nullable, NSError * _Nullable))completionHandler {
    self.eventCount++;
    NSLog(@">>>>> eventCount: %d", self.eventCount);
    completionHandler([NSData new], nil);
    return;
}
@end

@implementation OptimizelyClientTests_ObjcOthers

- (void)setUp {
    [OTUtils clearRegistryService];

    NSString *filePath = [[NSBundle bundleForClass:self.class] pathForResource:@"api_datafile" ofType:@"json"];
    self.datafile = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    [OTUtils clearRegistryService];
    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey:@"any-key"];
}

- (void)tearDown {
    [OTUtils clearRegistryService];
}

// MARK: - Test notification listners

- (void)testNotificationCenter_Activate {
    XCTestExpectation *exp = [self expectationWithDescription:@"x"];
    
    __block BOOL called = false;
    NSNumber *num = [self.optimizely.notificationCenter addActivateNotificationListenerWithActivateListener:^(NSDictionary<NSString *,id> * experiment,
                                                                                                              NSString * userId,
                                                                                                              NSDictionary<NSString *,id> * attributes,
                                                                                                              NSDictionary<NSString *,id> * variation,
                                                                                                              NSDictionary<NSString *,id> * event) {
        called = true;
        [exp fulfill];
    }];
    
    [self.optimizely startWithDatafile:self.datafile error:nil];
    
    NSString *variationKey = [self.optimizely activateWithExperimentKey:kExperimentKey
                                                                 userId:kUserId
                                                             attributes:@{@"key_1": @"value_1"}
                                                                  error:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    XCTAssert(called);
    NSLog(@"notification: (%@ %@)", num, variationKey);
}

- (void)testNotificationCenter_Track {
    XCTestExpectation *exp = [self expectationWithDescription:@"x"];
    
    __block BOOL called = false;
    NSNumber *num = [self.optimizely.notificationCenter addTrackNotificationListenerWithTrackListener:^(NSString * eventKey,
                                                                                                        NSString * userId,
                                                                                                        NSDictionary<NSString *,id> * attributes,
                                                                                                        NSDictionary<NSString *,id> * eventTags,
                                                                                                        NSDictionary<NSString *,id> * event) {
        called = true;
        [exp fulfill];
    }];
    
    [self.optimizely startWithDatafile:self.datafile error:nil];
    
    [self.optimizely trackWithEventKey:kEventKey userId:kUserId attributes:nil eventTags:nil error:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    XCTAssert(called);
    NSLog(@"notification: (%@)", num);
}

- (void)testNotificationCenter_Decision {
    XCTestExpectation *exp = [self expectationWithDescription:@"x"];
    
    __block BOOL called = false;
    NSNumber *num = [self.optimizely.notificationCenter addDecisionNotificationListenerWithDecisionListener:^(NSString * type,
                                                                                                              NSString * userId,
                                                                                                              NSDictionary<NSString *,id> * attributes,
                                                                                                              NSDictionary<NSString *,id> * decisionInfo) {
        called = true;
        [exp fulfill];
    }];
    
    [self.optimizely startWithDatafile:self.datafile error:nil];
    
    BOOL enabled = [self.optimizely isFeatureEnabledWithFeatureKey:kFeatureKey userId:kUserId attributes:nil];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    
    XCTAssert(called);
    NSLog(@"notification: (%@ %d)", num, enabled);
}

- (void)testNotificationCenter_RemoveListener {
    __block BOOL called = false;
    NSNumber *num = [self.optimizely.notificationCenter addDecisionNotificationListenerWithDecisionListener:^(NSString * type,
                                                                                                              NSString * userId,
                                                                                                              NSDictionary<NSString *,id> * attributes,
                                                                                                              NSDictionary<NSString *,id> * decisionInfo) {
        called = true;
    }];
    
    [self.optimizely startWithDatafile:self.datafile error:nil];
    
    BOOL enabled = [self.optimizely isFeatureEnabledWithFeatureKey:kFeatureKey userId:kUserId attributes:nil];
    sleep(1);
    XCTAssert(called);
    
    called = false;
    enabled = [self.optimizely isFeatureEnabledWithFeatureKey:kFeatureKey userId:kUserId attributes:nil];
    sleep(1);
    XCTAssert(called);
    
    // remove notification listener with type
    [self.optimizely.notificationCenter clearNotificationListenersWithType:NotificationTypeDecision];
    
    called = false;
    enabled = [self.optimizely isFeatureEnabledWithFeatureKey:kFeatureKey userId:kUserId attributes:nil];
    sleep(1);
    XCTAssertFalse(called);
    
    
    num = [self.optimizely.notificationCenter addDecisionNotificationListenerWithDecisionListener:^(NSString * type,
                                                                                                    NSString * userId,
                                                                                                    NSDictionary<NSString *,id> * attributes,
                                                                                                    NSDictionary<NSString *,id> * decisionInfo) {
        called = true;
    }];
    
    called = false;
    enabled = [self.optimizely isFeatureEnabledWithFeatureKey:kFeatureKey userId:kUserId attributes:nil];
    sleep(1);
    XCTAssert(called);
    
    // remove notification listener with id
    [self.optimizely.notificationCenter removeNotificationListenerWithNotificationId:[num intValue]];
    
    called = false;
    enabled = [self.optimizely isFeatureEnabledWithFeatureKey:kFeatureKey userId:kUserId attributes:nil];
    sleep(1);
    XCTAssertFalse(called);
    
    num = [self.optimizely.notificationCenter addDecisionNotificationListenerWithDecisionListener:^(NSString * type,
                                                                                                    NSString * userId,
                                                                                                    NSDictionary<NSString *,id> * attributes,
                                                                                                    NSDictionary<NSString *,id> * decisionInfo) {
        called = true;
    }];
    
    called = false;
    enabled = [self.optimizely isFeatureEnabledWithFeatureKey:kFeatureKey userId:kUserId attributes:nil];
    sleep(1);
    XCTAssert(called);
    
    // remove all notification listeners
    [self.optimizely.notificationCenter clearAllNotificationListeners];
    
    called = false;
    enabled = [self.optimizely isFeatureEnabledWithFeatureKey:kFeatureKey userId:kUserId attributes:nil];
    sleep(1);
    XCTAssertFalse(called);
    
}

// MARK: - Test custom EventDispatcher

- (void)testCustomEventDispatcher_DefaultEventDispatcher {
    MockOPTEventDispatcher *customEventDispatcher = [[MockOPTEventDispatcher alloc] init];
    BatchEventProcessor *customEventProcessor = [[BatchEventProcessor alloc] initWithEventDispatcher:customEventDispatcher
                                                                                           batchSize:1
                                                                                       timerInterval:10
                                                                                        maxQueueSize:100];
    [customEventProcessor clear];
    customEventDispatcher.eventCount = 0;
    [OptimizelyClient clearRegistryService];
    
    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey:@"any-key"
                                                        logger:nil
                                                eventProcessor:customEventProcessor
                                               eventDispatcher:nil
                                            userProfileService:nil
                                      periodicDownloadInterval:@(0)
                                               defaultLogLevel:OptimizelyLogLevelInfo];
    
    [self.optimizely startWithDatafile:self.datafile error:nil];

    NSString *variationKey = [self.optimizely activateWithExperimentKey:kExperimentKey
                                                                    userId:kUserId
                                                                attributes:@{@"key_1": @"value_1"}
                                                                    error:nil];
    [customEventProcessor clear];
    XCTAssertEqual(customEventDispatcher.eventCount, 1);
}

- (void)testCustomEventDispatcher {
    MockOPTEventDispatcher *customEventDispatcher = [[MockOPTEventDispatcher alloc] init];
    BatchEventProcessor *customEventProcessor = [[BatchEventProcessor alloc] initWithEventDispatcher:customEventDispatcher
                                                                                           batchSize:1
                                                                                       timerInterval:10
                                                                                        maxQueueSize:100];

    [customEventProcessor clear];
    customEventDispatcher.eventCount = 0;
    [OTUtils clearRegistryService];

    self.optimizely = [[OptimizelyClient alloc] initWithSdkKey:@"any-key"
                                                        logger:nil
                                                eventProcessor:customEventProcessor
                                               eventDispatcher:nil
                                            userProfileService:nil
                                      periodicDownloadInterval:@(0)
                                               defaultLogLevel:OptimizelyLogLevelInfo];
    [self.optimizely startWithDatafile:self.datafile error:nil];

    XCTAssertEqual(customEventDispatcher.eventCount, 0);
    [self.optimizely trackWithEventKey:kEventKey userId:kUserId attributes:nil eventTags:nil error:nil];

    [customEventProcessor clear];
    XCTAssertEqual(customEventDispatcher.eventCount, 1);
}

@end

