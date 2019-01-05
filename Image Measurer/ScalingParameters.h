//
//  ScalingParameters.h
//  Image Measurer
//
//  Created by Loren Petrich on 7/24/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#ifndef SCALING_PARAMETERS_DEFINTION
#define SCALING_PARAMETERS_DEFINTION

enum ScalingTypes {
    SCALING_NONE,
    SCALING_RECENTER,
    SCALING_HORIZONTAL,
    SCALING_VERTICAL,
    SCALING_DIAGONAL,
    SCALING_ORTHOGONAL,
    SCALING_GENERAL_LINEAR
};

#define NUMBER_OF_POINTS 3

struct ScalingParameters {
    enum ScalingTypes Type;
    
    // Input points
    // First index: which point
    // Second index: which coordinate
    // Third index: original, scaled values
    double Points[NUMBER_OF_POINTS][2][2];
    
    // Scaling matrix
    // First index: for scaled x, y
    // Second index: for original x, y, then offset
    // Will do linear scaling
    double Matrix[2][3];
    
    // For explicit scaling of horizontal, vertical, and diagonal cases:
    int UseExplicitLength; // Boolean: 1 = true, 0 = false
    double ExplicitLength;
};

// Initialize the scaling parameters
void ScalingParametersInit(struct ScalingParameters *SPs);

// Update the scaling parameters
// with the scaling type and the input points
void ScalingParametersUpdate(struct ScalingParameters *SPs);

#endif
