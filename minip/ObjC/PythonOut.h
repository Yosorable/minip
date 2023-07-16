//
//  PythonOut.h
//  minip
//
//  Created by ByteDance on 2023/7/14.
//

#ifndef PythonOut_h
#define PythonOut_h

#import <Foundation/Foundation.h>

@interface PythonOut : NSObject

@property (nonatomic, assign) NSString *stdoutmsg;

+ (instancetype)sharedInstance;
+ (void)pushStdout:(NSString*)msg;

@end

#endif /* PythonOut_h */
