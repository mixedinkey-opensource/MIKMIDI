//
//  MIKMIDIMapping.h
//  Energetic
//
//  Created by Andrew Madsen on 3/15/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MIKMIDICommand.h"
#import "MIKMIDIResponder.h"

/**
 *  Bit-mask constants used to specify MIDI responder types for mapping.
 *  Multiple responder types can be specified by ORing them together.
 *  @see -[MIKMIDIMappableResponder MIDIResponderTypeForCommandIdentifier:]
 */
typedef NS_OPTIONS(NSUInteger, MIKMIDIResponderType){
	/**
	 *  Responder does not have a type. Cannot be mapped.
	 */
	MIKMIDIResponderTypeNone = 0,
	
	/**
	 *  Type for a MIDI responder that can handle messages from a hardware absolute
	 *  knob or slider. That is, one that sends control change messages with an absolute value
	 *  depending on its position.
	 */
	MIKMIDIResponderTypeAbsoluteSliderOrKnob = 1 << 0,
	
	/**
	 *  Type for a MIDI responder that can handle messages from a hardware relative
	 *  knob. That is, a knob that sends a message for each "tick", and whose value
	 *  depends on the direction (and possibly velocity) of the knob, rather than its
	 *  absolute position.
	 */
	MIKMIDIResponderTypeRelativeKnob = 1 << 1,
	
	/**
	 *  Type for a MIDI responder that can handle messages from a hardware turntable-like
	 *  jog wheel. These are relative knobs, but typically have *much* higher resolution than
	 *  a small relative knob. They may also have a touch/pressure sensitive top to detect when
	 *  the user is touching, but not turning the wheel.
	 */
	MIKMIDIResponderTypeTurntableKnob = 1 << 2,
	
	/**
	 *  Type for a MIDI responder that can handle messages from a hardware relative knob that
	 *  sends messages to simulate an absolute knob. Relative knobs on (at least) Native Instruments
	 *  controllers can be configured to send messages like an absolute knob. This can pose the problem
	 *  of the knob continuing to turn past its limits (0 and 127) without additional messages being sent.
	 *  These knobs can and will be mapped as a regular absolute knob for responders that include MIKMIDIResponderTypeAbsoluteSliderOrKnob
	 *  but *not* MIKMIDIResponderTypeRelativeAbsoluteKnob in the type returned by -MIDIResponderTypeForCommandIdentifier:
	 */
	MIKMIDIResponderTypeRelativeAbsoluteKnob = 1 << 3,
	
	/**
	 *  Type for a MIDI responder that can handle messages from a hardware button that sends a message when
	 *  pressed down, and another message when released.
	 */
	MIKMIDIResponderTypePressReleaseButton = 1 << 4,
	
	/**
	 *  Type for a MIDI responder that can handle messages from a hardware button that only sends a single
	 *  message when pressed down, without sending a corresponding message upon release.
	 */
	MIKMIDIResponderTypePressButton = 1 << 5,
	
	/**
	 *  Convenience type for a responder that can handle messages from any type of knob.
	 */
	MIKMIDIResponderTypeKnob = (MIKMIDIResponderTypeAbsoluteSliderOrKnob | MIKMIDIResponderTypeRelativeKnob | \
								MIKMIDIResponderTypeTurntableKnob | MIKMIDIResponderTypeRelativeAbsoluteKnob),
	
	/**
	 *  Convenience type for a responder that can handle messages from any type of button.
	 */
	MIKMIDIResponderTypeButton = (MIKMIDIResponderTypePressButton | MIKMIDIResponderTypePressReleaseButton),
	
	/**
	 *  Convenience type for a responder that can handle messages from any kind of control.
	 */
	MIKMIDIResponderTypeAll = NSUIntegerMax,
};

@protocol MIKMIDIMappableResponder;

@class MIKMIDIChannelVoiceCommand;
@class MIKMIDIMappingItem;

