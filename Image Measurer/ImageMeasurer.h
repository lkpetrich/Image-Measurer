//
//  ImageMeasurer.h
//  Image Measurer
//
//  Created by Loren Petrich on 5/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ImageDisplayer.h"
#import "PositionReceiver.h"
#include "ScalingParameters.h"

// Entries in Measurements array:
// NSDictionary with these keys:
// NSNumber values: X, Y, R, G, B, A
// NSString value: Note

@interface ImageMeasurer : NSDocument <PositionReceiver> {
@private
    int Zoom; // Zoom amount is 2^(value)
    NSImage *Image; // What we want to measure
    NSMutableArray<NSMutableDictionary *> *Measurements;
    struct ScalingParameters SPs;
    BOOL BeepWhenMeasured;
    
    IBOutlet NSScrollView *ImageScroller;
    IBOutlet ImageDisplayer *ImageDisplay;
    
    IBOutlet NSPopUpButton *ZoomPopup;
    IBOutlet NSPopUpButton *ColorAvgPopup;
   
    IBOutlet NSTextField *ImageWidth;
    IBOutlet NSTextField *ImageHeight;
    
    IBOutlet NSTextField *Hover_OutX;
    IBOutlet NSTextField *Hover_OutY;
    IBOutlet NSTextField *Hover_OutXScld;
    IBOutlet NSTextField *Hover_OutYScld;
    
    IBOutlet NSTextField *Click_OutX;
    IBOutlet NSTextField *Click_OutY;
    IBOutlet NSTextField *Click_OutXScld;
    IBOutlet NSTextField *Click_OutYScld;
    
    IBOutlet NSTextField *Hover_OutR;
    IBOutlet NSTextField *Hover_OutG;
    IBOutlet NSTextField *Hover_OutB;
    IBOutlet NSTextField *Hover_OutA;
    
    IBOutlet NSTextField *Click_OutR;
    IBOutlet NSTextField *Click_OutG;
    IBOutlet NSTextField *Click_OutB;
    IBOutlet NSTextField *Click_OutA;
    
    IBOutlet NSTextField *NoteField;
    
    IBOutlet NSButton *ShowPointsCheckbox;
}

- (double)GetScaledX: (double)OrigX and:(double)OrigY;
- (double)GetScaledY: (double)OrigX and:(double)OrigY;
- (void)MeasurementsAltered:(NSNotification *)Notification;

- (IBAction)ZoomReset: (id)sender;
- (IBAction)ZoomIn: (id)sender;
- (IBAction)ZoomOut: (id)sender;
- (IBAction)ZoomSelected: (id) sender;
- (void)ZoomNewValue: (int)NewZoom;
- (void)UpdateImage;

- (IBAction)CopyImage: (id)sender;

- (IBAction)CopyMeasurement: (id)sender;

- (IBAction)ShowMeasurements: (id)sender;

- (IBAction)CopyMeasurements: (id)sender;
- (IBAction)ExportMeasurements: (id)sender;

- (IBAction)ToggleBeepWhenMeasured: (id)sender;

- (BOOL)GetShowPoints;
- (IBAction)ToggleShowPoints: (id) sender;

// Returns nil if absent
+ (NSImage *)GetClipboardImage;

@end
