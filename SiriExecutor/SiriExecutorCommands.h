//
//  SiriExecutorCommands.h
//  SiriExecutor
//
//  Created by Lukas Werner on 16.04.15.
//
//

#import <Foundation/Foundation.h>
#import "AssistantPlusHeaders.h"

@interface SiriExecutorCommands : NSObject <APPluginCommand>
- (BOOL)handleSpeech:(NSString *)text withTokens:(NSSet *)tokens withSession:(id<APSiriSession>)session;
@end
