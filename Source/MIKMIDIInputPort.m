//
//  MIKMIDIInputPort.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/8/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIPort_SubclassMethods.h"
#import <CoreMIDI/CoreMIDI.h>
#import "MIKMIDIInputPort.h"
#import "MIKMIDIPrivate.h"
#import "MIKMIDISourceEndpoint.h"
#import "MIKMIDICommand.h"
#import "MIKMIDIControlChangeCommand.h"
#import "MIKMIDIUtilities.h"

#if !__has_feature(objc_arc)
#error MIKMIDIInputPort.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIInputPort.m in the Build Phases for this target
#endif

@interface MIKMIDIInputPort ()

@property (nonatomic, strong) NSMutableArray *internalSources;
@property (nonatomic, strong, readwrite) NSMutableDictionary *eventHandlersByToken;

@property (nonatomic, strong) NSMutableArray *bufferedMSBCommands;
@property (nonatomic) dispatch_queue_t bufferedCommandQueue;

@end

@implementation MIKMIDIInputPort
{
	NSMutableSet *_eventHandlers;
}

- (id)initWithClient:(MIDIClientRef)clientRef name:(NSString *)name
{
	self = [super initWithClient:clientRef name:name];
	if (self) {
		name = [name length] ? name : @"Input port";
		MIDIPortRef port;
		OSStatus error = MIDIInputPortCreate(clientRef,
											 (__bridge CFStringRef)name,
											 MIKMIDIPortReadCallback,
											 (__bridge void *)self,
											 &port);
		if (error != noErr) { self = nil; return nil; }
		self.portRef = port; // MIKMIDIPort will take care of disposing of the port when needed
		_eventHandlersByToken = [[NSMutableDictionary alloc] init];
		_internalSources = [[NSMutableArray alloc] init];
		_coalesces14BitControlChangeCommands = YES;
		
		_bufferedCommandQueue = dispatch_queue_create("com.mixedinkey.MIKMIDI.MIKMIDIInputPort.bufferedCommandQueue", DISPATCH_QUEUE_SERIAL);
		dispatch_async(self.bufferedCommandQueue, ^{ self.bufferedMSBCommands = [[NSMutableArray alloc] init]; });
	}
	return self;
}

- (void)dealloc
{
	if (_bufferedCommandQueue) {
		MIKMIDI_GCD_RELEASE(_bufferedCommandQueue);
		_bufferedCommandQueue = NULL;
	}
}

#pragma mark - Public

- (BOOL)connectToSource:(MIKMIDISourceEndpoint *)source error:(NSError **)error;
{
	if ([self.connectedSources containsObject:source]) return YES;
	
	error = error ? error : &(NSError *__autoreleasing){ nil };
	OSStatus err = MIDIPortConnectSource(self.portRef, source.objectRef, (__bridge void *)source);
	if (err != noErr) {
		*error = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		return NO;
	}
	[self addInternalSourcesObject:source];
	return YES;
}

- (void)disconnectFromSource:(MIKMIDISourceEndpoint *)source
{
	OSStatus err = MIDIPortDisconnectSource(self.portRef, source.objectRef);
	if (err != noErr) NSLog(@"Error disconnecting MIDI source %@ from port %@", source, self);
	[self removeInternalSourcesObject:source];
}

- (id)addEventHandler:(MIKMIDIEventHandlerBlock)eventHandler; // Returns a token
{
	CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
	NSString *uuidString = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
	CFRelease(uuid);
	while ([self.eventHandlersByToken valueForKey:uuidString]) {
		// Very unlikely, but just to be safe
		uuid = CFUUIDCreate(kCFAllocatorDefault);
		uuidString = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
		CFRelease(uuid);
	}
	
	[self willChangeValueForKey:@"eventHandlers"];
	self.eventHandlersByToken[uuidString] = [eventHandler copy];
	[self didChangeValueForKey:@"eventHandlers"];
	return uuidString;
}

- (void)removeEventHandlerForToken:(id)token;
{
	[self willChangeValueForKey:@"eventHandlers"];
	[self.eventHandlersByToken removeObjectForKey:token];
	[self didChangeValueForKey:@"eventHandlers"];
}

- (void)removeAllEventHandlers;
{
	[self willChangeValueForKey:@"eventHandlers"];
	[self.eventHandlersByToken removeAllObjects];
	[self didChangeValueForKey:@"eventHandlers"];
}

#pragma mark - Private

- (BOOL)commandIsPossibleMSBOf14BitCommand:(MIKMIDICommand *)command
{
	if (command.commandType != MIKMIDICommandTypeControlChange) return NO;
	
	MIKMIDIControlChangeCommand *controlChange = (MIKMIDIControlChangeCommand *)command;
	
	if (controlChange.isFourteenBitCommand) return NO; // Already coalesced
	return controlChange.controllerNumber < 32;
}

