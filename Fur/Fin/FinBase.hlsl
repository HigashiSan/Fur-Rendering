#pragma once
float _FaceViewProdThresh;
float _FinLength;
float _AlphaCutout;
float _Occlusion;

float _TessMinDist;
float _TessMaxDist;
float _TessFactor;

float4 _BaseMove;
float4 _WindFreq;
float4 _WindMove;

int _FinJointNum;

float _RandomDirection;

TEXTURE2D(_FurMap); 
float4 _FurMap_ST;
SAMPLER(sampler_FurMap);

TEXTURE2D(_BaseMap); 
float4 _BaseMap_ST;
SAMPLER(sampler_BaseMap);

float4 _BaseColor;
float _Density;

#pragma shader_feature DRAW_ORIG_POLYGON

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 uv : TEXCOORD0;
};

struct Varyings
{
    float4 vertex : SV_POSITION;
    float2 uv : TEXCOORD0;
    float fogCoord : TEXCOORD1;
    float2 finUv : TEXCOORD2;
};

Attributes vert(Attributes input)
{
    return input;
}

inline float3 GetViewDirectionOS(float3 posOS)
{
    float3 cameraOS = TransformWorldToObject(GetCameraPositionWS());
    return normalize(posOS - cameraOS);
}

inline float rand(float2 seed)
{
    return frac(sin(dot(seed.xy, float2(12.9898, 78.233))) * 43758.5453);
}

inline float3 rand3(float2 seed)
{
    return 2.0 * (float3(rand(seed * 1), rand(seed * 2), rand(seed * 3)) - 0.5);
}

struct HsConstantOutput
{
    float fTessFactor[3] : SV_TessFactor;
    float fInsideTessFactor : SV_InsideTessFactor;
    float3 f3B210 : POS3;
    float3 f3B120 : POS4;
    float3 f3B021 : POS5;
    float3 f3B012 : POS6;
    float3 f3B102 : POS7;
    float3 f3B201 : POS8;
    float3 f3B111 : CENTER;
    float3 f3N110 : NORMAL3;
    float3 f3N011 : NORMAL4;
    float3 f3N101 : NORMAL5;
};

