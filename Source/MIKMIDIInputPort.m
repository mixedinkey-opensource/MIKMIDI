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
#import "MIKMIDISourceEndpoint.h"
#import "MIKMIDICommand.h"

@interface MIKMIDIInputPort ()

@property (nonatomic, strong) NSMutableArray *internalSources;
@property (nonatomic, strong, readwrite) NSSet *eventHandlers;

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
		self.eventHandlers = [[NSMutableSet alloc] init];
		self.internalSources = [[NSMutableArray alloc] init];
	}
	return self;
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
				
		dispatch_async(dispatch_get_main_queue(), ^{
			for (MIKMIDIEventHandlerBlock handler in self.eventHandlers) {
				handler(source, commands);
			}
		});
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

@end
