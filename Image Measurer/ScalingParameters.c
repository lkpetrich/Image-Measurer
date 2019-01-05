//
//  ScalingParameters.c
//  Image Measurer
//
//  Created by Loren Petrich on 7/25/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#include <string.h>
#include <math.h>
#include "ScalingParameters.h"

// Initialize the scaling parameters
void ScalingParametersInit(struct ScalingParameters *SPs)
{
    // Blank out the scaling matrix
    memset(SPs, 0, sizeof(struct ScalingParameters));
    SPs->Type = SCALING_NONE;
    // Identity scaling matrix
    for (int i=0; i<2; i++)
        SPs->Matrix[i][i] = 1;
}

// Update the scaling parameters
// with the scaling type and the input points
void ScalingParametersUpdate(struct ScalingParameters *SPs)
{
    // Blank out the scaling matrix
    memset(SPs->Matrix, 0, sizeof(SPs->Matrix));
    switch(SPs->Type)
    {
        case SCALING_NONE:
        {
            // Identity scaling matrix
            for (int i=0; i<2; i++)
                SPs->Matrix[i][i] = 1;
            break;
        }
            
        case SCALING_RECENTER:
        {
            // Changes the center to the point's location,
            // otherwise, the identity
            for (int i=0; i<2; i++)
            {
                SPs->Matrix[i][i] = 1;
                SPs->Matrix[i][2] = SPs->Points[0][i][1] - SPs->Points[0][i][0];
            }
            break;
        }
            
        case SCALING_HORIZONTAL:
        {
            // Calculates the scale in the horizontal direction,
            // uses it for the vertical direction also
            // Uses coordinates of first point as reference
            double scl = 0;
            {
                int i = 0;
                double ptin0 = SPs->Points[0][i][0];
                double ptout0 = SPs->Points[0][i][1];
                double ptin1 = SPs->Points[1][i][0];
                double ptout1 = SPs->Points[1][i][1];
                if (SPs->UseExplicitLength)
                    scl = SPs->ExplicitLength/(ptin1-ptin0);
                else
                    scl = (ptout1-ptout0)/(ptin1-ptin0);
            }
            for (int i=0; i<2; i++)
            {
                double ptin0 = SPs->Points[0][i][0];
                double ptout0 = SPs->Points[0][i][1];
                SPs->Matrix[i][i] = scl;
                SPs->Matrix[i][2] = ptout0 - scl*ptin0;
            }
            break;
       }
            
        case SCALING_VERTICAL:
        {
            // Calculates the scale in the vertical direction,
            // uses it for the horizontal direction also
            // Uses coordinates of first point as reference
           double scl = 0;
            {
                int i = 1;
                double ptin0 = SPs->Points[0][i][0];
                double ptout0 = SPs->Points[0][i][1];
                double ptin1 = SPs->Points[1][i][0];
                double ptout1 = SPs->Points[1][i][1];
                if (SPs->UseExplicitLength)
                    scl = SPs->ExplicitLength/(ptin1-ptin0);
                else
               scl = (ptout1-ptout0)/(ptin1-ptin0);
            }
            for (int i=0; i<2; i++)
            {
                double ptin0 = SPs->Points[0][i][0];
                double ptout0 = SPs->Points[0][i][1];
                SPs->Matrix[i][i] = scl;
                SPs->Matrix[i][2] = ptout0 - scl*ptin0;
            }
            break;
       }
            
        case SCALING_DIAGONAL:
        {
            // Calculates the scale using the distance between the two points
            // Uses coordinates of first point as reference
           double ptinsq = 0;
            double ptoutsq = 0;
            for (int i=0; i<2; i++)
            {
                double ptin0 = SPs->Points[0][i][0];
                double ptout0 = SPs->Points[0][i][1];
                double ptin1 = SPs->Points[1][i][0];
                double ptout1 = SPs->Points[1][i][1];
                double ptindif = ptin1 - ptin0;
                double ptoutdif = ptout1 - ptout0;
                ptinsq += ptindif*ptindif;
                ptoutsq += ptoutdif*ptoutdif;
            }
            double scl = 0;
            if (SPs->UseExplicitLength)
                scl = SPs->ExplicitLength/sqrt(ptinsq);
            else
                scl = sqrt(ptoutsq/ptinsq);
            
            for (int i=0; i<2; i++)
            {
                double ptin0 = SPs->Points[0][i][0];
                double ptout0 = SPs->Points[0][i][1];
                SPs->Matrix[i][i] = scl;
                SPs->Matrix[i][2] = ptout0 - scl*ptin0;
            }
            break;
       }
            
        case SCALING_ORTHOGONAL:
        {
            // Calculates the scale separately for each dimension
            for (int i=0; i<2; i++)
            {
                double ptin0 = SPs->Points[0][i][0];
                double ptout0 = SPs->Points[0][i][1];
                double ptin1 = SPs->Points[1][i][0];
                double ptout1 = SPs->Points[1][i][1];
                double scl = (ptout1-ptout0)/(ptin1-ptin0);
                SPs->Matrix[i][i] = scl;
                SPs->Matrix[i][2] = ptout0 - scl*ptin0;
            }
            break;
        }
            
        case SCALING_GENERAL_LINEAR:
        {
            // The most general case
            // Needs 3 points
            double ptin0_0 = SPs->Points[0][0][0];
            double ptout0_0 = SPs->Points[0][0][1];
            double ptin0_1 = SPs->Points[0][1][0];
            double ptout0_1 = SPs->Points[0][1][1];
            double ptin1_0 = SPs->Points[1][0][0];
            double ptout1_0 = SPs->Points[1][0][1];
            double ptin1_1 = SPs->Points[1][1][0];
            double ptout1_1 = SPs->Points[1][1][1];
            double ptin2_0 = SPs->Points[2][0][0];
            double ptout2_0 = SPs->Points[2][0][1];
            double ptin2_1 = SPs->Points[2][1][0];
            double ptout2_1 = SPs->Points[2][1][1];
            double osin1_0 = ptin1_0 - ptin0_0;
            double osout1_0 = ptout1_0 - ptout0_0;
            double osin1_1 = ptin1_1 - ptin0_1;
            double osout1_1 = ptout1_1 - ptout0_1;
            double osin2_0 = ptin2_0 - ptin0_0;
            double osout2_0 = ptout2_0 - ptout0_0;
            double osin2_1 = ptin2_1 - ptin0_1;
            double osout2_1 = ptout2_1 - ptout0_1;
            double mtdn = osin1_0*osin2_1 - osin1_1*osin2_0;
            double mt0_0 = (osin2_1*osout1_0 - osin1_1*osout2_0)/mtdn;
            double mt0_1 = (osin1_0*osout2_0 - osin2_0*osout1_0)/mtdn;
            double mt1_0 = (osin2_1*osout1_1 - osin1_1*osout2_1)/mtdn;
            double mt1_1 = (osin1_0*osout2_1 - osin2_0*osout1_1)/mtdn;
            SPs->Matrix[0][0] = mt0_0;
            SPs->Matrix[0][1] = mt0_1;
            SPs->Matrix[0][2] = ptout0_0 - (mt0_0*ptin0_0 + mt0_1*ptin0_1);
            SPs->Matrix[1][0] = mt1_0;
            SPs->Matrix[1][1] = mt1_1;
            SPs->Matrix[1][2] = ptout0_1 - (mt1_0*ptin0_0 + mt1_1*ptin0_1);
            break;
        }
    }
}
