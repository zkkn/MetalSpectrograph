//
//  LatticeGenerator.metal
//  MetalSpectrograph
//
//  Created by David Conner on 9/18/15.
//  Copyright © 2015 Voxxel. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct LatticeColorVertexInOut {
    float4 position [[ position ]];
    float4 color;
};

struct LatticeTextureVertexInOut {
    float4 position [[ position ]];
    float4 texCoord [[ user(texturecoord) ]];
};

// i could just specify this generic struct
// - since both color & texture require float4
// - hmmmm, really how to make these computes/shaders more generic and robust?
//struct LatticeTriangleInOut {
//    
//};

struct LatticeColorTriangleInOut {
    LatticeColorVertexInOut v1;
    LatticeColorVertexInOut v2;
    LatticeColorVertexInOut v3;
};

struct LatticeTextureTriangleInOut {
    LatticeTextureVertexInOut v1;
    LatticeTextureVertexInOut v2;
    LatticeTextureVertexInOut v3;
};

// bisects an existing square quadrilateral lattice
// - to produce new lattice with num triangles t(n) = 4 * t(n-1)
kernel void bisectionLatticeGenerator(uint gid [[ thread_position_in_grid ]],
                                      constant LatticeTextureTriangleInOut *tIn [[ buffer(0) ]],
                                      device LatticeTextureTriangleInOut *tOut [[ buffer(1) ]]
                                      ) {
    int inputIndex = gid / 4;
    
    int subtriangleIndex = gid % 4;
    LatticeTextureTriangleInOut inTriangle = tIn[inputIndex];
    LatticeTextureTriangleInOut outTriangle = tIn[gid];
    
    //TODO: finish ... this is supposed to be recursive, so it's a bit harder
    
    // write new triangle indices to outTriangle
    // - also interpolate color/texture indices
    
    // update vOut
}

struct LatticeBisectionInput {
    int2 size;
};

struct ColorQuadrilateralIn {
    LatticeColorVertexInOut A;
    LatticeColorVertexInOut B;
    LatticeColorVertexInOut C;
    LatticeColorVertexInOut D;
};

struct TextureQuadrilateralIn {
    LatticeTextureVertexInOut A; // A
    LatticeTextureVertexInOut B; // B
    LatticeTextureVertexInOut C; // C
    LatticeTextureVertexInOut D; // D
};

// A ---- B
// |      |
// |      |
// D ---- C

float4 findPointOnLine(float4 startPosition,
                               float4 xDirection,
                               float4 yDirection,
                               int x,
                               int y,
                               int xSize,
                               int ySize) {
    
    return startPosition + (x * xDirection / xSize) + (y * yDirection / ySize);
}


struct QuadLatticeConfig {
    int2 size;
};

