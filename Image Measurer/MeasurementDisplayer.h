//
//  MeasurementDisplayer.h
//  Image Measurer
//
//  Created by Loren Petrich on 5/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "ScalingParameters.h"

@interface MeasurementDisplayer : NSWindowController
{
@private
    NSMutableArray<NSMutableDictionary *> *Measurements; // Get from parent
    NSMutableArray *SPDisplay; // Defined here
    
    IBOutlet NSArrayController *MeasController;
    IBOutlet NSArrayController *SPDController;
    
    IBOutlet NSPopUpButton *ScalingType;
    
    IBOutlet NSButton *UseExplicitLength;
    IBOutlet NSTextField *ExplicitLength;
    
@public
    struct ScalingParameters *SPs;
}

- (id)initWithWindowNibName:(NSString *)windowNibName;
- (void)dealloc;

- (void)MeasurementsAltered:(NSNotification *)Notification;

- (void)LoadScalingParameters;
- (void)SaveScalingParameters;

- (IBAction)UseScalingType: (id)sender;
- (IBAction)UseSelectionInSPs: (id)sender;
- (IBAction)Rescale: (id)sender;

- (IBAction)copy: (id)sender;
- (IBAction)ExportMeasurements: (id)sender;
- (IBAction)DeleteSelection: (id)sender;

@property (retain) NSMutableArray<NSMutableDictionary *> *Measurements;
@property (retain) NSMutableArray *SPDisplay;

@end
