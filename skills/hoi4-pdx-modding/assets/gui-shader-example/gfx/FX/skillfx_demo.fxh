# Original example for the inspected HOI4 1.19.3 buttonstate consumer.
# Full-image UV, one art frame, straight alpha. No campaign-variable uniforms.
# State numbers are our entrypoint convention, not an engine uniform.
PixelShader = {
Code
[[
float4 SkillFxShade(in sampler2D art, float2 uv, float t, float state)
{
    float4 c = tex2D(art, uv);
    float interior = smoothstep(0.02, 0.10, uv.x)
                   * (1.0 - smoothstep(0.90, 0.98, uv.x))
                   * smoothstep(0.02, 0.10, uv.y)
                   * (1.0 - smoothstep(0.90, 0.98, uv.y));
    float sweep = frac(t * 0.08) * 1.8 - 0.4;
    float distance = (uv.x + uv.y * 0.3 - sweep) * 9.0;
    float band = exp(-distance * distance);
    float amount = 0.06;
    if (state > 0.5 && state < 1.5) { amount = 0.20; }
    if (state > 1.5 && state < 2.5) { amount = 0.10; c.rgb *= 0.88; }
    c.rgb += float3(1.0, 0.70, 0.35) * interior * band * amount;
    if (state > 2.5)
    {
        float grey = dot(c.rgb, float3(0.299, 0.587, 0.114));
        c.rgb = float3(grey, grey, grey) * 0.7;
    }
    return float4(saturate(c.rgb), c.a);
}
]]
}
