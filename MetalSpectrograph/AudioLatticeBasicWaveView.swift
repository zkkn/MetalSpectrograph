//
//  BasicWaveLattice.swift
//  MetalSpectrograph
//
//  Created by David Conner on 9/18/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

import Cocoa
import MetalKit
import simd
import EZAudio

class AudioLatticeBasicWaveView: MetalView {
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        preferredFramesPerSecond = 60
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AudioLatticeBasicWaveController: AudioPixelShaderViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        renderer.object!.setModelUniformsFrom((renderer as! AudioLatticeRenderer).originalObject!)
        setupGestures()
    }
    
    //TODO: not sure why this causes so many issues with nil
//    override func setupMetalView(frame: CGRect) -> MetalView {
//        return AudioLatticeBasicWaveView(frame: frame, device: MTLCreateSystemDefaultDevice())
//    }
    
    override func setupRenderer() {
        renderer = AudioLatticeRenderer()
    }
    
    override func microphone(microphone: EZMicrophone!, hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {
        
        //TODO: decide on async callback
        dispatch_async(dispatch_get_main_queue(), {
            let absAverage = WaveformAbsAvereageInput.waveformAverage(buffer, bufferSize: bufferSize, numberOfChannels: numberOfChannels)
            
            (self.renderer as! AudioLatticeRenderer).colorShift += self.colorShiftChangeRate * absAverage
            (self.renderer as! AudioLatticeRenderer).waveformBuffer!.writeBufferRow(buffer[0])
        })
    }
    
    override func pan(panGesture: NSPanGestureRecognizer){
        if panGesture.state == NSGestureRecognizerState.Changed{
            var pointInView = panGesture.locationInView(self.view)
            
            var xDelta = Float((lastPanLocation.x - pointInView.x)/self.view.bounds.width) * panSensivity
            var yDelta = Float((lastPanLocation.y - pointInView.y)/self.view.bounds.height) * panSensivity
            
            renderer.object?.modelPosition += [xDelta, 0.0, yDelta, 0.0]
            lastPanLocation = pointInView
        } else if panGesture.state == NSGestureRecognizerState.Began{
            lastPanLocation = panGesture.locationInView(self.view)
        }
    }
}

//TODO: check that texture is loaded (ensure pointer is valid)

class AudioLatticeRenderer: AudioPixelShaderRenderer {
    typealias VertexType = TexturedVertex
    typealias LG = QuadLatticeGenerator<Lattice2D<VertexType>, TexturedQuad<VertexType>>
    
    //    var object: Node<VertexType>
    var originalObject: protocol<RenderEncodable,Modelable,VertexBufferable>?
    var latticeGenerator: LG?
    
    // TODO: DrawPrimitives is not drawing all the triangles, but doesn't seem to be performance related.
    var latticeRows = 25
    var latticeCols = 20
    
    var waveformBuffer: CircularBuffer?
    var latticeConfigInput = BaseInput<QuadLatticeConfig>()
    
    override init() {
        super.init()

        vertexShaderName = "audioLatticeCircularWave"
        fragmentShaderName = "texQuadFragmentPeriodicColorShift"
    }
    
    override func configure(view: MetalView) {
        super.configure(view)
        
        latticeGenerator = LG(device: device!, size: CGSize(width: latticeCols, height: latticeRows))
        latticeGenerator!.configure()
        
        originalObject = object
        object = latticeGenerator!.generateLattice(object as! TexturedQuad<VertexType>)
        
        prepareLatticeConfig()
        prepareWaveformBuffer()
        scaleQuadForLattice()
    }
    
    func prepareLatticeConfig() {
        latticeConfigInput.data = QuadLatticeConfig(size: int2(Int32(latticeCols), Int32(latticeRows)))
        latticeConfigInput.bufferId = 4
    }
    
    func prepareWaveformBuffer() {
        let numCachedWaveforms = latticeRows + 1
        let samplesPerUpdate = 512
        
        waveformBuffer = WaveformBuffer()
        waveformBuffer!.bufferId = 2
        waveformBuffer!.prepareMemory(samplesPerUpdate * numCachedWaveforms * sizeof(Float))
        waveformBuffer!.prepareCircularParams(samplesPerUpdate)
        waveformBuffer!.circularParams!.bufferId = 3
        waveformBuffer!.prepareBuffer(device!)
    }
    
    func scaleQuadForLattice() {
        object!.modelScale *= float4(Float(latticeRows)/10.0, Float(latticeCols)/10.0, 1.0, 1.0)
    }
    
    override func encodeVertexBuffers(renderEncoder: MTLRenderCommandEncoder) {
        super.encodeVertexBuffers(renderEncoder)
        waveformBuffer!.writeVertex(renderEncoder)
        latticeConfigInput.writeVertexBytes(renderEncoder)
    }
    
    override func updateLogic(timeSinceLastUpdate: CFTimeInterval) {
        let timeSinceStart: CFTimeInterval = CFAbsoluteTimeGetCurrent() - startTime
        let quad = object as! Lattice2D<TexturedVertex>
        
        quad.rotateForTime(timeSinceLastUpdate) { obj in
            return 3.0
        }
        quad.updateRotationalVectorForTime(timeSinceLastUpdate) { obj in
            return -sin(Float(timeSinceStart)/4) *
                float4(0.5, 0.5, 1.0, 0.0)
        }
        
        object!.updateModelMatrix()
        //update vertex lattice (possibly modulating rows & columns
    }
    
}

class ImageLatticeBasicWaveController: AudioPixelShaderViewController {
    
    var callsToMicrophone = 0
    var callsToUpdate = 0
    
    override func setupTexture() {
        pixelTexture = renderer.inTexture as! ImageTexture
    }

    override func setupRenderer() {
        renderer = ImageLatticeRenderer()
    }
    
    override func microphone(microphone: EZMicrophone!, hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {
        
        print("In Microphone: \(callsToMicrophone++)")
        
        dispatch_async(dispatch_get_main_queue(), {
            print("In Async: \(self.callsToUpdate++)")
            let absAverage = WaveformAbsAvereageInput.waveformAverage(buffer, bufferSize: bufferSize, numberOfChannels: numberOfChannels)
            
            (self.renderer as! AudioLatticeRenderer).colorShift += self.colorShiftChangeRate * absAverage
            (self.renderer as! AudioLatticeRenderer).waveformBuffer!.writeBufferRow(buffer[0])
        })
    }
    
}

class ImageLatticeRenderer: AudioLatticeRenderer {
    let defaultFileName = "metaloopa"
    let defaultFileExt = "jpg"
    
    override init() {
        super.init()
        
        latticeRows = 25
        latticeCols = 20
        
        fragmentShaderName = "texQuadFragmentPeriodicColorShift"
    }
    
    override func prepareTexturedQuad(view: MetalView) -> Bool {
        inTexture = ImageTexture.init(name: defaultFileName as String, ext: defaultFileExt as String)
        inTexture?.texture
        
        guard inTexture!.finalize(device!) else {
            print("Failed to finalize ImageTexture")
            return false
        }
        
        inTexture!.texture!.label = "ImageTexture" as String
        size.width = CGFloat(inTexture!.texture!.width)
        size.width = CGFloat(inTexture!.texture!.width)
        
        object = TexturedQuad<TexturedVertex>(device: device!)
        
        return true
    }
    
}


