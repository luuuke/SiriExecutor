//
//  SiriExecutor.m
//  SiriExecutor
//
//  Created by Lukas Werner on 16.04.15.
//
//

#import "SiriExecutor.h"
#import "SiriExecutorCommands.h"

@implementation SiriExecutor
-(instancetype)initWithPluginManager:(id<APPluginManager>)manager{
	if (self = [super init]) {
		[manager registerCommand:[SiriExecutorCommands class]];
	}
	return self;
}
@end
