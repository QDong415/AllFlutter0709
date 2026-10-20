#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 友盟一键认证启动初始化器。
///
/// 在 AppDelegate 冷启动阶段调用一次，并缓存初始化结果供 Flutter 登录流程等待。
@interface UmengAuthBootstrap : NSObject

+ (void)startWithAppKey:(NSString *)appKey
           verifySecret:(NSString *)verifySecret
                 channel:(NSString *)channel;

+ (void)waitUntilPrepared:(void (^)(NSDictionary *result))completion;

@end

NS_ASSUME_NONNULL_END
