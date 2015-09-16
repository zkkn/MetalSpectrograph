//
//  TexturedQuadRenderer.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/11/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import simd
import MetalKit

// TODO: abstract textured quad behavior from image-loaded texture behavior
class TexturedQuadImgRenderer: BaseRenderer {
    var inTexture: MetalTexture?
    let defaultFileName = "Default"
    let defaultFileExt = "jpg"

    override init() {
        super.init()
        vertexShaderName = "texQuadVertex"
        fragmentShaderName = "texQuadFragment"
        rendererDebugGroupName = "Encode TexturedQuadImg"
        
        uniformScale = float4(1.0, 1.0, 1.0, 1.0)
        uniformPosition = float4(0.0, 0.0, 0.0, 1.0)
        uniformRotation = float4(1.0, 1.0, 1.0, 90)
    }
    
    override func configure(view: MetalView) {
        super.configure(view)
        
        //TODO: add asset?
        guard prepareTexturedQuad(view) else {
            print("Failed creating a textured quad!")
            return
        }
        
        guard prepareDepthStencilState() else {
            print("Failed creating a depth stencil state!")
            return
        }
    }
    
    override func preparePipelineState(view: MetalView) -> Bool {
        guard let vertexProgram = shaderLibrary?.newFunctionWithName(vertexShaderName) else {
            print("Couldn't load \(vertexShaderName)")
            return false
        }
        
        guard let fragmentProgram = shaderLibrary?.newFunctionWithName(fragmentShaderName) else {
            print("Couldn't load \(fragmentShaderName)")
            return false
        }
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        
//        pipelineStateDescriptor.depthAttachmentPixelFormat = view.depthPixelFormat!
        pipelineStateDescriptor.depthAttachmentPixelFormat = .Invalid

        pipelineStateDescriptor.stencilAttachmentPixelFormat = view.stencilPixelFormat!
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        pipelineStateDescriptor.sampleCount = view.sampleCount
        
        do {
            try pipelineState = (device!.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor))
        } catch(let err) {
            print("Failed to create pipeline state, error: \(err)")
            return false
        }
        
        return true
    }
    
    func prepareDepthStencilState() -> Bool {
        let depthStateDesc = MTLDepthStencilDescriptor()
        depthStateDesc.depthCompareFunction = .Always
        depthStateDesc.depthWriteEnabled = true
        depthState = device?.newDepthStencilStateWithDescriptor(depthStateDesc)
        
        return true
    }
    
    func prepareTexturedQuad(view: MetalView) -> Bool {
//        inTexture = ImageTexture.init(name: defaultFileName as String, ext: defaultFileExt as String)
        let bufferedTexture = BufferTexture<TexPixel2D>(size: CGSize(width: view.frame.size.width, height: view.frame.size.height))
        bufferedTexture.texture?.label = "BufferTexture" as String
        
//        guard inTexture!.finalize(device!) else {
        guard bufferedTexture.finalize(device!) else {
            print("Failed to finalize ImageTexture")
            return false
        }
        
        bufferedTexture.writePixels(bufferedTexture.randomPixels())
        inTexture = bufferedTexture

        object = TexturedQuad<TexturedVertex>(device: device!)
        
        return true
    }
    
    override func encode(renderEncoder: MTLRenderCommandEncoder) {
        renderEncoder.pushDebugGroup(rendererDebugGroupName)
        renderEncoder.setFrontFacingWinding(.CounterClockwise)
        renderEncoder.setDepthStencilState(depthState)
        renderEncoder.setRenderPipelineState(pipelineState!)
        object!.encode(renderEncoder)
        renderEncoder.setVertexBuffer(mvpBuffer, offset: 0, atIndex: mvpBufferId)
        renderEncoder.setFragmentTexture(inTexture!.texture, atIndex: 0)
        
        renderEncoder.drawPrimitives(.Triangle,
            vertexStart: 0,
            vertexCount: 6, //TODO: replace with constant?
            instanceCount: 1)
        
        renderEncoder.endEncoding()
        renderEncoder.popDebugGroup()
    }
}