/**
 *  Overview
 *  --------
 *
 *  MIKMIDIMapping includes represents a complete mapping between a particular hardware controller,
 *  and an application's functionality. Primarily, it acts as a container for MIKMIDIMappingItems,
 *  each of which specifies the mapping for a single hardware control.
 *
 *  MIKMIDIMapping can be stored on disk using a straightforward XML format, and includes methods
 *  to load and write these XML files. Currently this is only implemented on OS X (see 
 *  https://github.com/mixedinkey-opensource/MIKMIDI/issues/2 ).
 *
 *  Another class, MIKMIDIMappingManager can be used to manage both application-supplied, and
 *  user customized mappings.
 *
 *  Creating Mappings
 *  -----------------
 *
 *  MIKMIDIMappings can be generated manually, as the XML format is fairly straightforward.
 *  MIKMIDI also includes powerful functionality to assist in creating a way for users to
 *  easily create their own mappings using a "MIDI learning" interface.
 *
 *  Using Mappings
 *  --------------
 *  
 *  MIKMIDI does not include built in support for automatically routing messages using a mapping,
 *  so a user of MIKMIDI must write some code to make this happen. Typically, this is done by having
 *  a single controller in the application be responsible for receiving all incoming MIDI messages.
 *  When a MIDI message is received, it can query the MIDI mapping for the mapping item correspoding
 *  to the incomding message, then send the command to the mapped responder. Example code for this scenario:
 *
 *  	- (void)connectToMIDIDevice:(MIKMIDIDevice *)device {
 *  		MIKMIDIDeviceManager *manager = [MIKMIDIDeviceManager sharedDeviceManager];
 *  		BOOL success = [manager connectInput:source error:error eventHandler:^(MIKMIDISourceEndpoint *source, NSArray *commands) {
 *  			for (MIKMIDICommand *command in commands) {
 *  				[self routeIncomingMIDICommand:command];
 *  			}
 *  		}];
 *
 *  		if (success) self.device = device;
 *  	}
 *
 *  	- (void)routeIncomingMIDICommand:
 *  	{
 *  	    MIKMIDIDevice *controller = self.device; // The connected MIKMIDIDevice instance
 *  		MIKMIDIMapping *mapping = [[[MIKMIDIMappingManager sharedManager] mappingsForControllerName:controller.name] anyObject];
 *  		MIKMIDIMappingItem *mappingItem = [[self.MIDIMapping mappingItemsForMIDICommand:command] anyObject];
 *  		if (!mappingItem) return;
 *
 *  		id<MIKMIDIResponder> responder = [NSApp MIDIResponderWithIdentifier:mappingItem.MIDIResponderIdentifier];
 *  		if ([responder respondsToMIDICommand:command]) {
 *  			[responder handleMIDICommand:command];
 *  		}
 *  	}
 *
 *  @see MIKMIDIMappingManager
 *  @see MIKMIDIMappingGenerator
 */
@interface MIKMIDIMapping : NSObject <NSCopying>

/**
 *  Initializes and returns an MIKMIDIMapping object created from the XML file at url.
 *
 *  @note This method is currently only available on OS X. See https://github.com/mixedinkey-opensource/MIKMIDI/issues/2
 *
 *  @param url   An NSURL for the file to be read.
 *  @param error If an error occurs, upon returns contains an NSError object that describes the problem. If you are not interested in possible errors, you may pass in NULL.
 *
 *  @return An initialized MIKMIDIMapping instance, or nil if an error occurred.
 */
- (instancetype)initWithFileAtURL:(NSURL *)url error:(NSError **)error;

/**
 *  Initializes and returns an MIKMIDIMapping object created from the XML file at url.
 *
 *  @note This method is currently only available on OS X. See https://github.com/mixedinkey-opensource/MIKMIDI/issues/2
 *
 *  @param url   An NSURL for the file to be read.
 *
 *  @return An initialized MIKMIDIMapping instance, or nil if an error occurred.
 *
 *  @see -initWithFileAtURL:error:
 */
- (instancetype)initWithFileAtURL:(NSURL *)url;

#if !TARGET_OS_IPHONE
/**
 *  Returns an NSXMLDocument representation of the receiver.
 *  The XML document returned by this method can be written to disk.
 *
 *  @note This method is currently only available on OS X. -XMLStringRepresentation can be used on iOS.
 *  @deprecated This method is deprecated on OS X. Use -XMLStringRepresentation instead.
 *
 *  @return An NSXMLDocument representation of the receiver.
 *
 *  @see -writeToFileAtURL:error:
 */
- (NSXMLDocument *)XMLRepresentation DEPRECATED_ATTRIBUTE;

#endif

/**
 *  Returns an NSString instance containing an XML representation of the receiver.
 *  The XML document returned by this method can be written to disk.
 *
 *  @return An NSString containing an XML representation of the receiver.
 *
 *  @see -writeToFileAtURL:error:
 */
- (NSString *)XMLStringRepresentation;

/**
 *  Writes the receiver as an XML file to the specified URL.
 *
 *  @note This method is currently only available on OS X. See https://github.com/mixedinkey-opensource/MIKMIDI/issues/2
 *
 *  @param fileURL The URL for the file to be written.
 *  @param error   If an error occurs, upon returns contains an NSError object that describes the problem. If you are not interested in possible errors, you may pass in NULL.
 *
 *  @return YES if writing the mapping to a file succeeded, NO if an error occurred.
 */
- (BOOL)writeToFileAtURL:(NSURL *)fileURL error:(NSError **)error;

