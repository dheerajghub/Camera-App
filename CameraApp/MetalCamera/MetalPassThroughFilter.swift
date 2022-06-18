//
//  MetalPassThroughFilter.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 12/06/22.
//

import Foundation
import Metal

/// Pass through filter passes the same texture from image source to image consumer. Use pass through filter to setup the filter chain for custom filter group.
public class MetalPassThroughFilter: MetalBaseFilter {
    /// Whether to create a new texture. False by default for performance.
    public let createTexture: Bool
    
    public init(createTexture: Bool = false) {
        self.createTexture = createTexture
        super.init(kernelFunctionName: "passThroughKernel")
    }
    
    public override func newTextureAvailable(_ texture: MetalTexture, from source: MetalImageSource) {
        if createTexture {
            super.newTextureAvailable(texture, from: source)
        } else {
            // Transmit output texture to image consumers
            for consumer in consumers { consumer.newTextureAvailable(texture, from: self) }
        }
    }
    
    public override func updateParameters(forComputeCommandEncoder encoder: MTLComputeCommandEncoder) {}
}
