//////////////////////////////////////////////////////////////////////////
//
//      DO NOT EDIT THIS FILE!! THIS IS AUTOMATICALLY GENERATED!!
//      DO NOT EDIT THIS FILE!! THIS IS AUTOMATICALLY GENERATED!!
//      DO NOT EDIT THIS FILE!! THIS IS AUTOMATICALLY GENERATED!!
//
//////////////////////////////////////////////////////////////////////////

#ifndef UNITY_TERRAIN_TOOL_NOISE_StrataValue_INC
#define UNITY_TERRAIN_TOOL_NOISE_StrataValue_INC

/*=========================================================================

    Includes

=========================================================================*/

#include "Packages/com.unity.terrain-tools/Shaders/NoiseLib/Implementation/ValueImpl.hlsl"
#include "Packages/com.unity.terrain-tools/Shaders/NoiseLib/Strata/Value.hlsl"
#include "Packages/com.unity.terrain-tools/Shaders/NoiseLib/NoiseCommon.hlsl"





#ifndef STRATAFRACTALINPUT_DEF // [ STRATAFRACTALINPUT_DEF
#define STRATAFRACTALINPUT_DEF

struct StrataFractalInput
{
    float octaves;
    float amplitude;
    float persistence;
    float frequency;
    float lacunarity;
    float warpIterations;
    float warpStrength;
    float4 warpOffsets;
    float strataScale;
    float strataOffset;
};



StrataFractalInput GetDefaultStrataFractalInput()
{
    StrataFractalInput ret;

    ret.octaves = 8;
    ret.amplitude = 0.5;
    ret.persistence = 0.5;
    ret.frequency = 1;
    ret.lacunarity = 2;
    ret.warpIterations = 0;
    ret.warpStrength = 0.5;
    ret.warpOffsets = float4(2.5, 1.4, 3.2, 2.7);
    ret.strataScale = 1;
    ret.strataOffset = 0;

    return ret;
}




float _StrataOctaves;
float _StrataAmplitude;
float _StrataPersistence;
float _StrataFrequency;
float _StrataLacunarity;
float _StrataWarpIterations;
float _StrataWarpStrength;
float4 _StrataWarpOffsets;
float _StrataStrataScale;
float _StrataStrataOffset;

StrataFractalInput GetStrataFractalInput()
{
    StrataFractalInput ret;

    ret.octaves = _StrataOctaves;
    ret.amplitude = _StrataAmplitude;
    ret.persistence = _StrataPersistence;
    ret.frequency = _StrataFrequency;
    ret.lacunarity = _StrataLacunarity;
    ret.warpIterations = _StrataWarpIterations;
    ret.warpStrength = _StrataWarpStrength;
    ret.warpOffsets = _StrataWarpOffsets;
    ret.strataScale = _StrataStrataScale;
    ret.strataOffset = _StrataStrataOffset;

    return ret;
}



#endif // ] STRATAFRACTALINPUT_DEF



/*=========================================================================

    Fractal Functions

=========================================================================*/

float noise_StrataValue_Raw( float pos, StrataFractalInput fractalInput )
{
    float prev = 0;
    float n = 0;

    float octaves = ceil(fractalInput.octaves) + (1 - sign(frac(fractalInput.octaves)));

    for( float i = 0; i < octaves; ++i )
    {
        prev = n;
        n += fractalInput.amplitude * get_noise_Value( pos * fractalInput.frequency );
        fractalInput.frequency *= fractalInput.lacunarity;
        fractalInput.amplitude *= fractalInput.persistence;
    }

    n = lerp(prev, n, frac(fractalInput.octaves));

    return n;
}

float noise_StrataValue_Raw( float2 pos, StrataFractalInput fractalInput )
{
    float prev = 0;
    float n = 0;

    float octaves = ceil(fractalInput.octaves) + (1 - sign(frac(fractalInput.octaves)));

    for( float i = 0; i < octaves; ++i )
    {
        prev = n;
        n += fractalInput.amplitude * get_noise_Value( pos * fractalInput.frequency );
        fractalInput.frequency *= fractalInput.lacunarity;
        fractalInput.amplitude *= fractalInput.persistence;
    }

    n = lerp(prev, n, frac(fractalInput.octaves));

    return n;
}

float noise_StrataValue_Raw( float3 pos, StrataFractalInput fractalInput )
{
    float prev = 0;
    float n = 0;

    float octaves = ceil(fractalInput.octaves) + (1 - sign(frac(fractalInput.octaves)));

    for( float i = 0; i < octaves; ++i )
    {
        prev = n;
        n += fractalInput.amplitude * get_noise_Value( pos * fractalInput.frequency );
        fractalInput.frequency *= fractalInput.lacunarity;
        fractalInput.amplitude *= fractalInput.persistence;
    }

    n = lerp(prev, n, frac(fractalInput.octaves));

    return n;
}

