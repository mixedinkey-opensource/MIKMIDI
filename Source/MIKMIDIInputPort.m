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
#import "MIKMIDISystemExclusiveCommand.h"

#if !__has_feature(objc_arc)
#error MIKMIDIInputPort.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIInputPort.m in the Build Phases for this target
#endif

@interface MIKMIDIConnectionTokenAndEventHandler : NSObject

- (instancetype)initWithConnectionToken:(NSString *)token eventHandler:(MIKMIDIEventHandlerBlock)eventHandler;

@property (nonatomic, strong, readonly) NSString *connectionToken;
@property (nonatomic, strong, readonly) MIKMIDIEventHandlerBlock eventHandler;

@end

@interface MIKMIDIInputPort ()

@property (nonatomic, strong) NSMutableArray *internalSources;
@property (nonatomic, strong, readwrite) MIKMapTableOf(MIKMIDIEndpoint *, NSMutableArray *) *handlerTokenPairsByEndpoint;

@property (nonatomic, strong) NSMutableArray *bufferedMSBCommands;
@property (nonatomic) dispatch_queue_t bufferedCommandQueue;


@property (nonatomic, strong) NSMutableData *coalescedSystemExclusiveData;
@property (nonatomic, assign, getter = isCoalescingSystemExclusiveCommand) BOOL coalescingSystemExclusiveCommand;
@property (nonatomic, assign) BOOL couldRequireSystemExclusiveCoalescing;

@end

@implementation MIKMIDIInputPort

- (instancetype)initWithClient:(MIDIClientRef)clientRef name:(NSString *)name
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
		_handlerTokenPairsByEndpoint = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
		_internalSources = [[NSMutableArray alloc] init];
		_coalesces14BitControlChangeCommands = YES;
        
        // Default, set externally via the device manager as a special case?
        _couldRequireSystemExclusiveCoalescing = YES;
        _coalescingSystemExclusiveCommand = NO;
        _coalescedSystemExclusiveData = [NSMutableData new];
		
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

- (id)connectToSource:(MIKMIDISourceEndpoint *)source
				error:(NSError **)error
		 eventHandler:(MIKMIDIEventHandlerBlock)eventHandler
{
	error = error ?: &(NSError *__autoreleasing){ nil };
	if (![self.connectedSources containsObject:source] &&
		![self connectToSource:source error:error]) {
		return nil;
	}
	
	NSString *uuidString = [self createNewConnectionToken];
	[self addConnectionToken:uuidString andEventHandler:eventHandler forSource:source];
	return uuidString;
}

- (void)disconnectConnectionForToken:(id)token
{
	MIKMIDISourceEndpoint *source = [self sourceEndpointForConnectionToken:token];
	if (!source) return; // Already disconnected?
	
	[self removeEventHandlerForConnectionToken:token source:source];
	
	NSArray *handlerPairs = [self.handlerTokenPairsByEndpoint objectForKey:source];
	if (![handlerPairs count]) {
		[self disconnectFromSource:source];
	}
}

#pragma mark - Private

#pragma mark Connection / Disconnection

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

#pragma mark Event Handler Management

- (NSString *)createNewConnectionToken
{
	NSString *uuidString = nil;
	do { // Very unlikely, but just to be safe
		CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
		uuidString = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
		CFRelease(uuid);
		MIKMIDIConnectionTokenAndEventHandler *existingPair = nil;
		for (NSArray *handlerPairs in self.handlerTokenPairsByEndpoint.objectEnumerator) {
			for (MIKMIDIConnectionTokenAndEventHandler *pair in handlerPairs) {
				if ([pair.connectionToken isEqualToString:uuidString]) {
					existingPair = pair;
					break;
				}
			}
		}
		if (!existingPair) break;
	} while (1);
	return uuidString;
}

- (void)addConnectionToken:(NSString *)connectionToken andEventHandler:(MIKMIDIEventHandlerBlock)eventHandler forSource:(MIKMIDISourceEndpoint *)source
{
	MIKMIDIConnectionTokenAndEventHandler *tokenHandlerPair =
	[[MIKMIDIConnectionTokenAndEventHandler alloc] initWithConnectionToken:connectionToken eventHandler:eventHandler];
	NSMutableArray *tokenPairs = [self.handlerTokenPairsByEndpoint objectForKey:source];
	if (!tokenPairs) {
		tokenPairs = [NSMutableArray array];
		[self.handlerTokenPairsByEndpoint setObject:tokenPairs forKey:source];
	}
	[tokenPairs addObject:tokenHandlerPair];
}

- (void)removeEventHandlerForConnectionToken:(NSString *)connectionToken source:(MIKMIDISourceEndpoint *)source
{
	NSMutableArray *handlerPairs = [self.handlerTokenPairsByEndpoint objectForKey:source];
	for (MIKMIDIConnectionTokenAndEventHandler *pair in [handlerPairs copy]) {
		if ([pair.connectionToken isEqual:connectionToken]) {
			[handlerPairs removeObject:pair];
		}
	}
}

- (MIKMIDISourceEndpoint *)sourceEndpointForConnectionToken:(NSString *)token
{
	for (MIKMIDISourceEndpoint *source in self.handlerTokenPairsByEndpoint) {
		NSArray *handlerPairs = [self.handlerTokenPairsByEndpoint objectForKey:source];
		for (MIKMIDIConnectionTokenAndEventHandler *handlerPair in handlerPairs) {
			if ([handlerPair.connectionToken isEqual:token]) {
				return source;
			}
		}
	}
	return nil;
}

#pragma mark Coaelescing

