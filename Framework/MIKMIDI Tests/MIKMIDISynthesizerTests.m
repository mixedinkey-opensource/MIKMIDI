//
//  MIKMIDISynthesizerTests.m
//  MIKMIDI Tests
//
//  Created by Andrew R Madsen on 1/14/20.
//  Copyright © 2020 Mixed In Key. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MIKMIDI/MIKMIDI.h>
#import <AVFoundation/AVFoundation.h>

@interface MIKMIDISynthesizerTests : XCTestCase

@end

@implementation MIKMIDISynthesizerTests

#if TARGET_OS_IPHONE
- (void)testStoppingIO
{
	NSError *error = nil;
	AVAudioSession *session = [AVAudioSession sharedInstance];
	XCTAssertTrue([session setActive:YES error:&error], @"%@", error);
	MIKMIDISynthesizer *synth = [[MIKMIDISynthesizer alloc] initWithError:&error];
	MIKMIDINoteEvent *note1 = [MIKMIDINoteEvent noteEventWithTimeStamp:0 note:60 velocity:127 duration:1 channel:0];
	NSMutableArray *noteMessages = [[MIKMIDICommand commandsFromNoteEvent:note1 clock:nil] mutableCopy];
	[synth handleMIDIMessages:noteMessages];
	XCTAssertNotNil(synth, @"%@", error);
	XCTAssertTrue([session setActive:NO error:&error], @"%@", error);
	NSLog(@"%@", error);
}
#endif //TARGET_OS_IPHONE

@end
