//
//  PositionReceiver.h
//  Image Measurer
//
//  Created by Loren Petrich on 5/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


// For sending a point value back to the main class
// The point is tagged to indicate its origin

@protocol PositionReceiver <NSObject>

- (void)ReceivePosition:(NSPoint)Point Tag:(NSString *)Tag;

@end
