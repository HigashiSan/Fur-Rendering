Shader "URP/Pin"
{
	Properties
	{
		[Header(Basic)][Space]
		[Toggle(DRAW_ORIG_POLYGON)]_DrawOrigPolygon("Draw Original Polygon", Float) = 0
		[MainColor] _BaseColor("Color", Color) = (0.5, 0.5, 0.5, 1)
		_BaseMap("Base Map", 2D) = "white" {}

		[Header(Fur)][Space]
		_FurMap("Fur Map", 2D) = "white" {}
		_AlphaCutout("Alpha Cutout", Range(0.0, 1.0)) = 0.2
		_FinLength("Fin Length", Range(0.0, 1.0)) = 0.1
		_FaceViewProdThresh("Fin Direction Threshold", Range(0.0, 1.1)) = 0.1
		_Occlusion("Occlusion", Range(0.0, 1.0)) = 0.3
		_Density("Density", Range(0, 10)) = 1.0
		[Header(Tesselation)][Space]
		_TessMinDist("Tesselation Min Distance", Range(0.1, 50)) = 1.0
		_TessMaxDist("Tesselation Max Distance", Range(0.1, 50)) = 10.0
		_TessFactor("Tessellation Factor", Range(1, 20)) = 3
		_RandomDirection("RandomDirection", Range(0.0, 1.0)) = 0.5
		[Header(Move)][Space]
		_BaseMove("Base Move", Vector) = (0.0, -0.0, 0.0, 3.0)
		_WindFreq("Wind Freq", Vector) = (0.5, 0.7, 0.9, 1.0)
		_WindMove("Wind Move", Vector) = (0.2, 0.3, 0.2, 1.0)
		_FinJointNum("_FinJointNum", int) = 1.0
	}

	SubShader
	{
        Tags 
		{
            "IgnoreProjector"="True"
            "RenderPipeline" = "UniversalPipeline"
			"RenderType" = "Opaque"
        }

		Pass
		{
			Name "ForwardLit"
			Tags { "LightMode" = "UniversalForward" "Queue" = "Transparent"}

			Cull Off

			HLSLPROGRAM

			#pragma vertex vert
        	#pragma geometry geom 
        	#pragma fragment frag

			#pragma require tessellation tessHW
			#pragma hull hull
			#pragma domain domain

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT

			#pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "FinBase.hlsl"

			ENDHLSL
		}

		Pass
		{
		    Name "ShadowCaster"
		    Tags { "LightMode" = "ShadowCaster" }

		    ZWrite On
		    ZTest LEqual
		    ColorMask 0

		    HLSLPROGRAM
		    #pragma exclude_renderers gles gles3 glcore
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		    #include "FinBase.hlsl"
		    #pragma vertex vert
		    #pragma require geometry
		    #pragma geometry geom 
		    #pragma fragment FragShadow
		    ENDHLSL
		}
	}

	FallBack "VertexLit"
}