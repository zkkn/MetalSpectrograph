//
//  Objects.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/11/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

//https://developer.apple.com/library/prerelease/ios/samplecode/MetalKitEssentials/Introduction/Intro.html#//apple_ref/doc/uid/TP40016233-Intro-DontLinkElementID_2
// http://metalbyexample.com/introduction-to-compute/
// http://metalbyexample.com/introduction-to-compute/
// - https://github.com/FlexMonkey/MetalKit-Particles/tree/master/OSXMetalParticles

import simd
import Metal

// ugh how to convert to and from various types, using only bytes ... 
// ... 
// ... oh yeh... C & pointers!!!  Direct memory access, the O.G. Generic

// TODO: genericize views?   MetalView<BasicTriangle>   ... hmmmmm, maybe
// TODO: genericize renderers?   MetalRenderer<BasicTriangle>

protocol Vertexable {
    var vertex: float4 { get set }
    static func chunkSize() -> Int
    func toChunks() -> [float4]
    init(chunks: [float4]) // just chunking with float4 for now
}

protocol Colorable {
    var color: float4 { get set }
}

struct ColorVertex: Vertexable, Colorable {
    var vertex: float4;
    var color: float4;
    
    init(chunks: [float4]) {
        self.vertex = chunks[0]
        self.color = chunks[1]
    }
    
    init(vertex: float4, color: float4) {
        self.vertex = vertex
        self.color = color
    }
    
    func toChunks() -> [float4] {
        return [vertex, color]
    }
    
    static func chunkSize() -> Int {
        return sizeof(ColorVertex)
    }
}

//protocol Uniformable?

protocol Rotatable {
    var rotationRate: Float { get set }
    func rotateForTime(t: CFTimeInterval, block: (Rotatable -> Float)?) -> Float
}

protocol Translatable {
    var translationRate: Float { get set }
    func translateForTime(t: CFTimeInterval, block: (Translatable -> float3)?) -> float3
}

protocol Scalable {
    var scaleRate: Float { get set }
    func scaleForTime(t: CFTimeInterval, block: (Scalable -> float3)?) -> float3
}

class Node<T: Vertexable> {
    let name:String
    var vCount:Int
    var vBytes:Int
    var vertexBuffer:MTLBuffer
    var uniformBuffer:MTLBuffer
    var device:MTLDevice
    
    var modelScale = float3(1.0, 1.0, 1.0)
    var modelPosition = float3(0.0, 0.0, 0.0)
    
    // TODO: figure out why 90 deg is magic #
    var modelAngle = Float(90)
    var modelRotation = float3(1.0, 1.0, 1.0)
    
    //swift has to have a default value
    var modelMatrix: float4x4 = float4x4(diagonal: float4(1.0,1.0,1.0,1.0))
    var modelPointer: UnsafeMutablePointer<Void>?
    
    init(name: String, vertices: [T], device: MTLDevice) {
        self.name = name
        self.device = device
        
        // wish i could refactor this to the following method, but i guess i'm not allowed to bc swift
        // setVertexBuffer(vertices)
        self.vCount = vertices.count
        self.vBytes = Node<T>.calculateBytes(vCount)
        self.vertexBuffer = self.device.newBufferWithBytes(vertices, length: vBytes, options: .CPUCacheModeDefaultCache)
        
        self.uniformBuffer = self.device.newBufferWithLength(sizeof(float4x4), options: .CPUCacheModeDefaultCache)
        
        self.modelMatrix = initModelMatrix()
        self.modelPointer = uniformBuffer.contents()
        updateUniformBuffer()
    }
    
    func setVertexBuffer(vertices: [Vertexable]) {
        let vertexCount = vertices.count
        let vertexBytes = Node<T>.calculateBytes(vCount)
        self.vertexBuffer = self.device.newBufferWithBytes(vertices, length: vertexBytes, options: .CPUCacheModeDefaultCache)
        self.vertexBuffer.label = "\(T.self) vertices"
    }
    
    static func calculateBytes(vertexCount: Int) -> Int {
        return vertexCount * sizeof(T)
    }
    
    func initModelMatrix() -> float4x4 {
        //init 4x4 identity matrix
        let model = float4x4(diagonal: float4(1.0,1.0,1.0,1.0))
        return model *
            Metal3DTransforms.translate(modelPosition) *
            Metal3DTransforms.rotate(modelAngle, r: modelRotation) *
            Metal3DTransforms.scale(modelScale)
    }
    
    func updateModelMatrix(translation: float3, rotation: Float, scale: float3) {
        self.modelMatrix = float4x4(diagonal: float4(1.0,1.0,1.0,1.0)) *
            Metal3DTransforms.translate(modelPosition) *
            Metal3DTransforms.rotate(modelAngle, r: self.modelRotation) *
            Metal3DTransforms.scale(modelScale)
        
//        self.modelMatrix *=
//            Metal3DTransforms.translate(translation) *
//            Metal3DTransforms.rotate(rotation, r: self.modelRotation) *
//            Metal3DTransforms.scale(self.modelScale + scale)
    }
    
    func updateUniformBuffer() {
        memcpy(modelPointer!, &self.modelMatrix, sizeof(float4x4))
    }
}