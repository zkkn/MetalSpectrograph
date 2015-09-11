
//
//  MetalView.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/9/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import Foundation
import Cocoa
import MetalKit

let AAPLBuffersInflightBuffers: Int = 3;

protocol MetalViewDelegate: class {
    func updateLogic(timeSinseLastUpdate: CFTimeInterval)
    func renderObjects(drawable: CAMetalDrawable, renderPassDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer)
    func encode(renderEncoder: MTLRenderCommandEncoder)
}

//TODO: set default behaviors when setup delegates aren't implemented?

class MetalView: MTKView {
    var inflightSemaphore: dispatch_semaphore_t?
    
//    var computePipelineState: MTLComputePipelineState!
    var commandQueue: MTLCommandQueue!
    var displayLink: CVDisplayLink?
    var defaultLibrary:MTLLibrary!
    
    var lastFrameStart: CFAbsoluteTime!
    var thisFrameStart: CFAbsoluteTime!

    weak var metalViewDelegate: MetalViewDelegate?
    
    var renderPassDescriptor: MTLRenderPassDescriptor?
    
    var depthPixelFormat: MTLPixelFormat?
    var stencilPixelFormat: MTLPixelFormat?
//    var sampleCount: Int? // already in MTKView
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        // TODO: create device if not already present
        super.init(frame: frameRect, device: device)
        framebufferOnly = false
        preferredFramesPerSecond = 60
        
        beforeSetupMetal()
        setupMetal()
        afterSetupMetal()
        
        //override to setup objects
        setupRenderPipeline()
        
        lastFrameStart = CFAbsoluteTimeGetCurrent()
        thisFrameStart = CFAbsoluteTimeGetCurrent()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // move to delegate?
    func beforeSetupMetal() {
        
    }
    
    func afterSetupMetal() {
        
    }
    
    func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            self.metalUnavailable()
            return
        }
        
        self.device = device
        inflightSemaphore = dispatch_semaphore_create(AAPLBuffersInflightBuffers)
        defaultLibrary = device.newDefaultLibrary()
        commandQueue = device.newCommandQueue()
    }
    
    func metalUnavailable() {
        
    }
    
    func reshape(view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func render() {
        // setup CFAbsoluteTimeGetCurrent()
        
        renderPassDescriptor = currentRenderPassDescriptor
        
        // test renderpassdescriptor
        let commandBuffer = commandQueue.commandBuffer()
        
        guard let drawable = currentDrawable else
        {
            print("currentDrawable returned nil")

            return
        }
        
        setupRenderPassDescriptor(drawable)
        self.metalViewDelegate?.renderObjects(drawable, renderPassDescriptor: renderPassDescriptor!, commandBuffer: commandBuffer)
    }
    
    func setupRenderPassDescriptor(drawable: CAMetalDrawable) {
        //override in subclass
    }
    
    func setupRenderPipeline() {
        //override in subclass
    }
    
    // TODO: determine which mtkView gets called when there's no MTKViewDelegate?
//    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
//        self.reshape(drawableSizeWillChange: size)
//    }
    
    override func drawRect(dirtyRect: NSRect) {
        lastFrameStart = thisFrameStart
        thisFrameStart = CFAbsoluteTimeGetCurrent()
        self.metalViewDelegate?.updateLogic(CFTimeInterval(thisFrameStart - lastFrameStart))
        
        autoreleasepool { () -> () in
            self.render()
        }
    }
    
}