- (BOOL)command:(MIKMIDICommand *)lsbCommand isPossibleLSBOfMSBCommand:(MIKMIDICommand *)msbCommand;
{
	if (lsbCommand.commandType != MIKMIDICommandTypeControlChange) return NO;
	if (msbCommand.commandType != MIKMIDICommandTypeControlChange) return NO;
	
	MIKMIDIControlChangeCommand *lsbControlChange = (MIKMIDIControlChangeCommand *)lsbCommand;
	MIKMIDIControlChangeCommand *msbControlChange = (MIKMIDIControlChangeCommand *)msbCommand;
	
	if (msbControlChange.controllerNumber > 31) return NO;
	if (lsbControlChange.controllerNumber < 32 || lsbControlChange.controllerNumber > 63) return NO;
	
	return (lsbControlChange.controllerNumber - msbControlChange.controllerNumber) == 32;
}

- (NSArray *)commandsByCoalescingCommands:(NSArray *)commands
{
	NSMutableArray *coalescedCommands = [commands mutableCopy];
	MIKMIDICommand *lastCommand = nil;
	for (MIKMIDICommand *command in commands) {
		MIKMIDIControlChangeCommand *coalesced =
		[MIKMIDIControlChangeCommand commandByCoalescingMSBCommand:(MIKMIDIControlChangeCommand *)lastCommand
													 andLSBCommand:(MIKMIDIControlChangeCommand *)command];
		if (coalesced) {
			[coalescedCommands removeObject:command];
			NSUInteger lastCommandIndex = [coalescedCommands indexOfObject:lastCommand];
			[coalescedCommands replaceObjectAtIndex:lastCommandIndex withObject:coalesced];
		}
		lastCommand = command;
	}
	return [coalescedCommands copy];
}

- (void)sendCommands:(NSArray *)commands toEventHandlersFromSource:(MIKMIDISourceEndpoint *)source
{
	dispatch_async(dispatch_get_main_queue(), ^{
		for (MIKMIDIEventHandlerBlock handler in self.eventHandlers) {
			handler(source, commands);
		}
	});
}

#pragma mark - Callbacks

// May be called on a background thread!
void MIKMIDIPortReadCallback(const MIDIPacketList *pktList, void *readProcRefCon, void *srcConnRefCon)
{
	@autoreleasepool {
		MIKMIDIInputPort *self = (__bridge MIKMIDIInputPort *)readProcRefCon;
		MIKMIDISourceEndpoint *source = (__bridge MIKMIDISourceEndpoint *)srcConnRefCon;
		
		NSMutableArray *receivedCommands = [NSMutableArray array];
		MIDIPacket *packet = (MIDIPacket *)pktList->packet;
		for (int i=0; i<pktList->numPackets; i++) {
			if (packet->length == 0) continue;
			NSArray *commands = [MIKMIDICommand commandsWithMIDIPacket:packet];
			if (commands) [receivedCommands addObjectsFromArray:commands];
			packet = MIDIPacketNext(packet);
		}
		
		if (![receivedCommands count]) return;
		
		if (self.coalesces14BitControlChangeCommands) {
			dispatch_sync(self.bufferedCommandQueue, ^{
				if ([self.bufferedMSBCommands count]) {
					[receivedCommands insertObject:[self.bufferedMSBCommands objectAtIndex:0] atIndex:0];
					[self.bufferedMSBCommands removeObjectAtIndex:0];
				}
			});
			receivedCommands = [[self commandsByCoalescingCommands:receivedCommands] mutableCopy];
			MIKMIDICommand *finalCommand = [receivedCommands lastObject];
			if ([self commandIsPossibleMSBOf14BitCommand:finalCommand]) {
				// Hold back and wait for a possible LSB command to come in.
				dispatch_sync(self.bufferedCommandQueue, ^{ [self.bufferedMSBCommands addObject:finalCommand]; });
				[receivedCommands removeLastObject];
				
				// Wait 4ms, then send the buffered command if it hasn't been coalesced (and therefore set to nil)
				dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_MSEC));
				dispatch_after(popTime, self.bufferedCommandQueue, ^(void){
					if (![self.bufferedMSBCommands containsObject:finalCommand]) return;
					[self.bufferedMSBCommands removeObject:finalCommand];
					[self sendCommands:@[finalCommand] toEventHandlersFromSource:source];
				});
			}
		}
		
		if (![receivedCommands count]) return;
		
		[self sendCommands:receivedCommands toEventHandlersFromSource:source];
	}
}

#pragma mark - Properties

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"connectedSources"]) {
		keyPaths = [keyPaths setByAddingObject:@"internalSources"];
	}
	
	return keyPaths;
}

- (NSArray *)connectedSources { return [self.internalSources copy]; }

- (void)addInternalSourcesObject:(MIKMIDISourceEndpoint *)source
{
	[self.internalSources addObject:source];
}

- (void)removeInternalSourcesObject:(MIKMIDISourceEndpoint *)source
{
	[self.internalSources removeObject:source];
}

- (NSSet *)eventHandlers
{
	return [NSSet setWithArray:[self.eventHandlersByToken allValues]];
}

@synthesize bufferedCommandQueue = _bufferedCommandQueue;

- (void)setCommandsBufferQueue:(dispatch_queue_t)commandsBufferQueue
{
	MIKMIDI_GCD_RETAIN(commandsBufferQueue);
	MIKMIDI_GCD_RELEASE(_bufferedCommandQueue);
	_bufferedCommandQueue = commandsBufferQueue;
}

@end
