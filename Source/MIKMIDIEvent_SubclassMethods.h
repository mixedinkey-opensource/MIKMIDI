//
//  MIKMIDIEvent_SubclassMethods.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//


@interface MIKMIDIEvent ()

/**
 *  Registers a subclass of MIKMIDIEvent. Registered subclasses will be instantiated and returned
 *  by +[MIKMIDIEvent ] for events they support.
 *
 *  Typically this method should be called in the subclass's +load method.
 *
 *  @note If two subclasses support the same event type, as determined by calling +supportsMIDIEvent:
 *  which one is used is undefined.
 *
 *  @param subclass A subclass of MIKMIDIEvent.
 */
+ (void)registerSubclass:(Class)subclass;

/**
 *  Subclasses of MIKMIDIEvent must override this method, and return YES for any
 *  MIKMIDIEventType values they support. MIKMIDIEvent uses this method to determine which
 *  subclass to use to represent a particular MIDI event type.
 *
 *  @param type An MIKMIDIEventType value.
 *
 *  @return YES if the subclass supports type, NO otherwise.
 */
+ (BOOL)supportsMIKMIDIEventType:(MIKMIDIEventType)type;

/**
 *  The immutable counterpart class of the receiver.
 *
 *  @return A class object for the immutable counterpart class of the receiver, or self
 *  if the receiver is the immutable class in the pair.
 */
+ (Class)immutableCounterpartClass;

/**
 *  The mutable counterpart class of the receiver.
 *
 *  @return A class object for the mutable counterpart class of the receiver, or self
 *  if the receiver is the mutable class in the pair.
 */
+ (Class)mutableCounterpartClass;

/**
 *  Mutable subclasses of MIKMIDIEvent must override this method and return YES.
 *  MIKMIDIEvent itself implements this and returns NO, so *immutable* subclasses need
 *  not override this method.
 *
 *  @return YES if the receiver is a mutable MIKMIDIEvent subclass, NO otherwise.
 */
+ (BOOL)isMutable;

/**
 *  This is the property used internally by MIKMIDIEvent to store the raw data for
 *  a MIDI packet. It is essentially the mutable backing store for MIKMIDIEvent's
 *  data property. Subclasses may set it. When mutating it, subclasses should manually
 *  call -will/didChangeValueForKey for the internalData key path.
 */
@property (nonatomic, strong, readwrite) NSMutableData *internalData;

@property (nonatomic, readwrite) MusicTimeStamp timeStamp;

@property (nonatomic, readwrite) MusicEventType eventType;

@property (nonatomic, strong, readwrite) NSData *metaData;


/**
 *  Additional description string to be appended to basic description provided by
 *  -[MIKMIDIEvent description]. Subclasses of MIKMIDIEvent can override this
 *  to provide a additional description information.
 *
 *  @return A string to be appended to MIKMIDIEvent's basic description.
 */

- (NSString *)additionalEventDescription;

@end