#include "shader_Common.hlsli"

struct FragmentData
{
    unsigned int uDepthImportance;		// Depth (24 bit), importance (8 bit)
	float fAlphaWeight;					// Alpha weight
	float fImportance;
};

struct FragmentLink
{
    FragmentData fragmentData;	// Fragment data
    uint nNext;			// Link to next fragment
};

cbuffer CameraParameters : register(b0)
{
	row_major matrix View = matrix(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
	row_major matrix Projection = matrix(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
}

cbuffer RendererParameters : register(b1)
{
	float Q;
	float R;
	float Lambda;
	int TotalNumberOfControlPoints;
	float4 LineColor;
	float4 HaloColor;
	float StripWidth;
	float HaloPortion;
	int ScreenWidth;
	int ScreenHeight;
}

RWByteAddressBuffer StartOffsetSRV					: register( u1 );
RWStructuredBuffer< FragmentLink >  FragmentLinkSRV	: register( u2 );
RWByteAddressBuffer AlphaBufferUAV					: register( u3 );

struct QuadVSinput
{
    float4 pos : POSITION;
};

struct QuadVS_Output
{
    float4 pos : SV_POSITION; 
};

QuadVS_Output VS( QuadVSinput Input )
{
    QuadVS_Output Output;
    Output.pos = Input.pos;
    return Output;
}

struct QuadPS_Input 
{
    float4 pos                : SV_POSITION; 
};

// Max hardcoded.
#define TEMPORARY_BUFFER_MAX        256

void PS( QuadPS_Input input )
{    
    // index to current pixel.
	uint nIndex = (uint)input.pos.y * ScreenWidth + (uint)input.pos.x;
                           // number of fragments in current pixel's linked list.
    uint nNext = StartOffsetSRV.Load(nIndex * 4);                // get first fragment from the start offset buffer.
    
    // early exit if no fragments in the linked list.
    if( nNext == 0xFFFFFFFF ) {
		return;
    }


	float gall=0;
	
	// First pass - iterate and sum up the squared importance
	[allow_uav_condition]
	for (int iii = 0; iii < TEMPORARY_BUFFER_MAX; iii++)
	{
		if ( nNext == 0xFFFFFFFF )
			break;
        FragmentLink element = FragmentLinkSRV[nNext];
        
		//float gi = clamp(( (element.fragmentData.uDepthImportance) & 0xFF ) / 255.0f, 0.001, 0.999);
		float gi = clamp(element.fragmentData.fImportance, 0.001, 0.999);
		gall = gall + gi*gi;

        nNext = element.nNext;
    }

	nNext = StartOffsetSRV.Load(nIndex * 4);
	float gf = 0;


    // second pass - compute the alpha values and write to file!
	[allow_uav_condition]
	for (int ii = 0; ii < TEMPORARY_BUFFER_MAX; ii++)
	{
		if ( nNext == 0xFFFFFFFF )
			break;
        FragmentLink element = FragmentLinkSRV[nNext];
        
		float gi = clamp(element.fragmentData.fImportance, 0.001, 0.999);
		float gb = gall - gf - gi*gi;

		float p = 1;
		float alpha = (p) / ( p + pow(saturate(1-gi), 2*Lambda) * ( R*gf + Q*gb ) );
		alpha = saturate(alpha);

		// which control point does this fragment belong to?
		int controlPoint = (int)floor(element.fragmentData.fAlphaWeight + 0.5f);	// all half left and right belongs to the control point.

		// if we have a valid control point, update the alpha value!
		if (controlPoint >= 0 && controlPoint < TotalNumberOfControlPoints)
		{
			AlphaBufferUAV.InterlockedMin(controlPoint*4u, asuint(alpha));
		}

		gf = gf + gi*gi;

        nNext = element.nNext;
    }
}
