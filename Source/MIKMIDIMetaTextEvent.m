//
//  MIKMIDIMetadataTextEvent.m
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaTextEvent.h"
#import "MIKMIDIEvent_SubclassMethods.h"
#import "MIKMIDIUtilities.h"

#if !__has_feature(objc_arc)
#error MIKMIDIMetaTextEvent.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIMappingManager.m in the Build Phases for this target
#endif

@implementation MIKMIDIMetaTextEvent

+ (void)load { [MIKMIDIEvent registerSubclass:self]; }
+ (BOOL)supportsMIKMIDIEventType:(MIKMIDIEventType)type { return type == MIKMIDIEventTypeMetaText; }
+ (Class)immutableCounterpartClass { return [MIKMIDIMetaTextEvent class]; }
+ (Class)mutableCounterpartClass { return [MIKMutableMIDIMetaTextEvent class]; }
+ (BOOL)isMutable { return NO; }

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"string"]) {
        [keyPaths setByAddingObject:@"metaData"];
    }
    return keyPaths;
}

- (NSString *)string
{
    return [[NSString alloc] initWithData:self.metaData encoding:NSUTF8StringEncoding];
}

- (void)setString:(NSString *)string
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
    [self setMetaData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (NSString *)additionalEventDescription
{
    return [NSString stringWithFormat:@"Metadata Type: 0x%02x, String: %@", self.metadataType, self.string];
}

@end


@implementation MIKMutableMIDIMetaTextEvent

+ (BOOL)isMutable { return YES; }

@dynamic string;

@end