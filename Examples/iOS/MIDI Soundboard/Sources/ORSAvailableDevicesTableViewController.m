//
//  ORSAvailableDevicesTableViewController.m
//  MIDI Soundboard
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Open Reel Software. All rights reserved.
//

#import "ORSAvailableDevicesTableViewController.h"
#import "MIKMIDI.h"

@implementation ORSAvailableDevicesTableViewController

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.deviceManager addObserver:self forKeyPath:@"availableDevices" options:NSKeyValueObservingOptionInitial context:NULL];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[self.deviceManager addObserver:self forKeyPath:@"availableDevices" options:NSKeyValueObservingOptionInitial context:NULL];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"availableDevices"]) {
		[self.tableView reloadData];
	}
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger result = [[[self deviceManager] availableDevices] count];
	NSLog(@"%s %li", __PRETTY_FUNCTION__, (long)result);
	return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *result = [tableView dequeueReusableCellWithIdentifier:@"AvailableDeviceTableViewCell" forIndexPath:indexPath];
	result.textLabel.text = [self.deviceManager.availableDevices[indexPath.row] name];
	return result;
}

#pragma mark - UITableViewDelegate


#pragma mark - Properties

- (MIKMIDIDeviceManager *)deviceManager { return [MIKMIDIDeviceManager sharedDeviceManager]; }

@end
