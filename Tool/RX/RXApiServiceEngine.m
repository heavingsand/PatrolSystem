//
//  RXApiServiceEngine.m
//  RMRefresh
//
//  Created by Ryan on 15/11/24.
//  Copyright © 2015年 RyanShen. All rights reserved.
//

#import "RXApiServiceEngine.h"
//#import "AFNetworking.h"
#import <AFNetworking.h>
#import "RXApiServiceRequest.h"
#import "RXApiServiceResponse.h"
#import "NSData+SDK_Encrypt.h"
#import "RXRuntime.h"
//#import "AFNetworkActivityIndicatorManager.h"
#import <AFNetworkActivityIndicatorManager.h>

#define CONVERTER(obj) [obj isEqual:[NSNull null]] ? nil: obj

// api error domain
NSString *const RXApiServiceErrorDomain = @"Api.Service.ErrorDomain";

// api error message key
NSString *const RXApiServiceErrorMessage = @"Api.Service.ErrorMessage";

static NSTimeInterval const timeoutInterval = 45.0f;

@interface RXApiServiceEngine()

@property (nonatomic, strong) AFURLSessionManager *sessionManager;

@property (nonatomic, copy) NSString *baseUrl;

@property (nonatomic, copy) NSString *secretKey;

@property (nonatomic, strong) NSMutableURLRequest *requset;

@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@end

@implementation RXApiServiceEngine
singleton_implementation(RXApiServiceEngine)
/**
 *  初始化
 *
 *  @param baseUrl   URL
 *  @param secretKey 秘钥
 */
- (instancetype)initWithBaseUrl:(NSString *)baseUrl secretKey:(NSString *)secretKey
{
    self = [super init];
    if (self)
    {
        NSURLSessionConfiguration *configuration =
        [NSURLSessionConfiguration defaultSessionConfiguration];
        _sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        [_sessionManager setResponseSerializer:responseSerializer];
        
        _baseUrl = baseUrl;
        _secretKey = secretKey;
    }
    return self;
}


/**
 发送一个网络请求

 @param type 请求类型,POST or GET
 @param url 路径
 @param parameters 参数
 @param competionHandler 完成的处理
 */
+ (void)requestWithType:(RequestMethodType)type
                    url:(NSString *)url
             parameters:(NSDictionary *)parameters
      completionHanlder:(CompletionHandler)competionHandler
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
//    manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"text/html", @"text/plain", @"text/json", @"text/javascript", @"application/json"]];
    AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];
    responseSerializer.removesKeysWithNullValues = YES;
    manager.responseSerializer = responseSerializer;
    NSLog(@"url:\n%@",url);
    
    NSString *parametersString = @"";
    for (NSString *key in [parameters allKeys]) {
        parametersString = [parametersString stringByAppendingFormat:@"%@=%@&",key,parameters[key]];
    }
    NSLog(@"parameter string:\n %@",parametersString);
    NSLog(@"parameters:\n %@",parameters);
    __weak typeof(self) weakSelf = self;
    
    switch (type) {
        case RequestMethodTypeGet:
        {
            [manager GET:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"url = %@\n response.content = \n%@",url,[[[self alloc] init] dictionaryToJson:responseObject]);
                // 增加token验证失败逻辑
                if ([responseObject[@"resultnumber"] intValue] == 206) {
                    [[UserManager sharedManager] logout];
                    return ;
                }
                if (competionHandler) {
                    competionHandler(responseObject,nil);
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                if (error.code == -1005) {
                    [weakSelf requestWithType:type
                                          url:url
                                   parameters:parameters
                            completionHanlder:competionHandler];
                }else if (error.code == -1001){
                    NSLog(@"网络请求超时%@",error);
                    if (competionHandler) {
                        competionHandler(nil,error);
                    }
                }else{
                    if (competionHandler) {
                        competionHandler(nil,error);
                    }
                }
                NSLog(@"网络请求错误码:%@",error);
            }];
        }
            break;
            
        case RequestMethodTypePost:
        {
            [manager POST:url parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"url = %@\n response.content = \n%@",url,[[[self alloc] init] dictionaryToJson:responseObject]);
                // 增加token验证失败逻辑
//                if ([responseObject[@"resultnumber"] intValue] == 206) {
//                    [kNotificationCenter postNotificationName:kNotifPresentLogin object:nil];
//                    [[UserManager sharedManager] logout];
//                    return ;
//                }
                if (competionHandler) {
                    competionHandler(responseObject,nil);
                }
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                if (error.code == -1005) {
                    [weakSelf requestWithType:type
                                          url:url
                                   parameters:parameters
                            completionHanlder:competionHandler];
                }else if (error.code == -1001){
                    NSLog(@"网络请求超时%@",error);
                    if (competionHandler) {
                        competionHandler(nil,error);
                    }
                }else{
//                    NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
//                    NSInteger statusCode = [response statusCode];

                    if (competionHandler) {
                        competionHandler(nil,error);
                    }
                }
                NSLog(@"网络请求错误码:%@",error);
            }];
        }
            break;
        default:
            break;
    }
}

