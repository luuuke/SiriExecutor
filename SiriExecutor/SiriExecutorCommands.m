//
//  SiriExecutorCommands.m
//  SiriExecutor
//
//  Created by Lukas Werner on 16.04.15.
//
//

#import "SiriExecutorCommands.h"
#import "NSTask.h"

#define kDefaultsIdCString "de.ng.siriexecutor"
#define kPostNotificationNameCString "de.ng.siriexecutor.preferenceschanged"
#define kRePostNotificationName @"de.ng.siriexecutor.preferenceschanged.reposted"

#define LWLocalizedString(key) [bundle localizedStringForKey:(key) value:@"" table:nil]

static NSBundle* bundle;

static void settingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo){
	LWLog(@"settings changed, reposting notification");
	[[NSNotificationCenter defaultCenter] postNotificationName:kRePostNotificationName object:nil];
}

@interface SiriExecutorCommands ()
@property (strong, nonatomic) NSDictionary* settings;
@property (strong, nonatomic) NSMutableDictionary* mappedCommands;
@end

@implementation SiriExecutorCommands

-(instancetype)init{
	if(self=[super init]){
		LWLog(@"");
		bundle=[NSBundle bundleWithPath:@"/Library/AssistantPlusPlugins/SiriExecutor.assistantPlugin"];
		
		self.mappedCommands=[[NSMutableDictionary alloc] initWithCapacity:20];
		
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, settingsChanged, CFSTR(kPostNotificationNameCString), NULL, CFNotificationSuspensionBehaviorCoalesce);
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesChanged:) name:kRePostNotificationName object:nil];
		[self loadSettings];
	}
	return self;
}

- (BOOL)handleSpeech:(NSString *)text withTokens:(NSSet *)tokens withSession:(id<APSiriSession>)session{
	NSString* command;
	if((command=[self commandForSpeech:text andTokens:tokens])){
		LWLog(@"Handling command for speech: %@", text);
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[self executeCommand:command forSpeech:text withSession:session];
		});

		return YES;
	}
	return NO;
}

-(NSString*)commandForSpeech:(NSString*)text andTokens:(NSSet*)tokens{
	LWLog(@"searching command for speech: %@ and tokens: %@", text, tokens);
	
	__block NSString* command=nil;
	[self.mappedCommands enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		NSString* trigger=(NSString*)key;
		NSRegularExpression* regex=[[NSRegularExpression alloc] initWithPattern:trigger options:0 error:nil];
		NSTextCheckingResult* match=[regex firstMatchInString:text options:0 range:NSMakeRange(0, [text length])];
		
		NSInteger numberOfRanges=[match numberOfRanges];
		if(numberOfRanges > 0){
			command=(NSString*)obj;
			stop=YES;
		}
	}];
	
	return command;
}

-(void)executeCommand:(NSString*)command forSpeech:(NSString*)text withSession:(id<APSiriSession>)session{
	LWLog(@"executing \"%@\"", command);
	
	NSTask* task=[[NSTask alloc] init];
	task.launchPath=[[[NSProcessInfo processInfo] environment] objectForKey:@"SHELL"];
	task.arguments=@[@"-l", @"-c", command, @"--speech", text];
	[task setTerminationHandler:^(NSTask *terminatedTask){
		NSInteger status=[terminatedTask terminationStatus];
		LWLog(@"task terminationStatus: %i", status);
		if(status == 127){
			[session sendTextSnippet:LWLocalizedString(@"COMMAND_NOT_FOUND") temporary:NO scrollToTop:NO dialogPhase:@"Completion"];
		}else if(status != 0){
			[session sendTextSnippet:LWLocalizedString(@"EXECUTION_FAILED") temporary:NO scrollToTop:NO dialogPhase:@"Completion"];
		}
		[session sendRequestCompleted];
	}];
	
	@try{
		[task launch];
	}@catch(NSException *exception){
		LWLog(@"exception occured: %@", exception);
		[session sendTextSnippet:LWLocalizedString(@"EXECUTION_FAILED") temporary:NO scrollToTop:NO dialogPhase:@"Completion"];
		[session sendRequestCompleted];
	}
}

-(void)preferencesChanged:(NSNotification*)notification{
	[self loadSettings];
}

-(void)loadSettings{
	self.settings=(NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(CFPreferencesCopyKeyList(CFSTR(kDefaultsIdCString), kCFPreferencesCurrentUser, kCFPreferencesAnyHost), CFSTR(kDefaultsIdCString), kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
	
	LWLog(@"settings loaded: %@", self.settings);
	[self.mappedCommands removeAllObjects];
	for(int i=0; i<(self.settings.count/2 > 20 ? self.settings.count/2 : 20); i++){
		NSString* tempTrigger=[[self.settings objectForKey:[NSString stringWithFormat:@"trigger_%i", i]] lowercaseString];
		if(tempTrigger && [tempTrigger length] > 0 && ![self.mappedCommands objectForKey:tempTrigger]){
			NSString* tempCmd=[self.settings objectForKey:[NSString stringWithFormat:@"command_%i", i]];
			if(tempCmd){
				self.mappedCommands[tempTrigger]=tempCmd;
			}
		}
	}
	
	LWLog(@"mapped commands: %@", self.mappedCommands);
}

@end
