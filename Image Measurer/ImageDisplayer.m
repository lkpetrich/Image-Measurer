//
//  ImageDisplayer.m
//  Image Measurer
//
//  Created by Loren Petrich on 5/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ImageDisplayer.h"

static void PaintRect(CGFloat x, CGFloat y, CGFloat w, CGFloat h)
{
    NSRectFill(NSMakeRect(x,y,w,h));
}

static void PaintRectOp(CGFloat x, CGFloat y, CGFloat w, CGFloat h, NSCompositingOperation op)
{
    NSRectFillUsingOperation(NSMakeRect(x,y,w,h),op);
}

@implementation ImageDisplayer

@synthesize Measurements;

- (id)init
{
    self = [super init];
    if (self) {
        // Init
        Tracker = nil;
    }
    return self;
}


- (void)SetPositionReceiver: (id <PositionReceiver>)Receiver_
{
    Receiver = Receiver_;
}


- (void)awakeFromNib
{
    [self UpdateTracker];
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    [self UpdateTracker];
}

- (void)UpdateTracker
{
    if (Tracker) [self removeTrackingArea:Tracker];
    
    Tracker = [[NSTrackingArea alloc] initWithRect:[self visibleRect]
                                           options:NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingInVisibleRect | NSTrackingActiveAlways
                                             owner:self userInfo:nil];
    [self addTrackingArea:Tracker];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    NSPoint WindowLocation = [theEvent locationInWindow];
    [Receiver ReceivePosition:WindowLocation Tag:@"Hover"];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    NSPoint WindowLocation = [theEvent locationInWindow];
    [Receiver ReceivePosition:WindowLocation Tag:@"Hover"];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint WindowLocation = [theEvent locationInWindow];
    [Receiver ReceivePosition:WindowLocation Tag:@"Click"];
}

// So the image will appear in the top left rather than in the bottom left
- (BOOL)isFlipped
{
    return YES;
}


- (void)SetZoom: (int)Zoom_
{
    Zoom = Zoom_;
}

- (void)SetShowMeas: (BOOL)ShowMeasurements_
{
    ShowMeasurements = ShowMeasurements_;
}


- (void)DrawContents:(NSRect)rect {
    
    // Draw the image first
    [super drawRect: rect];
    
    // Draw the measured points
    if (!ShowMeasurements) return;
    
    // Get the view's rectangle in its coordinates
    NSRect Bds = self.bounds;
    
    // Get its context for drawing into
    NSGraphicsContext* Ctxt = [NSGraphicsContext currentContext];
    
    // Colors for the markers
    NSColor *InnerColor = [NSColor colorWithWhite:0 alpha:1];
    NSColor *OuterColor = [NSColor colorWithWhite:1 alpha:0.5];
    NSCompositingOperation OutOp = NSCompositeSourceOver;
    
    // Marker length
    int MkrLen = 3;
    
    [Ctxt saveGraphicsState];
    
    for (NSDictionary *Measurement in Measurements)
    {
        NSNumber *X = [Measurement objectForKey:@"X"];
        NSNumber *Y = [Measurement objectForKey:@"Y"];
        int xv = [X intValue];
        int yv = [Y intValue];
        
        if (Zoom > 0)
        {
            xv <<= Zoom;
            yv <<= Zoom;
        }
        else if (Zoom < 0)
        {
            xv >>= (-Zoom);
            yv >>= (-Zoom);
        }
        
        CGFloat xval = Bds.origin.x + xv;
        CGFloat yval = Bds.origin.y + yv;
        
        [OuterColor setFill];
        
        PaintRectOp(xval-2-MkrLen,yval-1, MkrLen,3, OutOp);
        PaintRectOp(xval+2,yval-1, MkrLen,3, OutOp);
        PaintRectOp(xval-1,yval-2-MkrLen, 3,MkrLen, OutOp);
        PaintRectOp(xval-1,yval+2, 3,MkrLen, OutOp);
        
        [InnerColor setFill];
        
        PaintRect(xval-2-MkrLen,yval, MkrLen,1);
        PaintRect(xval+2,yval, MkrLen,1);
        PaintRect(xval,yval-2-MkrLen, 1,MkrLen);
        PaintRect(xval,yval+2, 1,MkrLen);
    }
    
    [Ctxt restoreGraphicsState];
}

// So that an image will appear properly pixelated if magnified
- (void)drawRect:(NSRect)rect
{
    if (Zoom > 0)
    {
        // Pop the current interpolation, set it to pixelated,
        // render, then set it back again
        NSGraphicsContext *Ctxt = [NSGraphicsContext currentContext];
        NSImageInterpolation Interp = [Ctxt imageInterpolation];
        [Ctxt setImageInterpolation:NSImageInterpolationNone];
        [self DrawContents: rect];
        [Ctxt setImageInterpolation:Interp];
    }
    else
    {
        [self DrawContents: rect];
    }
}

@end
