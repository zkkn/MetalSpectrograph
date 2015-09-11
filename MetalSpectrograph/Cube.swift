//
//  BasicCube.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/11/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import simd
import Metal

// TODO: how to dynamically swap out vertex colors?
class Cube<T: Vertexable>: Node<T>, Rotatable, Translatable, Scalable {
    
    // TODO: how to make truly generic?
    //  i.e. make cube that works with Vertex & ColorVertex
    //  where a single cubeVertices method produces either Vertex/ColorVertex
    class func cubeVertices() -> [T] {
        return [
            T(chunks: [float4(-1.0,  1.0,  1.0, 1.0), float4(1.0, 1.0, 1.0, 0.0)]),
            T(chunks: [float4(-1.0, -1.0,  1.0, 1.0), float4(0.0, 1.0, 1.0, 0.0)]),
            T(chunks: [float4( 1.0, -1.0,  1.0, 1.0), float4(1.0, 0.0, 1.0, 0.0)]),
            T(chunks: [float4( 1.0,  1.0,  1.0, 1.0), float4(1.0, 0.0, 0.0, 0.0)]),
            T(chunks: [float4(-1.0,  1.0, -1.0, 1.0), float4(0.0, 0.0, 1.0, 0.0)]),
            T(chunks: [float4( 1.0,  1.0, -1.0, 1.0), float4(1.0, 1.0, 0.0, 0.0)]),
            T(chunks: [float4(-1.0, -1.0, -1.0, 1.0), float4(0.0, 1.0, 0.0, 0.0)]),
            T(chunks: [float4( 1.0, -1.0, -1.0, 1.0), float4(0.0, 0.0, 0.0, 0.0)])
        ]
    }
    
    class func verticesToTriangles(vertices: [T]) -> [T] {
        let A = vertices[0]
        let B = vertices[1]
        let C = vertices[2]
        let D = vertices[3]
        let Q = vertices[4]
        let R = vertices[5]
        let S = vertices[6]
        let T = vertices[7]
        
        return [
            A,B,C ,A,C,D,   //Front
            R,T,S ,Q,R,S,   //Back
            
            Q,S,B ,Q,B,A,   //Left
            D,C,T ,D,T,R,   //Right
            
            Q,A,D ,Q,D,R,   //Top
            B,S,T ,B,T,C]   //Bottom
    }
    
    init(device: MTLDevice) {
        let baseVertices = Cube<T>.cubeVertices()
        let triangleVertices = Cube<T>.verticesToTriangles(baseVertices)
        super.init(name: "Cube", vertices: triangleVertices, device: device)
    }
    
    func encode(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
        renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, atIndex: 1)
    }
    
    // Rotatable
    
    var rotationRate: Float = 10.0
    func rotateForTime(t: CFTimeInterval, block: (Rotatable -> Float)?) -> Float {
        // TODO: clean this up.  add applyRotation? as default extension to protocol?
        // - or set up 3D transforms as a protocol?
        let rotation = (rotationRate * Float(t)) * (block?(self) ?? 1)
        self.modelAngle += rotation
        return rotation
    }
    
    // Translatable
    
    var translationRate: Float = 0.1
    func translateForTime(t: CFTimeInterval, block: (Translatable -> float3)?) -> float3 {
        let translation = (translationRate * Float(t)) * (block?(self) ?? float3(0,0,0))
        self.modelPosition += translation
        return translation
    }
    
    // Scalable
    
    var scaleRate: Float = 0.1
    func scaleForTime(t: CFTimeInterval, block: (Scalable -> float3)?) -> float3 {
        let scaleAmount = (scaleRate * Float(t)) * (block?(self) ?? float3(0.0,0.0,0.0))
        self.modelScale += scaleAmount
        return scaleAmount
    }
}
