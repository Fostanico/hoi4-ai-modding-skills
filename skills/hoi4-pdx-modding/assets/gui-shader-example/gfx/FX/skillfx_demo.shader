# Consumer-specific component; supply art and the owning GUI.
# Standalone HLSL checked; native binding requires a consumer smoke test.
Includes = { "buttonstate.fxh" "skillfx_demo.fxh" }
VertexStruct VS_OUTPUT {
    float4 vPosition : PDX_POSITION;
    float2 vTexCoord : TEXCOORD0;
};
VertexShader = {
    MainCode VertexShader [[
        VS_OUTPUT main(const VS_INPUT v) {
            VS_OUTPUT Out;
            Out.vPosition = mul(WorldViewProjectionMatrix, float4(v.vPosition.xyz, 1.0));
            Out.vTexCoord = v.vTexCoord + Offset;
            return Out;
        }
    ]]
}
PixelShader = {
    Samplers = {
        MapTexture = {
            Index = 0
            MagFilter = "Linear"
            MinFilter = "Linear"
            MipFilter = "None"
            AddressU = "Clamp"
            AddressV = "Clamp"
        }
    }
    MainCode PixelShaderUp [[
        float4 main(VS_OUTPUT v) : PDX_COLOR {
            return SkillFxShade(MapTexture, v.vTexCoord, Time, 0.0) * Color;
        }
    ]]
    MainCode PixelShaderOver [[
        float4 main(VS_OUTPUT v) : PDX_COLOR {
            return SkillFxShade(MapTexture, v.vTexCoord, Time, 1.0) * Color;
        }
    ]]
    MainCode PixelShaderDown [[
        float4 main(VS_OUTPUT v) : PDX_COLOR {
            return SkillFxShade(MapTexture, v.vTexCoord, Time, 2.0) * Color;
        }
    ]]
    MainCode PixelShaderDisable [[
        float4 main(VS_OUTPUT v) : PDX_COLOR {
            return SkillFxShade(MapTexture, v.vTexCoord, Time, 3.0) * Color;
        }
    ]]
}
BlendState BlendState {
    BlendEnable = yes
    SourceBlend = "src_alpha"
    DestBlend = "inv_src_alpha"
}
Effect Up { VertexShader = "VertexShader" PixelShader = "PixelShaderUp" }
Effect Over { VertexShader = "VertexShader" PixelShader = "PixelShaderOver" }
Effect Down { VertexShader = "VertexShader" PixelShader = "PixelShaderDown" }
Effect Disable { VertexShader = "VertexShader" PixelShader = "PixelShaderDisable" }