// interpolates vertices from a simple quadrilateral
// - to produce new lattice with num triangles t(n) = 2 * size.x * size.y
kernel void quadLatticeGenerator(uint gid [[ thread_position_in_grid ]],
                                 constant TextureQuadrilateralIn &qIn [[ buffer(0) ]],
                                 device LatticeTextureTriangleInOut *tOut [[ buffer(1) ]],
                                 constant QuadLatticeConfig &bisectionInput [[ buffer(2) ]]
                                 ) {
    
    //TODO: how to interpolate color/texture in a generic way?
    
    //============================================
    // here is test code
    //============================================
    
    int elementsPerRow = (2 * bisectionInput.size.x);
    int quadRowNumber = gid / elementsPerRow;
    int quadColNumber = (gid - quadRowNumber * elementsPerRow) / 2;
    int triangleIndex = (gid % 2);
    
    // if i hardcode texture coordinates, i get a crash on 2nd frame
    // - this is probably because the GPU isn't finished drawing or something
//    if (triangleIndex == 0) {
//        tOut[gid].v1.position = float4(-1.0, -1.0, 0.0, 1.0);
//        tOut[gid].v1.texCoord = float4(-1.0, -1.0, 0.0, 0.0);
//        tOut[gid].v2.position = float4(-1.0, 1.0, 0.0, 1.0);
//        tOut[gid].v2.texCoord = float4(-1.0, 1.0, 0.0, 0.0);
//        tOut[gid].v3.position = float4(1.0, 1.0, 0.0, 1.0);
//        tOut[gid].v3.texCoord = float4(1.0, 1.0, 0.0, 0.0);
//    } else {
//        tOut[gid].v1.position = float4(1.0, 1.0, 0.0, 1.0);
//        tOut[gid].v1.texCoord = float4(1.0, 1.0, 0.0, 0.0);
//        tOut[gid].v2.position = float4(1.0, -1.0, 0.0, 1.0);
//        tOut[gid].v2.texCoord = float4(1.0, -1.0, 0.0, 0.0);
//        tOut[gid].v3.position = float4(-1.0, -1.0, 0.0, 1.0);
//        tOut[gid].v3.texCoord = float4(-1.0, -1.0, 0.0, 0.0);
//    }
    
    // if i hardcode only vertex coordinate, i get a shape rendering,
    // - though it is apparently not correct
//    if (triangleIndex == 0) {
//        tOut[gid].v1.position = float4(-1.0, -1.0, 0.0, 1.0);
//        tOut[gid].v1.texCoord = qIn.D.texCoord;
//        tOut[gid].v2.position = float4(-1.0, 1.0, 0.0, 1.0);
//        tOut[gid].v2.texCoord = qIn.A.texCoord;
//        tOut[gid].v3.position = float4(1.0, 1.0, 0.0, 1.0);
//        tOut[gid].v3.texCoord = qIn.B.texCoord;
//    } else {
//        tOut[gid].v1.position = float4(1.0, 1.0, 0.0, 1.0);
//        tOut[gid].v1.texCoord = qIn.B.texCoord;
//        tOut[gid].v2.position = float4(1.0, -1.0, 0.0, 1.0);
//        tOut[gid].v2.texCoord = qIn.C.texCoord;
//        tOut[gid].v3.position = float4(-1.0, -1.0, 0.0, 1.0);
//        tOut[gid].v3.texCoord = qIn.D.texCoord;
//    }
    
    // if i try to set all the triangles to the same input for the quad
    // - all the floats returned are incredibly small
//    if (triangleIndex == 0) {
//        tOut[gid].v1.position = qIn.D.position;
//        tOut[gid].v1.texCoord = qIn.D.texCoord;
//        tOut[gid].v2.position = qIn.A.position;
//        tOut[gid].v2.texCoord = qIn.A.texCoord;
//        tOut[gid].v3.position = qIn.B.position;
//        tOut[gid].v3.texCoord = qIn.B.texCoord;
//    } else {
//        tOut[gid].v1.position = qIn.B.position;
//        tOut[gid].v1.texCoord = qIn.B.texCoord;
//        tOut[gid].v2.position = qIn.C.position;
//        tOut[gid].v2.texCoord = qIn.C.texCoord;
//        tOut[gid].v3.position = qIn.D.position;
//        tOut[gid].v3.texCoord = qIn.D.texCoord;
//    }

    // same thing
//    tOut[gid].v1.position = qIn.A.position;
//    tOut[gid].v1.texCoord = qIn.A.texCoord;
//    tOut[gid].v2.position = qIn.B.position;
//    tOut[gid].v2.texCoord = qIn.B.texCoord;
//    tOut[gid].v3.position = qIn.C.position;
//    tOut[gid].v3.texCoord = qIn.C.texCoord;
    
    // trying to render one triangle
//    tOut[0].v1.position = qIn.A.position;
//    tOut[0].v1.texCoord = qIn.A.texCoord;
//    tOut[0].v2.position = qIn.B.position;
//    tOut[0].v2.texCoord = qIn.B.texCoord;
//    tOut[0].v3.position = qIn.C.position;
//    tOut[0].v3.texCoord = qIn.C.texCoord;
//    
////    float4 v1pos = mix(qIn.A.position, qIn.B.position, )
//
    
    
    //============================================
    // here is original code
    //============================================
    
    float4 hDir = qIn.B.position - qIn.A.position;
    float4 hDirTexture = qIn.B.texCoord - qIn.A.texCoord;
    
    float4 vDir = qIn.D.position - qIn.A.position;
    float4 vDirTexture = qIn.D.texCoord - qIn.A.texCoord;
    
    float4 v1pos = findPointOnLine(qIn.A.position, hDir, vDir, quadColNumber, quadRowNumber + 1, bisectionInput.size.x, bisectionInput.size.y);
    float4 v1tex = findPointOnLine(qIn.A.texCoord, hDirTexture, vDirTexture, quadColNumber, quadRowNumber + 1, bisectionInput.size.x, bisectionInput.size.y);
    
    float4 v2pos = findPointOnLine(qIn.A.position, hDir, vDir, quadColNumber + 1, quadRowNumber, bisectionInput.size.x, bisectionInput.size.y);
    float4 v2tex = findPointOnLine(qIn.A.texCoord, hDirTexture, vDirTexture, quadColNumber + 1, quadRowNumber, bisectionInput.size.x, bisectionInput.size.y);
    
    // output only triangles with vertices in order ABC or BCD
    if (triangleIndex == 0) {  // then it's the top triangle
        float4 v3pos = findPointOnLine(qIn.A.position, hDir, vDir, quadColNumber, quadRowNumber, bisectionInput.size.x, bisectionInput.size.y);
        float4 v3tex = findPointOnLine(qIn.A.texCoord, hDirTexture, vDirTexture, quadColNumber, quadRowNumber, bisectionInput.size.x, bisectionInput.size.y);
        
        // output ABC triangle
        tOut[gid].v1.position = v1pos;
        tOut[gid].v1.texCoord = v1tex;
        tOut[gid].v2.position = v3pos;
        tOut[gid].v2.texCoord = v3tex;
        tOut[gid].v3.position = v2pos;
        tOut[gid].v3.texCoord = v2tex;
    } else { //  then it's the bottom triangle
        float4 v3pos = findPointOnLine(qIn.A.position, hDir, vDir, quadColNumber + 1, quadRowNumber + 1, bisectionInput.size.x, bisectionInput.size.y);
        float4 v3tex = findPointOnLine(qIn.A.texCoord, hDirTexture, vDirTexture, quadColNumber + 1, quadRowNumber + 1, bisectionInput.size.x, bisectionInput.size.y);
        
        // output BCD triangle
        tOut[gid].v1.position = v2pos;
        tOut[gid].v1.texCoord = v2tex;
        tOut[gid].v2.position = v3pos;
        tOut[gid].v2.texCoord = v3tex;
        tOut[gid].v3.position = v1pos;
        tOut[gid].v3.texCoord = v1tex;
    }
}


// generates an nxn square quadrilateral lattice
//kernel void nn2dLatticeGenerator


//kernel void rainbowNoise(texture2d<float, access::write> outTexture [[texture(0)]]
//                         uint id [[ thread_position_in_grid ]])