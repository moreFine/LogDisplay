//
//  EncryptAndDecryptMananger.h
//  XJKHealth
//
//  Created by wangwei on 2019/7/3.
//  Copyright © 2019 xiaweidong. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EncryptAndDecryptMananger : NSObject
//获取加解密SDK版本
-(NSString *)version;
//数据流加密
-(NSData * _Nonnull)encryptorStream:(NSData * _Nonnull)content;
//数据流解密
-(NSData * _Nonnull)decryptorStream:(NSData * _Nonnull)content;
//log日志解密
-(NSData * _Nonnull)decryptorLog:(NSString * _Nonnull)filePath;
//组成完整的数据【文件头+包头+数据+文件尾】
-(NSData * _Nonnull)assembleFileData:(NSData * _Nullable)headData bodyData:(NSData * _Nonnull)bodyData;
@end

NS_ASSUME_NONNULL_END