/**
 *  The mapping items that map controls to responder. 
 *
 *  This can be used to get mapping items for all commands supported by a responder. It is
 *  also possible for multiple physical controls to be mapped to a single command on the same responder.
 *
 *  @param responder An object that coforms to the MIKMIDIMappableResponder protocol.
 *
 *  @return An NSSet containing MIKMIDIMappingItems for responder, or an empty set if none are found.
 */
- (NSSet *)mappingItemsForMIDIResponder:(id<MIKMIDIMappableResponder>)responder;

/**
 *  The mapping items that map controls to a specific command identifier supported by a MIDI responder.
 *
 *  @param identifier An NSString containing one of the responder's supported command identifiers.
 *  @param responder  An object that coforms to the MIKMIDIMappableResponder protocol.
 *
 *  @return An NSSet containing MIKMIDIMappingItems for the responder and command identifer, or an empty set if none are found.
 *
 *  @see -[<MIKMIDIMappableResponder> commandIdentifiers]
 */
- (NSSet *)mappingItemsForCommandIdentifier:(NSString *)identifier responder:(id<MIKMIDIMappableResponder>)responder;

/**
 *  The mapping items for a particular MIDI command (corresponding to a physical control).
 *
 *  This method is typically used to route incoming messages from a controller to the correct mapped responder.
 *
 *  @param command An an instance of MIKMIDICommand.
 *
 *  @return An NSSet containing MIKMIDIMappingItems for command, or an empty set if none are found.
 */
- (NSSet *)mappingItemsForMIDICommand:(MIKMIDIChannelVoiceCommand *)command;

/**
 *  The name of the MIDI mapping. Currently only used to determine the (default) file name when saving a mapping to disk.
 *  If not set, this defaults to the controllerName.
 */
@property (nonatomic, copy) NSString *name;

/**
 *  The name of the hardware controller this mapping is for. This should (typically) be the same as the name returned by
 *  calling -[MIKMIDIDevice name] on the controller's MIKMIDIDevice instance.
 */
@property (nonatomic, copy) NSString *controllerName;

/**
 *  YES if the receiver was loaded from the application bundle, NO if loaded from user-accessible folder (e.g. Application Support)
 */
@property (nonatomic, readonly, getter = isBundledMapping) BOOL bundledMapping;

/**
 *  Optional additional key value pairs, which will be saved as attributes in this mapping's XML representation. Keys and values must be NSStrings.
 */
@property (nonatomic, copy) NSDictionary *additionalAttributes;

/**
 *  All mapping items this mapping contains.
 */
@property (nonatomic, readonly) NSSet *mappingItems;

/**
 *  Add a single mapping item to the receiver.
 *
 *  @param mappingItem An MIKMIDIMappingItem instance.
 */
- (void)addMappingItemsObject:(MIKMIDIMappingItem *)mappingItem;

/**
 *  Add multiple mapping items to the receiver.
 *
 *  @param mappingItems An NSSet containing mappings to be added.
 */
- (void)addMappingItems:(NSSet *)mappingItems;

/**
 *  Remove a mapping item from the receiver.
 *
 *  @param mappingItem An MIKMIDIMappingItem instance.
 */
- (void)removeMappingItemsObject:(MIKMIDIMappingItem *)mappingItem;

/**
 *  Remove multiple mapping items from the receiver.
 *
 *  @param mappingItems An NSSet containing mappings to be removed.
 */
- (void)removeMappingItems:(NSSet *)mappingItems;

@end

/**
 *  MIKMIDIMappingItem contains information about a mapping between a physical MIDI control,
 *  and a single command supported by a particular MIDI responder object.
 *
 *  MIKMIDIMappingItem specifies the command type, and MIDI channel for the commands sent by the
 *  mapped physical control along with the control's interaction type (e.g. knob, turntable, button, etc.).
 *  It also specifies the (software) MIDI responder to which incoming commands from the mapped control
 *  should be routed.
 *
 */
@interface MIKMIDIMappingItem : NSObject <NSCopying>

/**
 *  Creates and initializes a new MIKMIDIMappingItem instance.
 *
 *  @param MIDIResponderIdentifier The identifier for the MIDI responder object being mapped.
 *  @param commandIdentifier       The identifer for the command to be mapped.
 *
 *  @return An initialized MIKMIDIMappingItem instance.
 */
- (instancetype)initWithMIDIResponderIdentifier:(NSString *)MIDIResponderIdentifier andCommandIdentifier:(NSString *)commandIdentifier;

/**
 *  Returns an NSString instance containing an XML representation of the receiver.
 *  The XML document returned by this method can be written to disk.
 *
 *  @return An NSString containing an XML representation of the receiver.
 *
 *  @see -writeToFileAtURL:error:
 */
