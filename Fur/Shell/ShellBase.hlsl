TEXTURE2D(_BaseMap);    
float4 _BaseMap_ST;
SAMPLER(sampler_BaseMap);

TEXTURE2D(_FurMap);    
float4 _FurMap_ST;
SAMPLER(sampler_FurMap);

int _ShellAmount;
float _ShellStep;
float _AlphaCutout;
float _Occlusion;
float _RimLightPower;
float _RimLightIntensity;

float4 _BaseMove;
float4 _WindFreq;
float4 _WindMove;

struct VertexInput
{
	float4 vertex : POSITION;
	float4 normal : NORMAL;
	float4 tangent: TANGENT;
    float2 texcoord : TEXCOORD0;
};

struct GeometryOutput
{
    float4 vertex   : SV_POSITION;
    float2 uv       : TEXCOORD0;
    float2 uv2      : TEXCOORD1;
    float  layer    : TEXCOORD2;
    float3 worldPos : TEXCOORD3;
    float3 worldNormal : TEXCOORD4;
    float3 worldTangent : TEXCOORD5;
    float3 worldBitangent : TEXCOORD6;
    float3 worldViewDir : TEXCOORD7;
    float3 worldLightDir : TEXCOORD8;
    float4 shadowCoord : TEXCOORD9;
};

VertexInput Vertex(VertexInput input)
{
    return input;
}

void GenerateFurMesh(inout TriangleStream<GeometryOutput> stream, VertexInput input, int index)
{
    GeometryOutput output = (GeometryOutput)0;

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.vertex.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangent);
    
    float moveFactor = pow((float) index / _ShellAmount, _BaseMove.w);
    
    float3 windAngle = _Time.w * _WindFreq.xyz;
    float3 windMove = moveFactor * _WindMove.xyz * sin(windAngle + input.vertex * _WindMove.w);
    
    float3 move = moveFactor * _BaseMove.xyz;
    
    float3 shellDir = normalize(normalInput.normalWS + move + windMove);
    
    float3 posWS = vertexInput.positionWS + shellDir * (_ShellStep * index);
    float4 posCS = TransformWorldToHClip(posWS);
    
    output.worldPos = vertexInput.positionWS;
    output.worldNormal = normalInput.normalWS;
    output.worldTangent = normalInput.tangentWS;
    output.worldBitangent = normalInput.bitangentWS;

    float3 TtoW1 = float3(output.worldTangent.x, output.worldBitangent.x, output.worldNormal.x);
    float3 TtoW2 = float3(output.worldTangent.y, output.worldBitangent.y, output.worldNormal.y);
    float3 TtoW3 = float3(output.worldTangent.z, output.worldBitangent.z, output.worldNormal.z);

    float3x3 rotation = float3x3(TtoW1, TtoW2, TtoW3);

    output.worldViewDir = normalize(_WorldSpaceCameraPos.xyz - vertexInput.positionWS);
    output.worldLightDir = normalize(_MainLightPosition.xyz);

    output.vertex = posCS;
    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.uv2 = TRANSFORM_TEX(input.texcoord, _FurMap);
    output.layer = (float)index / _ShellAmount;
        
    output.shadowCoord = GetShadowCoord(vertexInput);

    stream.Append(output);
}

[maxvertexcount(30)]
void geom(triangle VertexInput input[3], inout TriangleStream<GeometryOutput> stream)
{
    [loop] for (float i = 0; i < _ShellAmount; ++i)
    {
        [unroll] for (float j = 0; j < 3; ++j)
        {
            GenerateFurMesh(stream, input[j], i);
        }
        stream.RestartStrip();
    }
}

void CalculateRimLight(inout float3 color, float3 posWS, float3 viewDirWS, float3 normalWS)
{
    float VoN = abs(dot(viewDirWS, normalWS));
    float normalFactor = pow(abs(1.0 - VoN), _RimLightPower);

    Light light = GetMainLight();
    float LoV = dot(light.direction, viewDirWS);
    float intensity = pow(max(-LoV, 0.0), _RimLightPower);
    intensity *= _RimLightIntensity * normalFactor;
#ifdef _MAIN_LIGHT_SHADOWS
    float4 shadowCoord = TransformWorldToShadowCoord(posWS);
    intensity *= MainLightRealtimeShadow(shadowCoord);
#endif 
    color += intensity * light.color;

#ifdef _ADDITIONAL_LIGHTS
    int additionalLightsCount = GetAdditionalLightsCount();
    for (int i = 0; i < additionalLightsCount; ++i)
    {
        int index = GetPerObjectLightIndex(i);
        Light light = GetAdditionalPerObjectLight(index, posWS);
        float LoV = dot(light.direction, viewDirWS);
        float intensity = max(-LoV, 0.0);
        intensity *= _RimLightIntensity * normalFactor;
        intensity *= light.distanceAttenuation;
#ifdef _MAIN_LIGHT_SHADOWS
        intensity *= AdditionalLightRealtimeShadow(index, posWS);
#endif 
        color += intensity * light.color;
    }
#endif
}

float4 Frag(GeometryOutput input) : SV_Target
{
    float4 furColor = SAMPLE_TEXTURE2D(_FurMap, sampler_FurMap, input.uv2);
    float4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);

    float alpha = furColor.r * (1.0 - input.layer) * baseColor.r;
    if (input.layer > 0.0 && alpha < _AlphaCutout) discard;

    float occlusion = lerp(1.0 - _Occlusion, 1.0, input.layer);
    float3 color = baseColor * occlusion;

    float3 diffuse = saturate(dot(input.worldLightDir, input.worldNormal)) * color;
    
    int lightCount = GetAdditionalLightsCount();
    for(int lightIndex = 0; lightIndex < lightCount; lightIndex++)
    {
        Light lightAdditional = GetAdditionalLight(lightIndex, input.worldPos);

        diffuse += saturate(dot(lightAdditional.direction, input.worldNormal)) * color;
    }

    CalculateRimLight(color, input.worldPos, input.worldViewDir, input.worldNormal);
    
    Light light = GetMainLight();
    light.shadowAttenuation = MainLightRealtimeShadow(input.shadowCoord);
    float3 shadow = light.shadowAttenuation;

    //return float4(color + diffuse * shadow, alpha);
    return float4(color + diffuse, alpha);
 
}

void FragShadow(
    GeometryOutput input,
    out float4 outColor : SV_Target,
    out float outDepth : SV_Depth)
{
    float4 furColor = SAMPLE_TEXTURE2D(_FurMap, sampler_FurMap, input.uv);
    float alpha = furColor.r * (1.0 - input.layer);
    if (input.layer > 0.0 && alpha < _AlphaCutout)
        discard;

    outColor = outDepth = input.vertex.z / input.vertex.w;
}