float noise_StrataValue_Raw( float4 pos, StrataFractalInput fractalInput )
{
    float prev = 0;
    float n = 0;

    float octaves = ceil(fractalInput.octaves) + (1 - sign(frac(fractalInput.octaves)));

    for( float i = 0; i < octaves; ++i )
    {
        prev = n;
        n += fractalInput.amplitude * get_noise_Value( pos * fractalInput.frequency );
        fractalInput.frequency *= fractalInput.lacunarity;
        fractalInput.amplitude *= fractalInput.persistence;
    }

    n = lerp(prev, n, frac(fractalInput.octaves));

    return n;
}

/*=========================================================================

    StrataValue Noise Functions - Fractal, Warped

=========================================================================*/

float noise_StrataValue( float pos, StrataFractalInput fractalInput )
{
    if(fractalInput.warpIterations > 0)
    {
        float prev = 0;
        float warpIterations = ceil( fractalInput.warpIterations ) + ( 1 - sign( frac( fractalInput.warpIterations ) ) );

        // do warping
        for ( float i = 0; i < warpIterations; ++i )
        {
            float q = noise_StrataValue_Raw( pos + fractalInput.warpOffsets.x, fractalInput );
            prev = pos;
            pos = pos + fractalInput.warpStrength * q;
        }

        pos = lerp( prev, pos, frac( fractalInput.warpIterations ) );
    }

    float h = noise_StrataValue_Raw( pos, fractalInput );

    float f = noise_StrataValue_Raw( h * fractalInput.strataScale + fractalInput.strataOffset, fractalInput );

    return f;
}

float noise_StrataValue( float2 pos, StrataFractalInput fractalInput )
{
    if(fractalInput.warpIterations > 0)
    {
        float2 prev = 0;
        float warpIterations = ceil( fractalInput.warpIterations ) + ( 1 - sign( frac( fractalInput.warpIterations ) ) );

        // do warping
        for ( float i = 0; i < warpIterations; ++i )
        {
            float2 q = float2( noise_StrataValue_Raw( pos, fractalInput ),
                            noise_StrataValue_Raw( pos + fractalInput.warpOffsets.xy, fractalInput ) );
            prev = pos;

            pos = pos + fractalInput.warpStrength * q;
        }

        pos = lerp( prev, pos, frac( fractalInput.warpIterations ) );
    }

    float h = noise_StrataValue_Raw( pos, fractalInput );

    float f = noise_StrataValue_Raw( h * fractalInput.strataScale + fractalInput.strataOffset, fractalInput );

    return f;
}

float noise_StrataValue( float3 pos, StrataFractalInput fractalInput )
{
    if(fractalInput.warpIterations > 0)
    {
        float3 prev = 0;
        float warpIterations = ceil( fractalInput.warpIterations ) + ( 1 - sign( frac( fractalInput.warpIterations ) ) );

        // do warping
        for ( float i = 0; i < warpIterations; ++i )
        {
            float3 q = float3( noise_StrataValue_Raw( pos.xyz, fractalInput ),
                        noise_StrataValue_Raw( pos.xyz + fractalInput.warpOffsets.xyz, fractalInput ),
                        noise_StrataValue_Raw( pos.xyz + float3( fractalInput.warpOffsets.x, fractalInput.warpOffsets.y, 0 ), fractalInput ) );
            prev = pos;
            pos = pos + fractalInput.warpStrength * q;
        }

        pos = lerp(prev, pos, frac( fractalInput.warpIterations ) );
    }

    float h = noise_StrataValue_Raw( pos, fractalInput );

    // h = sin( sign( h ) * ( 1 / abs( h ) ) );
    // h = sign( h ) * ( 1 / abs( h ) );

    float f = noise_StrataValue_Raw( h * fractalInput.strataScale + fractalInput.strataOffset, fractalInput );

    // f = ( h * .5 );
    // f = h;

    return f;
}

float noise_StrataValue( float4 pos, StrataFractalInput fractalInput )
{
    float h = noise_StrataValue_Raw( pos, fractalInput );

    float f = noise_StrataValue_Raw( h * fractalInput.strataScale + fractalInput.strataOffset, fractalInput );

    return f;
}

#endif // UNITY_TERRAIN_TOOL_NOISE_StrataValue_INC