//
//  SiriExecutor.h
//  SiriExecutor
//
//  Created by Lukas Werner on 16.04.15.
//
//

#import <Foundation/Foundation.h>
#import "AssistantPlusHeaders.h"

@interface SiriExecutor : NSObject <APPlugin>
-(id)initWithPluginManager:(id<APPluginManager>)manager;
@end
