//
//  SPTaskTest.m
//  Moriarty
//
//  Created by Joachim Bengtsson on 2012-12-26.
//
//

#import "SPTaskTest.h"
#import "SPTask.h"

@implementation SPTaskTest
- (void)testCallback
{
    SPTaskCompletionSource *source = [SPTaskCompletionSource new];
    SPTask *task = source.task;
    dispatch_queue_t callbackQueue = dispatch_get_main_queue();
    __block BOOL firstCallbackTriggered = NO;
    __block BOOL secondCallbackTriggered = NO;
    
    [task addCallback:^(id value) {
        STAssertEqualObjects(value, @(1337), @"Unexpected value");
        STAssertEquals(firstCallbackTriggered, NO, @"Callback should only trigger once");
        firstCallbackTriggered = YES;
    } on:callbackQueue];
    [task addErrback:^(id value) {
        STAssertTrue(NO, @"Error should not have triggered");
    } on:callbackQueue];
    [task addCallback:^(id value) {
        STAssertEqualObjects(value, @(1337), @"Unexpected value");
        STAssertEquals(firstCallbackTriggered, YES, @"First callback should have triggered before the second");
        secondCallbackTriggered = YES;
    } on:callbackQueue];
    
    [source completeWithValue:@(1337)];
    
    // Spin the runloop
    while(!secondCallbackTriggered)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    STAssertEquals(firstCallbackTriggered, YES, @"First callback should have triggered");
    STAssertEquals(secondCallbackTriggered, YES, @"Second callback should have triggered");
    
}

- (void)testErrback
{
    SPTaskCompletionSource *source = [SPTaskCompletionSource new];
    SPTask *task = source.task;
    dispatch_queue_t callbackQueue = dispatch_get_main_queue();
    __block BOOL firstErrbackTriggered = NO;
    __block BOOL secondErrbackTriggered = NO;
    
    [task addErrback:^(NSError *error) {
        STAssertEquals(error.code, (NSInteger)1337, @"Unexpected error code");
        STAssertEquals(firstErrbackTriggered, NO, @"Errback should only trigger once");
        firstErrbackTriggered = YES;
    } on:callbackQueue];
    [task addCallback:^(id value) {
        STAssertTrue(NO, @"Callback should not have triggered");
    } on:callbackQueue];
    [task addErrback:^(NSError *error) {
        STAssertEquals(error.code, (NSInteger)1337, @"Unexpected error code");
        STAssertEquals(firstErrbackTriggered, YES, @"First errback should have triggered before the second");
        secondErrbackTriggered = YES;
    } on:callbackQueue];
    
    [source failWithError:[NSError errorWithDomain:@"test" code:1337 userInfo:nil]];
    
    // Spin the runloop
    while(!secondErrbackTriggered)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    STAssertEquals(firstErrbackTriggered, YES, @"First errback should have triggered");
    STAssertEquals(secondErrbackTriggered, YES, @"Second errback should have triggered");
}

- (void)testLateCallback
{
    SPTaskCompletionSource *source = [SPTaskCompletionSource new];
    SPTask *task = source.task;
    dispatch_queue_t callbackQueue = dispatch_get_main_queue();
    __block BOOL firstCallbackTriggered = NO;
    __block BOOL secondCallbackTriggered = NO;
    
    [task addCallback:^(id value) {
        STAssertEqualObjects(value, @(1337), @"Unexpected value");
        STAssertEquals(firstCallbackTriggered, NO, @"Callback should only trigger once");
        firstCallbackTriggered = YES;
    } on:callbackQueue];
    
    [source completeWithValue:@(1337)];

    [task addCallback:^(id value) {
        STAssertEqualObjects(value, @(1337), @"Unexpected value");
        secondCallbackTriggered = YES;
    } on:callbackQueue];
    
    
    // Spin the runloop
    while(!secondCallbackTriggered)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    STAssertEquals(firstCallbackTriggered, YES, @"First callback should have triggered");
    STAssertEquals(secondCallbackTriggered, YES, @"Second callback should have triggered");
}

- (void)testLateErrback
{
    SPTaskCompletionSource *source = [SPTaskCompletionSource new];
    SPTask *task = source.task;
    dispatch_queue_t callbackQueue = dispatch_get_main_queue();
    __block BOOL firstErrbackTriggered = NO;
    __block BOOL secondErrbackTriggered = NO;
    
    [task addErrback:^(NSError *error) {
        STAssertEquals(error.code, (NSInteger)1337, @"Unexpected value");
        STAssertEquals(firstErrbackTriggered, NO, @"Callback should only trigger once");
        firstErrbackTriggered = YES;
    } on:callbackQueue];
    
    [source failWithError:[NSError errorWithDomain:@"test" code:1337 userInfo:nil]];

    [task addErrback:^(NSError *error) {
        STAssertEquals(error.code, (NSInteger)1337, @"Unexpected value");
        secondErrbackTriggered = YES;
    } on:callbackQueue];
    
    // Spin the runloop
    while(!secondErrbackTriggered)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    
    STAssertEquals(firstErrbackTriggered, YES, @"First callback should have triggered");
    STAssertEquals(secondErrbackTriggered, YES, @"Second callback should have triggered");
}

- (void)testThen
{
    SPTaskCompletionSource *source = [SPTaskCompletionSource new];
    [source completeWithValue:@(10)];

    __block BOOL done = NO;
    
    [[[source.task then:^id(id value) {
        return @([value intValue]*20);
    } on:dispatch_get_main_queue()] then:^id(id value) {
        return @([value intValue]*30);
    } on:dispatch_get_main_queue()] addCallback:^(id value) {
        STAssertEqualObjects(value, @(6000), @"Chain didn't chain as expected");
        done = YES;
    } on:dispatch_get_main_queue()];
    
    while(!done)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
}

@end