+ (void)uploadImagesWithUrl:(NSString *)url andImages:(NSArray *)images andParameters:(NSDictionary *)parameters completionHanlder:(CompletionHandler)completionHanlder {
    
    NSMutableArray *imgDataArr = [NSMutableArray new];
    for (int i = 0; i < images.count; i ++) {
        NSData *imageData = [NSData photoCompression:images[i]];
        [imgDataArr addObject:imageData];
    }
    
    NSLog(@"url:\n%@",url);
    NSString *parametersString = @"";
    for (NSString *key in [parameters allKeys]) {
        parametersString = [parametersString stringByAppendingFormat:@"%@=%@&",key,parameters[key]];
    }
    NSLog(@"parameter string:\n %@",parametersString);
    NSLog(@"parameters:\n %@",parameters);
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSError *managerErr;
    manager.requestSerializer.timeoutInterval = 60;
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"text/html", @"text/plain", @"text/json", @"text/javascript", @"application/json"]];
    
    NSMutableURLRequest *uploadRequest = [manager.requestSerializer multipartFormRequestWithMethod:@"POST" URLString:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        for (int n = 0 ; n <imgDataArr.count; n++) {
            NSString *name = [NSString stringWithFormat:@"%d_picture",n + 1];
            NSString *fileName = [NSString stringWithFormat:@"%d.png", n +1];
            [formData appendPartWithFileData:imgDataArr[n] name:name fileName:fileName mimeType:@"image/jpeg"];
        }
    } error:&managerErr];
    
    [[manager uploadTaskWithStreamedRequest:uploadRequest progress:^(NSProgress * _Nonnull uploadProgress) {
        NSLog(@"上传进度:%@",uploadProgress);
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        NSLog(@"url = %@\n response.content = \n%@",url,[[[self alloc] init] dictionaryToJson:responseObject]);
        if (!error) {
            completionHanlder(responseObject,nil);
//            error = [NSError errorWithDomain:responseObject[@"cause"] code:[responseObject[@"resultnumber"] intValue] userInfo:nil];
        }
        if (error) {
            completionHanlder(nil,error);
            NSLog(@"%@",error.domain);
        }
    }] resume];
    /*********上传图片**********/
    //    [manager POST:kUrl_SubmitCleaningRecords parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
    //        [formData appendPartWithFileData:imageData name:@"one_picture" fileName:curImgName mimeType:@"image/jpeg"];
    //    } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
    //        NSLog(@"response.content = \n%@",responseObject);
    //        NSLog(@"上传成功");
    //    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
    //        NSLog(@"上传失败");
    //    }];
}

/**
 *   发送一个拼接httpbody类型的POST请求
 *
 *  @param servies        服务名
 *  @param parameters     参数
 *  @param successHandler 成功回调
 *  @param failureHanler  失败回调
 */
