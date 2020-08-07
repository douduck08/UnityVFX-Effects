float3 VAT_RotateVector (float3 v, float4 q) {
    return v + cross(2 * q.xyz, cross(q.xyz, v) + q.w * v);
}

float3 VAT_UnpackAlpha (float a) {
    float a_hi = floor(a * 32);
    float a_lo = a * 32 * 32 - a_hi * 32;

    float2 n2 = float2(a_hi, a_lo) / 31.5 * 4 - 2;
    float n2_n2 = dot(n2, n2);
    float3 n3 = float3(sqrt(1 - n2_n2 / 4) * n2, 1 - n2_n2 / 2);

    return clamp(n3, -1, 1);
}

float3 VAT_ConvertSpace (float3 v) {
    return v.xzy * float3(-1, 1, 1);
}

float4 GetSampleUV (float4 texelSize, float uv, float currentFrame, float totalFrame) {
    float frame = floor(clamp(currentFrame, 0, totalFrame - 1));
    float v = 1.0 - (frame + 0.5) * abs(texelSize.y);
    return float4(uv.x, v, 0, 0);
}

void SoftVAT (
float3 position,
float2 uv1,
sampler2D positionMap,
sampler2D normalMap,
float4 texelSize,
float2 bounds,
float totalFrame,
float currentFrame,
out float3 outPosition,
out float3 outNormal
) {
    float4 sampleUV = GetSampleUV(texelSize, uv1, currentFrame, totalFrame);
    float4 p = tex2Dlod(positionMap, sampleUV);

    outPosition = VAT_ConvertSpace(lerp(bounds.x, bounds.y, p.xyz));

#ifndef _PACKED_NORMAL_ON
    // Alpha-packed normal
    outNormal = VAT_ConvertSpace(VAT_UnpackAlpha(p.w));
#else
    // Normal vector from normal map
    outNormal = VAT_ConvertSpace(tex2Dlod(normalMap, sampleUV).xyz);
#endif
}

void RigidVAT (
float3 position,
float3 normal,
float3 color,
float2 uv1,
sampler2D positionMap,
sampler2D rotationMap,
float4 texelSize,
float4 bounds,
float totalFrame,
float currentFrame,
out float3 outPosition,
out float3 outNormal
) {
    float4 sampleUV = GetSampleUV(texelSize, uv1, currentFrame, totalFrame);
    float4 p = tex2Dlod(positionMap, sampleUV);
    float4 r = tex2Dlod(rotationMap, sampleUV);

    float3 offset = lerp(bounds.x, bounds.y, p.xyz);
    float3 pivot = lerp(bounds.z, bounds.w, color);
    float4 rot = (r * 2 - 1);

    // outPosition = VAT_RotateVector(position - pivot, rot) + pivot + offset;
    outPosition = offset;
    outNormal = VAT_RotateVector(normal, rot);
}