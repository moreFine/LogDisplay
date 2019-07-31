//
//  EncryptAndDecryptMananger.m
//  XJKHealth
//
//  Created by wangwei on 2019/7/3.
//  Copyright © 2019 xiaweidong. All rights reserved.
//

#import "EncryptAndDecryptMananger.h"
#import <XJK_AES_Decryptor/XJK_Aes_Encryptor.h>

@implementation EncryptAndDecryptMananger

static CXJK_Aes_Encryptor *aes = nil;

-(instancetype)init{
    if (self = [super init]){
        aes = new CXJK_Aes_Encryptor();
        NSLog(@"加密算法版本：%@",self.version);
    }
    return self;
}
-(NSString *)version{
    return [NSString stringWithFormat:@"%d",aes->GetVer()];
}
-(NSData *)encryptorStream:(NSData *)content{
    int length = (int)content.length + 24 + 16;
    char *contentChar = new char[length];
    memcpy(contentChar, [content bytes], length);
    int reulst1 = aes->XJK_Encrypt(1, contentChar, length, "", 1);
    return [NSData dataWithBytes:contentChar length:reulst1];
}

-(NSData *)decryptorStream:(NSData *)content{
    int length = (int)content.length;
    char *contentChar = new char[length];
    memcpy(contentChar, [content bytes], length);
    int result2 = aes->XJK_Decrypt(1, contentChar, length - 24, "", 0 , 1);
    return [NSData dataWithBytes:contentChar length:result2];
}

-(NSData *)decryptorLog:(NSString *)filePath{
    NSData *filpathData = [[filePath stringByAppendingString:@"\0"] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    int length = (int)(fileData.length + 16);
    char *contentChar = new char[length];
    memcpy(contentChar, [filpathData bytes], length);
    int result2 = aes->XJK_Decrypt(3, contentChar, length,"");
    return [NSData dataWithBytes:contentChar length:result2];
}

-(NSData *)assembleFileData:(NSData *)headData bodyData:(NSData *)bodyData{
    if (headData){
        Byte *headDataBytes = (Byte *)headData.bytes;
        headDataBytes[0]   = 0x04;  //文件加密版本
        headDataBytes[107] = 0x01;  //前端加密标志，0 = 未加密， 1 = 已加密。
        headDataBytes[108] = 0x00;  //服务器端密标志，0 = 未加密，1 = 已加密
        headDataBytes[109] = 0x02;  //文件加密模式，1 = 全文加密（文件头不加密），2 = 按大包加密（文件头和包头不加密），需要按大包加密加密时，把包的内容传给加密模块加密，修改包头长度，并修改文件头的byEncryptMode=2.
        NSUInteger trailLocation = headData.length + bodyData.length;
        headDataBytes[110] = trailLocation >> 24 & 0xff;  //写入文件尾
        headDataBytes[111] = trailLocation >> 16 & 0xff;
        headDataBytes[112] = trailLocation >> 8 & 0xff;
        headDataBytes[113] = trailLocation & 0xff;
    }
    
    Byte tailBytes[4];
    NSUInteger packageLocation = 151;
    tailBytes[0] = packageLocation >> 24 & 0xff;
    tailBytes[1] = packageLocation >> 16 & 0xff;
    tailBytes[2] = packageLocation >> 8 & 0xff;
    tailBytes[3] = packageLocation & 0xff;
    NSData *tailData = [NSData dataWithBytes:tailBytes length:4];
    
    NSMutableData *resultData = [NSMutableData new];
    if (headData){
      [resultData appendData:headData];
    }
    [resultData appendData:bodyData];
    [resultData appendData:tailData];
    
    return [resultData copy];
}
@end