- (void)requestService:(NSString *)servies
            parameters:(NSDictionary *)parameters
             onSuccess:(SuccessHandler)successHandler
             onFailure:(FailureHandler)failureHanler
{
    RXApiServiceRequest *serviceRequest = [self generateServiceRequestWithServiceName:servies parameters:parameters];
    [self.requset setHTTPBody:[self encodeRequest:serviceRequest]];
    
    NSURLSessionDataTask *dataTask = [_sessionManager dataTaskWithRequest:self.requset completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error)
   {
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
          // 请求成功,有数据回来
          if (httpResponse.statusCode == 200) {
              RXApiServiceResponse *response = [self decodeResponse:responseObject];
              NSLog(@"response.content = \n%@",[self dictionaryToJson:response.content]);
              if (response.status == RXApiServiceResponseStatusSuccess) {
                  if (successHandler) {
                      successHandler(response.content);
                  }
              }else{
                  NSDictionary *userInfo = @{RXApiServiceErrorMessage : response.errorMessage};
                  NSError *error = [NSError errorWithDomain:RXApiServiceErrorDomain
                                                       code:response.status
                                                   userInfo:userInfo];
                  if (failureHanler) {
                      failureHanler(error);
                  }
              }
          }
          // 请求失败
          if (error) {
              if (failureHanler) {
                  failureHanler(error);
              }
          }
    }];
    
    [dataTask resume];
    self.dataTask = dataTask;
}

- (RXApiServiceRequest *)generateServiceRequestWithServiceName:(NSString *)serviceName
                                                    parameters:(NSDictionary *)parameters
{
    RXApiServiceRequest *request = [[RXApiServiceRequest alloc] init];
    RXRuntime *runtime = [RXRuntime sharedInstance];
    request.serviceName = serviceName;
    request.os = runtime.os;
    request.osVersion = runtime.osVersion;
    request.appName = runtime.appName;
    request.appVersion = runtime.appVersion;
    request.udid = runtime.udid;
    request.params = parameters;
    return request;
}

// 编码请求
- (NSData *)encodeRequest:(RXApiServiceRequest *)request
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    for (NSString *key in request.params.allKeys)
    {
        id value = request.params[key];
        if ([value isKindOfClass:[NSData class]])
        {
            NSData *data = value;
            params[key] = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        }
        else
        {
            params[key] = value;
        }
    }
    
    NSDictionary *jsonObject = @{
                                 @"service_name" : request.serviceName,
                                 @"os" : request.os,
                                 @"os_version" : request.osVersion,
                                 @"app_name" : request.appName,
                                 @"app_version" : request.appVersion,
                                 @"udid" : request.udid,
                                 @"params" : params
                                 };
    NSLog(@"request params: == \n%@",jsonObject);
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:nil];
    if (_secretKey != nil)
    {
        data = [data sdk_AESEncryptWithKey:_secretKey];
    }
    return data;
}

// 解码应答
- (RXApiServiceResponse *)decodeResponse:(NSData *)responseData
{
    NSData *data = responseData;
    
    if (_secretKey != nil)
    {
        data = [responseData sdk_AESDecryptWithKey:_secretKey];
    }
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    if ([json isKindOfClass:[NSDictionary class]]) {
        RXApiServiceResponse *response = [[RXApiServiceResponse alloc] init];
        response.status = (RXApiServiceResponseStatus)[CONVERTER(json[@"status"]) intValue];
        response.errorMessage = CONVERTER(json[@"error_message"]);
        response.content = CONVERTER(json[@"content"]);
        return response;
    }
    return nil;
}

- (NSMutableURLRequest *)requset
{
    if (!_requset) {
        
        NSURL *baseURL = [NSURL URLWithString:_baseUrl];
        
        _requset = [NSMutableURLRequest requestWithURL:baseURL
                                           cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                       timeoutInterval:timeoutInterval];
        
        [_requset setValue:@"Content-Type" forHTTPHeaderField:@"application/json"];
        
        _requset.HTTPMethod = @"POST";
    }
    return _requset;
}

- (NSString *)dictionaryToJson:(NSDictionary *)dic
{
    if (!dic) return nil;
    
    NSError *parseError = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&parseError];
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)cancelAllTask
{
    [self.dataTask cancel];
}

@end
