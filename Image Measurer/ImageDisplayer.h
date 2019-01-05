//
//  ImageDisplayer.h
//  Image Measurer
//
//  Created by Loren Petrich on 5/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PositionReceiver.h"

// For catching mouse clicks -- transmit clicks captured in the image pane to the main object

@interface ImageDisplayer : NSImageView {
@private
    id <PositionReceiver> Receiver;
    int Zoom; // Need this to select which sort of interpolation
    
    NSTrackingArea *Tracker; // For getting the moused-over position

    NSArray<NSMutableDictionary *> *Measurements; // Get from parent
    BOOL ShowMeasurements; // Whether or not to show them on the image
}

- (void)SetPositionReceiver: (id <PositionReceiver>)Receiver_;
- (void)SetZoom: (int)Zoom_;
- (void)SetShowMeas: (BOOL)ShowMeasurements_;

- (void)UpdateTracker;

@property (retain) NSArray<NSMutableDictionary *> *Measurements;

@end
