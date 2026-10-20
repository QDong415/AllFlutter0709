#import "UmengAuthBootstrap.h"

#import <UMCommon/UMConfigure.h>
#import <UMVerify/UMCommonHandler.h>

@implementation UmengAuthBootstrap

static BOOL _started = NO;
static NSDictionary *_result;
static NSMutableArray *_waiterList;

+ (void)startWithAppKey:(NSString *)appKey
           verifySecret:(NSString *)verifySecret
                 channel:(NSString *)channel {
  NSAssert([NSThread isMainThread], @"友盟认证初始化必须从主线程启动");
  if (_started) {
    return;
  }
  _started = YES;
  _waiterList = [NSMutableArray array];

  [UMConfigure initWithAppkey:appKey channel:channel];
  [UMCommonHandler
      setVerifySDKInfo:verifySecret
              complete:^(NSDictionary *_Nonnull resultDic) {
                NSAssert([NSThread isMainThread],
                         @"友盟认证初始化回调应位于主线程");
                _result = resultDic ?: @{
                  @"resultCode" : @"",
                  @"msg" : @"友盟认证初始化返回为空"
                };

                NSArray *waiterList = [_waiterList copy];
                [_waiterList removeAllObjects];
                for (id item in waiterList) {
                  void (^waiter)(NSDictionary *) = item;
                  waiter(_result);
                }
              }];
}

+ (void)waitUntilPrepared:(void (^)(NSDictionary *result))completion {
  NSAssert([NSThread isMainThread], @"Flutter MethodChannel 应位于主线程");
  if (_result != nil) {
    completion(_result);
    return;
  }
  if (!_started) {
    completion(@{
      @"resultCode" : @"",
      @"msg" : @"友盟认证尚未启动初始化"
    });
    return;
  }
  [_waiterList addObject:[completion copy]];
}

@end
