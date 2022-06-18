//
//  MetalRotateFilter.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 12/06/22.
//

import Foundation
import Metal

/// Rotates an image
public class MetalRotateFilter: MetalBaseFilter {
    /// Angle (degree) to rotate
    public var angle: Float {
        get { return _angle / Float.pi * 180 }
        set { _angle = newValue * Float.pi / 180 }
    }
    private var _angle: Float
    
    /// True to change image size to fit rotated image, false to keep image size
    public var fitSize: Bool
    
    public init(angle: Float = 0, fitSize: Bool = true) {
        _angle = angle * Float.pi / 180
        self.fitSize = fitSize
        super.init(kernelFunctionName: "rotateKernel")
    }
    
    public override func outputTextureSize(withInputTextureSize inputSize: MetalIntSize) -> MetalIntSize {
        if fitSize {
            let width = Int(abs(sin(_angle) * Float(inputSize.height)) + abs(cos(_angle) * Float(inputSize.width)))
            let height = Int(abs(sin(_angle) * Float(inputSize.width)) + abs(cos(_angle) * Float(inputSize.height)))
            return MetalIntSize(width: width, height: height)
        }
        return inputSize
    }
    
    public override func updateParameters(forComputeCommandEncoder encoder: MTLComputeCommandEncoder) {
        encoder.setBytes(&_angle, length: MemoryLayout<Float>.size, index: 0)
    }
}