[domain("tri")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[patchconstantfunc("hullConst")]
[outputcontrolpoints(3)]
Attributes hull(InputPatch<Attributes, 3> input, uint id : SV_OutputControlPointID)
{
    return input[id];
}

HsConstantOutput hullConst(InputPatch<Attributes, 3> i)
{
    HsConstantOutput o = (HsConstantOutput) 0;

    float distance = length(float3(UNITY_MATRIX_MV[0][3], UNITY_MATRIX_MV[1][3], UNITY_MATRIX_MV[2][3]));
    float factor = (_TessMaxDist - _TessMinDist) / max(distance - _TessMinDist, 0.01);
    factor = min(factor, 1.0);
    factor *= _TessFactor;

    o.fTessFactor[0] = o.fTessFactor[1] = o.fTessFactor[2] = factor;
    o.fInsideTessFactor = factor;

    float3 f3B003 = i[0].positionOS.xyz;
    float3 f3B030 = i[1].positionOS.xyz;
    float3 f3B300 = i[2].positionOS.xyz;

    float3 f3N002 = i[0].normalOS;
    float3 f3N020 = i[1].normalOS;
    float3 f3N200 = i[2].normalOS;
        
    o.f3B210 = ((2.0 * f3B003) + f3B030 - (dot((f3B030 - f3B003), f3N002) * f3N002)) / 3.0;
    o.f3B120 = ((2.0 * f3B030) + f3B003 - (dot((f3B003 - f3B030), f3N020) * f3N020)) / 3.0;
    o.f3B021 = ((2.0 * f3B030) + f3B300 - (dot((f3B300 - f3B030), f3N020) * f3N020)) / 3.0;
    o.f3B012 = ((2.0 * f3B300) + f3B030 - (dot((f3B030 - f3B300), f3N200) * f3N200)) / 3.0;
    o.f3B102 = ((2.0 * f3B300) + f3B003 - (dot((f3B003 - f3B300), f3N200) * f3N200)) / 3.0;
    o.f3B201 = ((2.0 * f3B003) + f3B300 - (dot((f3B300 - f3B003), f3N002) * f3N002)) / 3.0;

    float3 f3E = (o.f3B210 + o.f3B120 + o.f3B021 + o.f3B012 + o.f3B102 + o.f3B201) / 6.0;
    float3 f3V = (f3B003 + f3B030 + f3B300) / 3.0;
    o.f3B111 = f3E + ((f3E - f3V) / 2.0);
    
    float fV12 = 2.0 * dot(f3B030 - f3B003, f3N002 + f3N020) / dot(f3B030 - f3B003, f3B030 - f3B003);
    float fV23 = 2.0 * dot(f3B300 - f3B030, f3N020 + f3N200) / dot(f3B300 - f3B030, f3B300 - f3B030);
    float fV31 = 2.0 * dot(f3B003 - f3B300, f3N200 + f3N002) / dot(f3B003 - f3B300, f3B003 - f3B300);
    o.f3N110 = normalize(f3N002 + f3N020 - fV12 * (f3B030 - f3B003));
    o.f3N011 = normalize(f3N020 + f3N200 - fV23 * (f3B300 - f3B030));
    o.f3N101 = normalize(f3N200 + f3N002 - fV31 * (f3B003 - f3B300));
           
    return o;
}

[domain("tri")]
Attributes domain(
    HsConstantOutput hsConst,
    const OutputPatch<Attributes, 3> i,
    float3 bary : SV_DomainLocation)
{
    Attributes o = (Attributes) 0;

    float fU = bary.x;
    float fV = bary.y;
    float fW = bary.z;
    float fUU = fU * fU;
    float fVV = fV * fV;
    float fWW = fW * fW;
    float fUU3 = fUU * 3.0f;
    float fVV3 = fVV * 3.0f;
    float fWW3 = fWW * 3.0f;
    
    o.positionOS.xyz = float4(
        i[0].positionOS.xyz * fWW * fW +
        i[1].positionOS.xyz * fUU * fU +
        i[2].positionOS.xyz * fVV * fV +
        hsConst.f3B210 * fWW3 * fU +
        hsConst.f3B120 * fW * fUU3 +
        hsConst.f3B201 * fWW3 * fV +
        hsConst.f3B021 * fUU3 * fV +
        hsConst.f3B102 * fW * fVV3 +
        hsConst.f3B012 * fU * fVV3 +
        hsConst.f3B111 * 6.0f * fW * fU * fV,
        1.0);
    o.normalOS = normalize(
        i[0].normalOS * fWW +
        i[1].normalOS * fUU +
        i[2].normalOS * fVV +
        hsConst.f3N110 * fW * fU +
        hsConst.f3N011 * fU * fV +
        hsConst.f3N101 * fW * fV);
    o.uv =
        i[0].uv * fW +
        i[1].uv * fU +
        i[2].uv * fV;

    return o;
}

void AppendFinVertex(
    inout TriangleStream<Varyings> stream,
    float2 uv,
    float3 posOS,
    float2 finUv)
{
    Varyings output;

    output.vertex = TransformObjectToHClip(posOS);
    output.uv = uv;
    output.fogCoord = ComputeFogFactor(output.vertex.z);
    output.finUv = finUv;

    stream.Append(output);
}

void AppendFinVertices(
    inout TriangleStream<Varyings> stream,
    Attributes input0,
    Attributes input1,
    Attributes input2,
    float3 normalOS)
{
    float3 posOS0 = input0.positionOS.xyz;
    float3 lineOS01 = input1.positionOS.xyz - posOS0;
    float3 lineOS02 = input2.positionOS.xyz - posOS0;
    float3 posOS3 = posOS0 + (lineOS01 + lineOS02) / 2;

    float2 uv0 = TRANSFORM_TEX(input0.uv, _BaseMap);
    float2 uv12 = (TRANSFORM_TEX(input1.uv, _BaseMap) + TRANSFORM_TEX(input2.uv, _BaseMap)) / 2;
    float uvOffset = length(uv0);
    float uvXScale = length(uv0 - uv12) * _Density;

    AppendFinVertex(stream, uv0, posOS0, float2(uvOffset, 0.0));
    AppendFinVertex(stream, uv12, posOS3, float2(uvOffset + uvXScale, 0.0));

    float3 normalWS = TransformObjectToWorldNormal(normalOS);
    float3 posWS = TransformObjectToWorld(posOS0);
    float finStep = _FinLength / _FinJointNum;
    float3 windAngle = _Time.w * _WindFreq.xyz;
    float3 windMoveWS = _WindMove.xyz * sin(windAngle + posWS * _WindMove.w);
    float3 baseMoveWS = _BaseMove.xyz;

    [loop]
    for (int i = 1; i <= _FinJointNum; ++i)
    {
        float finFactor = (float) i / _FinJointNum;
        float moveFactor = pow(abs(finFactor), _BaseMove.w);
        float3 moveWS = SafeNormalize(normalWS + (baseMoveWS + windMoveWS) * moveFactor) * finStep;
        float3 moveOS = TransformWorldToObjectDir(moveWS, false);
        posOS0 += moveOS;
        posOS3 += moveOS;
        AppendFinVertex(stream, uv0, posOS0, float2(uvOffset, finFactor));
        AppendFinVertex(stream, uv12, posOS3, float2(uvOffset + uvXScale, finFactor));
    }
    stream.RestartStrip();
}

[maxvertexcount(15)]
void geom(triangle Attributes input[3], inout TriangleStream<Varyings> stream)
{
#ifdef DRAW_ORIG_POLYGON
    for (int i = 0; i < 3; ++i)
    {
        Varyings output;
        output.vertex = TransformObjectToHClip(input[i].positionOS.xyz);
        output.uv = TRANSFORM_TEX(input[i].uv, _BaseMap);
        output.fogCoord = ComputeFogFactor(output.vertex.z);
        output.finUv = float2(-1.0, -1.0);
        stream.Append(output);
    }
    stream.RestartStrip();
#endif

    float3 lineOS01 = (input[1].positionOS - input[0].positionOS).xyz;
    float3 lineOS02 = (input[2].positionOS - input[0].positionOS).xyz;
    
    float3 normalOS = normalize(cross(lineOS01, lineOS02));
    normalOS += rand3(input[0].uv) * _RandomDirection;
    normalOS = normalize(normalOS);
    
    float3 centerOS = (input[0].positionOS + input[1].positionOS + input[2].positionOS).xyz / 3;
    float3 viewDirOS = GetViewDirectionOS(centerOS);
    float eyeDotN = dot(viewDirOS, normalOS);
    if (abs(eyeDotN) > _FaceViewProdThresh)
        return;

    AppendFinVertices(stream, input[0], input[1], input[2], normalOS);
    //AppendFinVertices(stream, input[2], input[0], input[1], normalOS);
    //AppendFinVertices(stream, input[1], input[2], input[0], normalOS);
}

float4 frag(Varyings input) : SV_Target
{
    float4 furColor = SAMPLE_TEXTURE2D(_FurMap, sampler_FurMap, input.finUv);
    if (input.finUv.x >= 0 && furColor.a < _AlphaCutout)    discard;

    float4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
    color *= _BaseColor;
    color *= furColor;
    color.rgb *= lerp(1.0 - _Occlusion, 1.0, input.finUv.y);
    color.rgb = MixFog(color.rgb, input.fogCoord);
    return color;
}

void FragShadow(
    Varyings input,
    out float4 outColor : SV_Target,
    out float outDepth : SV_Depth)
{
    float4 furColor = SAMPLE_TEXTURE2D(_FurMap, sampler_FurMap, input.finUv);
    float alpha = furColor.a;
    if (alpha < _AlphaCutout)
        discard;
    outColor = outDepth = input.vertex.z / input.vertex.w;
}