//
//  PythonOut.m
//  minip
//
//  Created by ByteDance on 2023/7/14.
//

#import <Foundation/Foundation.h>
#import "PythonOut.h"

static PythonOut *pythonOutInstance = nil;

@implementation PythonOut

+ (instancetype)sharedInstance {
    if (!pythonOutInstance) {
        pythonOutInstance = [[self alloc] init];
        pythonOutInstance.stdoutmsg = @"";
    }
    return pythonOutInstance;
}


+ (void)pushStdout:(NSString *)msg {
    if (!msg) {
        return;
    }
    [[self sharedInstance].stdoutmsg stringByAppendingString:msg];
}

@end