- (NSString *)XMLStringRepresentation;

// Properties

/**
 *  The MIDI identifier for the (software) responder object being mapped. This is the same value as returned by calling -MIDIIdentifier
 *  on the responder to be mapped.
 *
 *  This value can be used to retrieve the MIDI responder to which this mapping refers at runtime using
 *  -[NS/UIApplication MIDIResponderWithIdentifier].
 */
@property (nonatomic, readonly) NSString *MIDIResponderIdentifier;

/**
 *  The identifier for the command mapped by this mapping item. This will be one of the identifier's returned
 *  by the mapped responder's -commandIdentifiers method.
 */
@property (nonatomic, readonly) NSString *commandIdentifier;

/**
 *  The interaction type for the physical control mapped by this item. This can be used to determine
 *  how to interpret the incoming MIDI messages mapped by this item.
 */
@property (nonatomic) MIKMIDIResponderType interactionType;

/**
 *  If YES, value decreases as slider/knob goes left->right or top->bottom. 
 *  This property is currently only relevant for knobs and sliders, and has no meaning for buttons or other responder types.
 */
@property (nonatomic, getter = isFlipped) BOOL flipped;

/**
 *  The MIDI channel upon which commands are sent by the control mapped by this item.
 */
@property (nonatomic) NSInteger channel;

/**
 *  The MIDI command type of commands sent by the control mapped by this item.
 */
@property (nonatomic) MIKMIDICommandType commandType;

/**
 *  The control number of the control mapped by this item.
 *  This is either the note number (for Note On/Off commands) or controller number (for control change commands).
 */
@property (nonatomic) NSUInteger controlNumber;

/**
 *  Optional additional key value pairs, which will be saved as attributes in this item's XML representation. Keys and values must be NSStrings.
 */
@property (nonatomic, copy) NSDictionary *additionalAttributes;

@end

/**
 *  This protocol defines methods that that must be implemented by MIDI responder objects to be mapped
 *  using MIKMIDIMappingGenerator, and to whom MIDI messages will selectively be routed using a MIDI mapping
 *  during normal operation.
 */
@protocol MIKMIDIMappableResponder <MIKMIDIResponder>

@required
/**
 *  The list of identifiers for all commands supported by the receiver.
 *
 *  A MIDI responder may want to handle incoming MIDI message from more than one control. For example, a view displaying
 *  a list of songs may want to support commands for browsing up and down the list with buttons, or with a knob, as well as a button
 *  to load the selected song. These commands would be for example, KnobBrowse, BrowseUp, BrowseDown, and Load. This way, multiple physical
 *  controls can be mapped to different functions of the same MIDI responder.
 *
 *  @return An NSArray containing NSString identifers for all MIDI mappable commands supported by the receiver.
 */
- (NSArray *)commandIdentifiers;

/**
 *  The MIDI responder types the receiver will allow to be mapped to the command specified by commandID.
 *
 *  In the example given for -commandIdentifers, the "KnobBrowse" might be mappable to any physical knob,
 *  while BrowseUp, BrowseDown, and Load are mappable to buttons. The responder would return MIKMIDIResponderTypeKnob
 *  for @"KnobBrowse" while returning MIKMIDIResponderTypeButton for the other commands.
 *
 *  @param commandID A command identifier string.
 *
 *  @return A MIKMIDIResponderType bitfield specifing one or more responder type(s).
 *
 *  @see MIKMIDIResponderType
 */
- (MIKMIDIResponderType)MIDIResponderTypeForCommandIdentifier:(NSString *)commandID; // Optional. If not implemented, MIKMIDIResponderTypeAll will be assumed.

@optional

/**
 *  Whether the physical control mapped to the commandID in the receiver should
 *  be illuminated, or not.
 *
 *  Many hardware MIDI devices, e.g. DJ controllers, have buttons that can light
 *  up to show state for the associated function. For example, the play button
 *  could be illuminated when the software is playing. This method allows mapped
 *  MIDI responder objects to communicate the desired state of the physical control
 *  mapped to them.
 *
 *  Currently MIKMIDI doesn't provide automatic support for actually updating
 *  physical LED status. This must be implemented in application code. For most devices,
 *  this can be accomplished by sending a MIDI message _to_ the device. The MIDI message
 *  should identical to the message that the relevant control sends when pressed, with
 *  a non-zero value to illumniate the control, or zero to turn illumination off.
 *
 *  @param commandID The commandID for which the associated illumination state is desired.
 *
 *  @return YES if the associated control should be illuminated, NO otherwise.
 */
- (BOOL)illuminationStateForCommandIdentifier:(NSString *)commandID;

@end
