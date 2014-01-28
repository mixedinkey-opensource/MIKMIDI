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

@interface MIKMIDIInputPort ()

@property (nonatomic, strong) NSMutableArray *internalSources;
@property (nonatomic, strong, readwrite) NSSet *eventHandlers;

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
		_eventHandlers = [[NSMutableSet alloc] init];
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

- (void)addEventHandler:(MIKMIDIEventHandlerBlock)eventHandler
{
	[self addEventHandlersObject:[eventHandler copy]];
}

- (void)removeEventHandler:(MIKMIDIEventHandlerBlock)eventHandler
{
	[self removeEventHandlersObject:[eventHandler copy]];
}

- (void)removeAllEventHandlers;
{
	NSSet *eventHandlers = [self eventHandlers];
	for (MIKMIDIEventHandlerBlock handler in eventHandlers) {
		[self removeEventHandler:handler];
	}
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
		
		NSMutableArray *commands = [NSMutableArray array];
		MIDIPacket *packet = (MIDIPacket *)pktList->packet;
		for (int i=0; i<pktList->numPackets; i++) {
			MIKMIDICommand *command = [MIKMIDICommand commandWithMIDIPacket:packet];
			if (command) [commands addObject:command];
			packet = MIDIPacketNext(packet);
		}
		
		if (![commands count]) return;
		
		if (self.coalesces14BitControlChangeCommands) {
			dispatch_sync(self.bufferedCommandQueue, ^{
				if ([self.bufferedMSBCommands count]) {
					[commands insertObject:[self.bufferedMSBCommands objectAtIndex:0] atIndex:0];
					[self.bufferedMSBCommands removeObjectAtIndex:0];
				}
			});
			commands = [[self commandsByCoalescingCommands:commands] mutableCopy];
			MIKMIDICommand *finalCommand = [commands lastObject];
			if ([self commandIsPossibleMSBOf14BitCommand:finalCommand]) {
				// Hold back and wait for a possible LSB command to come in.
				dispatch_sync(self.bufferedCommandQueue, ^{ [self.bufferedMSBCommands addObject:finalCommand]; });
				[commands removeLastObject];
				
				// Wait 4ms, then send the buffered command if it hasn't been coalesced (and therefore set to nil)
				dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_MSEC));
				dispatch_after(popTime, self.bufferedCommandQueue, ^(void){
					if (![self.bufferedMSBCommands containsObject:finalCommand]) return;
					[self.bufferedMSBCommands removeObject:finalCommand];
					[self sendCommands:@[finalCommand] toEventHandlersFromSource:source];
				});
			}
		}
		
		if (![commands count]) return;
		
		[self sendCommands:commands toEventHandlersFromSource:source];
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
	return [_eventHandlers copy];
}

- (void)setEventHandlers:(NSSet *)set
{
	if (set != _eventHandlers) {
		_eventHandlers = [set mutableCopy];
	}
}

- (void)addEventHandlersObject:(MIKMIDIEventHandlerBlock)eventHandler;
{
	[_eventHandlers addObject:eventHandler];
}

- (void)removeEventHandlersObject:(MIKMIDIEventHandlerBlock)eventHandler;
{
	[_eventHandlers removeObject:eventHandler];
}

@synthesize bufferedCommandQueue = _bufferedCommandQueue;

- (void)setCommandsBufferQueue:(dispatch_queue_t)commandsBufferQueue
{
	MIKMIDI_GCD_RETAIN(commandsBufferQueue);
	MIKMIDI_GCD_RELEASE(_bufferedCommandQueue);
	_bufferedCommandQueue = commandsBufferQueue;
}

@end
