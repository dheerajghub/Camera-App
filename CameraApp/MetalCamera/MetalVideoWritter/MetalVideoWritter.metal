//
//  MetalVideoWritter.metal
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 12/06/22.
//

#include <metal_stdlib>
using namespace metal;



kernel void passThroughKernel(texture2d<half, access::write> outputTexture [[texture(0)]],
                              texture2d<half, access::read> inputTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
    
    if ((gid.x >= outputTexture.get_width()) || (gid.y >= outputTexture.get_height())) { return; }
    outputTexture.write(inputTexture.read(gid), gid);
}
