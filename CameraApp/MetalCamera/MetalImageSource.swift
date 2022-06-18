//
//  MetalImageSource.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 12/06/22.
//

import Foundation
/// Defines image source behaviors
public protocol MetalImageSource: AnyObject {
    /// Adds an image consumer to consume the output texture
    ///
    /// - Parameter consumer: image consumer object to add
    /// - Returns: image consumer object to add
    func add<T: MetalImageConsumer>(consumer: T) -> T
    
    /// Adds an image consumer at the specific index
    ///
    /// - Parameters:
    ///   - consumer: image consumer object to add
    ///   - index: index for the image consumer object
    func add(consumer: MetalImageConsumer, at index: Int)
    
    /// Removes the image consumer
    ///
    /// - Parameter consumer: image consumer object to remove
    func remove(consumer: MetalImageConsumer)
    
    /// Removes all image consumers
    func removeAllConsumers()
}
