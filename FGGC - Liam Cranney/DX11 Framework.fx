//--------------------------------------------------------------------------------------
// File: DX11 Framework.fx
//
// Copyright (c) Microsoft Corporation. All rights reserved.
//--------------------------------------------------------------------------------------
Texture2D txDiffuse : register(t0);
SamplerState samLinear : register(s0);
//--------------------------------------------------------------------------------------
// Constant Buffer Variables
//--------------------------------------------------------------------------------------
cbuffer ConstantBuffer : register( b0 )
{
	matrix World;
	matrix View;
	matrix Projection;
	float4 AmbientMtrl;
	float4 AmbientLight;
	float4 SpecularMtrl;
	float4 SpecularLight;
	float  SpecularPower;
	float3 EyePosW;
	float4 DiffuseMtrl;
	float4 DiffuseLight;
	float3 LightVecW;
}

//--------------------------------------------------------------------------------------
struct VS_OUTPUT
{
    float4 Pos : SV_POSITION;
	float3 Norm : NORMAL;
	float3 PosW : POSITION;
	float2 Tex : TEXCOORD0;
};

//------------------------------------------------------------------------------------
// Vertex Shader - Implements Gouraud Shading using Diffuse lighting only
//------------------------------------------------------------------------------------
VS_OUTPUT VS(float4 Pos : POSITION, float3 NormalL : NORMAL, float2 Tex : TEXCOORD0)
{
	VS_OUTPUT output = (VS_OUTPUT)0;

	// Convert from local space to world space 
	// W component of vector is 0 as vectors cannot be translated
	output.Norm = mul(float4(NormalL, 0.0f), World).xyz;
	output.Norm = normalize(output.Norm);

	output.PosW = mul(Pos, World);
	output.Pos = mul(Pos, World);
	output.Pos = mul(output.Pos, View);
	output.Pos = mul(output.Pos, Projection);

	output.Tex = Tex;

	return output;
}



//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
float4 PS( VS_OUTPUT input ) : SV_Target
{
	input.Norm = normalize(input.Norm);

	float3 toEye = normalize(EyePosW - input.PosW);
	float3 r = reflect(-LightVecW, input.Norm);

	// Compute Colour using Diffuse lighting only
	float diffuseAmount = max(dot(LightVecW, input.Norm), 0.0f);
	float3 diffuse = diffuseAmount * (DiffuseMtrl * DiffuseLight).rgb;

	// Compute Colour
	float3 ambient = (AmbientMtrl * AmbientLight).rgb;

	float specularAmount = pow(max(dot(r, toEye), 0.0f), SpecularPower);
	float3 specular = specularAmount * (SpecularMtrl * SpecularLight).rgb;

	float4 textureColour = txDiffuse.Sample(samLinear, input.Tex);

	float4 Color;
	Color.rgb = ambient + diffuse + specular + textureColour;
	Color.a = DiffuseMtrl.a;

    return Color;
}