- (BOOL)commandIsPossibleMSBOf14BitCommand:(MIKMIDICommand *)command
{
	if (command.commandType != MIKMIDICommandTypeControlChange) return NO;
	
	MIKMIDIControlChangeCommand *controlChange = (MIKMIDIControlChangeCommand *)command;
	
	if (controlChange.isFourteenBitCommand) return NO; // Already coalesced
	return controlChange.controllerNumber < 32;
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

#pragma mark Command Handling

- (void)sendCommands:(NSArray *)commands toEventHandlersFromSource:(MIKMIDISourceEndpoint *)source
{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSArray *handlerPairs = [self.handlerTokenPairsByEndpoint objectForKey:source];
		for (MIKMIDIConnectionTokenAndEventHandler *handlerTokenPair in handlerPairs) {
			handlerTokenPair.eventHandler(source, commands);
		}
	});
}

#pragma mark - Coalesce System Exclusive (Roland D50)

- (NSString*)hexStrFromData:(Byte*)bytes length:(UInt16)length {
    NSMutableString* hex = [NSMutableString string];
    for(int i = 0; i < length; ++i)[hex appendFormat:@"%02X ", bytes[i]];
    return [hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (BOOL)shouldCoalesceSystemExclusiveCommand:(MIDIPacket *)packet{
    
    if (self.isCoalescingSystemExclusiveCommand) {
        return self.isCoalescingSystemExclusiveCommand;
    }
    
    if (packet->data[0] == 0xF0 && packet->data[packet->length - 1] != kMIKMIDISysexEndDelimiter){
        self.coalescingSystemExclusiveCommand = YES;
    } else {
        self.coalescingSystemExclusiveCommand = NO;
    }
    
    return self.coalescingSystemExclusiveCommand;
}

- (void)coalesceSystemExclusiveCommandData:(const MIDIPacketList *)pktList packet:(MIDIPacket *)packet{
    
    for (int i=0; i<pktList->numPackets; i++) {
        
        NSLog(@"MIKMIDI SYSEX  : Packet [%d] Packet Len [%d] Data [%@] ", i, packet->length, [self hexStrFromData:packet->data length:packet->length]);
        
        if (packet->length != 0) {
            [[self coalescedSystemExclusiveData] appendBytes:packet->data length:packet->length];
        }
        
        // TODO : Check the packet data for commands other than SYSEX and Command, if found bail on coalescing, corrupt SYSEX Recevied?
        
        packet = MIDIPacketNext(packet);
    }
}

- (BOOL)coalesceSystemExclusiveCommandIsComplete{
    if (self.coalescedSystemExclusiveData) {
        uint8_t *bytePtr = (uint8_t *)self.coalescedSystemExclusiveData.bytes;
        if (bytePtr[self.coalescedSystemExclusiveData.length - 1] == kMIKMIDISysexEndDelimiter) {
            return YES;
        }
    }
    return NO;
}

- (MIKMutableMIDISystemExclusiveCommand *)coalesceSystemExclusiveCommand{
    MIKMutableMIDISystemExclusiveCommand *cmd = [MIKMutableMIDISystemExclusiveCommand new];
    uint8_t *bytePtr = (uint8_t *)self.coalescedSystemExclusiveData.bytes;
    cmd.manufacturerID = bytePtr[1];
    // Remove duped F0 & F7 to provide a valid per MIKMIDI Sys Ex Packet
    cmd.sysexData = [[self coalescedSystemExclusiveData] subdataWithRange:NSMakeRange(2, self.coalescedSystemExclusiveData.length - 2)];
    [[self coalescedSystemExclusiveData] setData:[NSData dataWithBytes:NULL length:0]];
    self.coalescingSystemExclusiveCommand = NO;
    return cmd;
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
        
        if (self.couldRequireSystemExclusiveCoalescing) {
            if ([self shouldCoalesceSystemExclusiveCommand:packet]) {
                [self coalesceSystemExclusiveCommandData:pktList packet:packet];
                if ([self coalesceSystemExclusiveCommandIsComplete]) {
                    [self sendCommands:@[[self coalesceSystemExclusiveCommand]] toEventHandlersFromSource:source];
                }
                return;
            }
        }
        
		for (int i=0; i<pktList->numPackets; i++) {
            if (packet->length > 0) {                
                NSArray *commands = [MIKMIDICommand commandsWithMIDIPacket:packet];
                if (commands) [receivedCommands addObjectsFromArray:commands];
            }
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

+ (NSSet *)keyPathsForValuesAffectingConnectedSources { return [NSSet setWithObjects:@"internalSources", nil]; }

- (NSArray *)connectedSources { return [self.internalSources copy]; }

- (void)addInternalSourcesObject:(MIKMIDISourceEndpoint *)source
{
	[self.internalSources addObject:source];
}

- (void)removeInternalSourcesObject:(MIKMIDISourceEndpoint *)source
{
	[self.internalSources removeObject:source];
}

@synthesize bufferedCommandQueue = _bufferedCommandQueue;

- (void)setCommandsBufferQueue:(dispatch_queue_t)commandsBufferQueue
{
	MIKMIDI_GCD_RETAIN(commandsBufferQueue);
	MIKMIDI_GCD_RELEASE(_bufferedCommandQueue);
	_bufferedCommandQueue = commandsBufferQueue;
}

@end

#pragma mark -

@implementation MIKMIDIConnectionTokenAndEventHandler

- (instancetype)initWithConnectionToken:(NSString *)token eventHandler:(MIKMIDIEventHandlerBlock)eventHandler
{
	self = [super init];
	if (self) {
		_connectionToken = [token copy];
		_eventHandler = [eventHandler copy];
	}
	return self;
}

@end