//
//  Modified by Daniel Tian (March 23, 2018)
//

#import "Renderer.h"
#import <Foundation/Foundation.h>
#include <chrono>
#include <iostream>
#include <fstream>      // std::ifstream
#include <sstream>      // std::istringstream
#include <vector>
using namespace std;

@interface Renderer () {
    BaseEffect *_shader;
    GLKView *theView;
    GLuint PROGRAM_HANDLE;

    GLuint VertexArrayID;
    GLuint vertexbuffer;     // This will identify our vertex buffer
    GLuint normalbuffer;
    GLuint uvBuffer;
    GLuint elementBuffer;
    GLuint textureID;
    GLuint npcTextureID;
    
    GLKMatrix4 mvp;
    
    //Camera, movement
    GLKMatrix4 Model, ViewMatrix, ProjectionMatrix;
    
    GLKVector3 direction;
    GLKVector3 position;
    GLKVector3 up;

    float initialFoV;
    float moveSpeed;
    float rotationSensitivity;
    
    float cameraHorizontalRot;
    float cameraVerticalRot;
    
    float cameraX, cameraY, cameraZ;
    
    float modelYRot; //y rotation for one of the cubes to use, for continuous rotation
    
    //for obj data
    vector< GLKVector3 > vertices;
    vector< GLKVector2 > uvs;
    vector< GLKVector3 > normals;
    vector<unsigned short> indices;
    
    vector< GLKVector3 > indexed_vertices;
    vector< GLKVector2 > indexed_uvs;
    vector< GLKVector3 > indexed_normals;
    
    float cubeScale;
    
    vector<unsigned short> indices2;
    GLuint textureIdWall;
    GLuint vertexbuffer2;     // buffers for 2nd obj
    GLuint normalbuffer2;
    GLuint uvBuffer2;
    GLuint elementBuffer2;
    
}

@end

@implementation Renderer

typedef struct{
    float x;
    float z;
}MyVec2;

static bool mazeArray[10][10] = {
    {true, true, true, true, false, true, true, true, true, true},
    {true, false, false, true, false, false, false, true, false, true},
    {true, true, false, false, false, true, true, true, false, true},
    {true, true, true, true, false, false, false, false, false, true},
    {true, false, false, false, false, true, true, false, true, true},
    {true, false, true, true, true, true, true, false, true, true},
    {true, false, true, true, true, false, true, false, true, true},
    {true, false, true, true, true, false, true, false, true, true},
    {true, false, false, false, false, false, true, false, true, true},
    {true, true, true, true, true, true, true, false, true, true},
};

const int mazeLength = 10;

MyVec2 coordinates[100];

- (void)dealloc {
    glDeleteProgram(PROGRAM_HANDLE);
}


- (void)setup:(GLKView *)view {
    
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (!view.context) {
        NSLog(@"Failed to create ES context");
    }
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    theView = view;
    [EAGLContext setCurrentContext:view.context];
    
    [self setupShaders];
    
    //initial camera info
    cameraX = 18; cameraY = 2; cameraZ = 8; cameraHorizontalRot = 174.445;
    position.x = 0; position.y = 0; position.z = 0; cubeScale = 2;
    initialFoV = 75.0; moveSpeed = .3; rotationSensitivity = 0.0005;
    
    //set clear color
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f); //0.0f, 0.0f, 0.35f, 0.0f
    glGenVertexArraysOES(1, &VertexArrayID);
    glBindVertexArrayOES(VertexArrayID);
    // Enable depth test
    glEnable(GL_DEPTH_TEST);
    // Accept fragment if it closer to the camera than the former one
    glDepthFunc(GL_LESS);
    // Cull triangles which normal is not towards the camera
    //glEnable(GL_CULL_FACE);
    
    textureIdWall = [self setupTexture:@"crate.jpg"];
    textureID = [self setupTexture:@"goldplate.jpg"]; //floor
    npcTextureID = [self setupTexture:@"rabbit.jpg"];
    
    indices = [self setupVBO:@"cube_mit" vertexBuffer:vertexbuffer uvBuffer:uvBuffer normalBuffer:normalbuffer elementBuffer:elementBuffer];  //walls
    
    indices2 = [self setupVBO:@"rabbit" vertexBuffer:vertexbuffer2 uvBuffer:uvBuffer2 normalBuffer:normalbuffer2 elementBuffer:elementBuffer2]; //npc
    
    int i = 0;
    
    for (size_t x = 0; x < sizeof(*mazeArray) / sizeof(**mazeArray); ++x){
        for (size_t z = 0; z < sizeof(mazeArray)  / sizeof(*mazeArray);  ++z) {
            if (mazeArray[x][z]) {  //wall
                coordinates[i].x  = x;
                coordinates[i++].z = z;
            }
        }
        
    }
    
}


- (void)update {
    /*
    
    //Model = GLKMatrix4Translate(GLKMatrix4Identity, position.x, position.y, position.z);
    //Model = GLKMatrix4RotateX(Model, modelYRot);
    //Model = GLKMatrix4Scale(Model, cubeScale, cubeScale, cubeScale);
    */
    modelYRot += 0.05f;
    //Projection matrix
    float aspect = (float)theView.drawableWidth / (float)theView.drawableHeight;
    ProjectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(initialFoV), aspect, 0.1, 100.0);
    
    ViewMatrix = GLKMatrix4MakeYRotation(cameraHorizontalRot);
    //ViewMatrix = GLKMatrix4RotateX(ViewMatrix, cameraVerticalRot);
    ViewMatrix = GLKMatrix4Translate(ViewMatrix, -cameraX, -cameraY, -cameraZ);
    
   //npcRotY += 0.05;
   [self moveNPC];
}

//float npcX = 8.5, npcZ = 7.2, npcRotY = 150;
float npcX = 10, npcZ = 9, npcRotY = 125, npcSpeed = 3;
- (void)moveNPC{
    
    if (npcRotY > 2 * M_PI) {
        npcRotY -= 2 * M_PI;
    }
    if (npcRotY < 0.0) {
        npcRotY += 2 * M_PI;
    }
    
     for(const MyVec2 &vec2 : coordinates){
         if(abs(npcX - vec2.x) < .8 && abs(npcZ - vec2.z ) < .8){
         
         NSLog(@"Currently colliding!");
         
         if(abs(npcX - vec2.x) > abs(npcZ - vec2.z)){
         if(npcX > vec2.x){ //hitting the wall from a greater x value
             npcX = vec2.x + 1;
         }
         
         if(npcX < vec2.x){ //hitting wall from smaller x value
             npcX = vec2.x - 1;
         }
         }else{
         
         if(npcZ > vec2.z){
             npcZ = vec2.z + 1;
         }
         
         if(npcZ < vec2.z){
             npcZ = vec2.z - 1;
         }
         }
         
         return;
         }
     }
    
    npcZ -= cos(npcRotY) * npcSpeed * 0.01;
    npcX += sin(npcRotY) * npcSpeed * 0.01;
}

- (void)draw:(CGRect)drawRect; {
    
    [_shader prepareToDraw];
    glClear ( GL_COLOR_BUFFER_BIT |GL_DEPTH_BUFFER_BIT );

    
    Model = GLKMatrix4Translate(GLKMatrix4Identity, npcX, .4, npcZ);
    Model = GLKMatrix4Scale(Model, .5, .5, .5);
    Model = GLKMatrix4RotateY(Model, npcRotY);
    [self drawVBO2:npcTextureID];
    
    
    for (size_t x = 0; x < sizeof(*mazeArray) / sizeof(**mazeArray); ++x){
        for (size_t z = 0; z < sizeof(mazeArray)  / sizeof(*mazeArray);  ++z) {
            if (mazeArray[x][z]) {  //wall
                
                //printf("drawing wall %lu %lu",x,z);
                
                Model = GLKMatrix4Translate(GLKMatrix4Identity, x, 0, z);
                Model = GLKMatrix4Scale(Model, 1, 1, 1);
                [self drawVBO1:textureID];
                
                Model = GLKMatrix4Translate(GLKMatrix4Identity, x, 1.5, z);
                Model = GLKMatrix4Scale(Model, 1, 2, 1);
                [self drawVBO1:textureIdWall];
                
            }else{ //just floor
                
                Model = GLKMatrix4Scale(Model, 1, 1, 1);
                Model = GLKMatrix4Translate(GLKMatrix4Identity, x, 0, z);
                [self drawVBO1:textureID];
            }
        }
        
    }
    
    
}

- (void)rotateCamera:(float)xDelta secondDelta:(float)yDelta {
    cameraVerticalRot += (yDelta * rotationSensitivity);
    cameraHorizontalRot -= xDelta * rotationSensitivity;
}


float r = 1; //length of every edge
//Point p1 is the center of one square, and p2 is of the other
//if (Math.abs(p1.x - p2.x) < r && Math.abs(p1.y - p2.y) < r){ collided!}
- (void)translateCameraForward:(float)xDelta secondDelta:(float)zDelta{
    
    if (cameraHorizontalRot > 2 * M_PI) {
        cameraHorizontalRot -= 2 * M_PI;
    }
    if (cameraHorizontalRot < 0.0) {
        cameraHorizontalRot += 2 * M_PI;
    }
    
    //NSLog(@"%f %f",cameraX, cameraZ);
    
    /*
    for(const MyVec2 &vec2 : coordinates){
        if(abs(cameraX - vec2.x) < .8 && abs(cameraZ - vec2.z ) < .8){
            
            NSLog(@"Currently colliding!");
            
            if(abs(cameraX - vec2.x) > abs(cameraZ - vec2.z)){
                if(cameraX > vec2.x){ //hitting the wall from a greater x value
                    cameraX = vec2.x + 1;
                }
                
                if(cameraX < vec2.x){ //hitting wall from smaller x value
                    cameraX = vec2.x - 1;
                }
            }else{
                
                if(cameraZ > vec2.z){
                    cameraZ = vec2.z + 1;
                }
                
                if(cameraZ < vec2.z){
                    cameraZ = vec2.z - 1;
                }
            }
 
            return;
        }
    } */
    
    cameraZ -= cos(cameraHorizontalRot) * zDelta * 0.001;
    cameraX += sin(cameraHorizontalRot) * zDelta * 0.001;
}

//sets up an vbo with data loaded in from an obj file
- (vector<unsigned short>) setupVBO:(NSString *) objFileName vertexBuffer:(GLuint &)outVertexBuffer
          uvBuffer:(GLuint &)outUvBuffer normalBuffer:(GLuint &)outNormalBuffer elementBuffer:(GLuint &)outElementBuffer{
    
    vector<unsigned short> tempIndices;
    
    //laod obj first
    [self loadOBJ:objFileName vs:vertices us:uvs ns:normals];
    
    indexVBO_slow(vertices, uvs, normals, tempIndices, indexed_vertices, indexed_uvs, indexed_normals);
    
    // Load it into a VBO
    glGenBuffers(1, &outVertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, outVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, indexed_vertices.size() * sizeof(GLKVector3), &indexed_vertices[0], GL_STATIC_DRAW);
    

    glGenBuffers(1, &outUvBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, outUvBuffer);
    glBufferData(GL_ARRAY_BUFFER, indexed_uvs.size() * sizeof(GLKVector2), &indexed_uvs[0], GL_STATIC_DRAW);
    
    
    glGenBuffers(1, &outNormalBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, outNormalBuffer);
    glBufferData(GL_ARRAY_BUFFER, indexed_normals.size() * sizeof(GLKVector3), &indexed_normals[0], GL_STATIC_DRAW);
    
    // Generate a buffer for the indices as well
    glGenBuffers(1, &outElementBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, outElementBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, tempIndices.size() * sizeof(unsigned short), &tempIndices[0] , GL_STATIC_DRAW);
    
    
    vertices.clear();
    uvs.clear();
    normals.clear();
    indexed_vertices.clear();
    indexed_uvs.clear();
    indexed_normals.clear();
    
    return tempIndices;
}

- (void) drawVBO1:(GLuint)textureID{
    
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    // Get a handle for our "MVP" uniform
    glUniformMatrix4fv(glGetUniformLocation(PROGRAM_HANDLE, "P"), 1, FALSE, (const float *)ProjectionMatrix.m);
    glUniformMatrix4fv(glGetUniformLocation(PROGRAM_HANDLE, "MV"), 1, FALSE, (const float *)GLKMatrix4Multiply(ViewMatrix, Model).m);

    
    // 1st attribute buffer : vertices
    glEnableVertexAttribArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
    glVertexAttribPointer(
                          0,                  // attribute 0. No particular reason for 0, but must match the layout in the shader.
                          3,                  // size
                          GL_FLOAT,           // type
                          GL_FALSE,           // normalized?
                          0,                  // stride
                          (void*)0             // array buffer offset
                          );
    
    glEnableVertexAttribArray(1); glBindBuffer(GL_ARRAY_BUFFER, uvBuffer); glVertexAttribPointer(1,2,GL_FLOAT,  GL_FALSE, 0,(void*)0 );
    
    // Index buffer
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBuffer);
    
    // Draw the triangles !
    glDrawElements(
                   GL_TRIANGLES,      // mode
                   (int)indices.size(),    // count
                   GL_UNSIGNED_SHORT,   // type
                   (void*)0           // element array buffer offset
                   );
    
    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
}


- (void) drawVBO2:(GLuint)textureID{
    glBindTexture(GL_TEXTURE_2D, textureID);
    
    
    // Get a handle for our "MVP" uniform
    glUniformMatrix4fv(glGetUniformLocation(PROGRAM_HANDLE, "P"), 1, FALSE, (const float *)ProjectionMatrix.m);
    glUniformMatrix4fv(glGetUniformLocation(PROGRAM_HANDLE, "MV"), 1, FALSE, (const float *)GLKMatrix4Multiply(ViewMatrix, Model).m);
    
    glEnableVertexAttribArray(0); glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer2); glVertexAttribPointer(0,3,GL_FLOAT,  GL_FALSE, 0,(void*)0 );
    glEnableVertexAttribArray(1); glBindBuffer(GL_ARRAY_BUFFER, uvBuffer2); glVertexAttribPointer(1,2,GL_FLOAT,  GL_FALSE, 0,(void*)0 );
    
    // Index buffer
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBuffer2);
    
    // Draw the triangles !
    glDrawElements(
                   GL_TRIANGLES,      // mode
                   (int)indices2.size(),    // count
                   GL_UNSIGNED_SHORT,   // type
                   (void*)0           // element array buffer offset
                   );
    
    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
}

- (void)setupShaders {
    _shader = [[BaseEffect alloc] initWithVertexShader:@"SimpleVertex.glsl" fragmentShader:@"SimpleFragment.glsl"];
    PROGRAM_HANDLE = _shader.programHandle;
}

// Load in and set up texture image (adapted from Ray Wenderlich)
- (GLuint)setupTexture:(NSString *)fileName {
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return texName;
}


- (bool)loadOBJ:(NSString*)fileName vs:(vector<GLKVector3>&)out_vertices
             us:(vector<GLKVector2>&)out_uvs
             ns:(vector<GLKVector3>&)out_normals{
    
    vector< unsigned int > vertexIndices, uvIndices, normalIndices;
    vector< GLKVector3 > temp_vertices;
    vector< GLKVector2 > temp_uvs;
    vector< GLKVector3 > temp_normals;
    
    
    NSString* filePath = [[NSBundle mainBundle] pathForResource:fileName
                                                         ofType:@"obj"];
    
    FILE * file = fopen([filePath UTF8String], "r");
    if( file == NULL ){
        printf("Impossible to open the file !\n");
        return false;
    }
    
    
    while( 1 ){
        
        char lineHeader[128];
        // read the first word of the line
        int res = fscanf(file, "%s", lineHeader);
        if (res == EOF)
            break; // EOF = End Of File. Quit the loop.
        
        // else : parse lineHeader
        
        if ( strcmp( lineHeader, "v" ) == 0 ){
            GLKVector3 vertex;
            fscanf(file, "%f %f %f\n", &vertex.x, &vertex.y, &vertex.z );
            temp_vertices.push_back(vertex);
        }else if( strcmp( lineHeader, "vt" ) == 0){
            GLKVector2 uv;
            fscanf(file, "%f %f\n", &uv.x, &uv.y );
            temp_uvs.push_back(uv);
        }else if ( strcmp( lineHeader, "vn" ) == 0 ){
            GLKVector3 normal;
            fscanf(file, "%f %f %f\n", &normal.x, &normal.y, &normal.z );
            temp_normals.push_back(normal);
        }else if ( strcmp( lineHeader, "f" ) == 0 ){
            
            std::string vertex1, vertex2, vertex3;
            unsigned int vertexIndex[3], uvIndex[3], normalIndex[3];
            int matches = fscanf(file, "%d/%d/%d %d/%d/%d %d/%d/%d\n", &vertexIndex[0], &uvIndex[0], &normalIndex[0], &vertexIndex[1], &uvIndex[1], &normalIndex[1], &vertexIndex[2], &uvIndex[2], &normalIndex[2] );
            if (matches != 9){
                printf("File can't be read by this simple parser\nTry exporting from blender with the following options:1. Apply modifiers 2.Include Normals 3.Include UVs 4. Triangulate faces 5.Objects as OBJ Objects\n");
                return false;
            }
            
            vertexIndices.push_back(vertexIndex[0]);
            vertexIndices.push_back(vertexIndex[1]);
            vertexIndices.push_back(vertexIndex[2]);
            uvIndices    .push_back(uvIndex[0]);
            uvIndices    .push_back(uvIndex[1]);
            uvIndices    .push_back(uvIndex[2]);
            normalIndices.push_back(normalIndex[0]);
            normalIndices.push_back(normalIndex[1]);
            normalIndices.push_back(normalIndex[2]);
        }
    }
    
    for(unsigned int i=0; i<vertexIndices.size(); i++ ){
        unsigned int vertexIndex = vertexIndices[i];
        GLKVector3 vertex = temp_vertices[ vertexIndex-1 ];
        out_vertices.push_back(vertex);
    }
    
    for(unsigned int i=0; i<uvIndices.size(); i++ ){
        unsigned int uvIndex = uvIndices[i];
        GLKVector2 uv = temp_uvs[ uvIndex-1 ];
        out_uvs.push_back(uv);
    }
    
    for(unsigned int i=0; i<normalIndices.size(); i++ ){
        unsigned int normalIndex = normalIndices[i];
        GLKVector3 normal = temp_normals[ normalIndex-1 ];
        out_normals.push_back(normal);
    }
    
    return true;
}

// Returns true if v1 can be considered equal to v2
bool is_near(float v1, float v2){
    return fabs( v1-v2 ) < 0.01f;
}

// Searches through all already-exported vertices
// for a similar one.
// Similar = same position + same UVs + same normal
bool getSimilarVertexIndex(
                           GLKVector3 & in_vertex,
                           GLKVector2 & in_uv,
                           GLKVector3 & in_normal,
                           std::vector<GLKVector3> & out_vertices,
                           std::vector<GLKVector2> & out_uvs,
                           std::vector<GLKVector3> & out_normals,
                           unsigned short & result
                           ){
    // Lame linear search
    for ( unsigned int i=0; i<out_vertices.size(); i++ ){
        if (
            is_near( in_vertex.x , out_vertices[i].x ) &&
            is_near( in_vertex.y , out_vertices[i].y ) &&
            is_near( in_vertex.z , out_vertices[i].z ) &&
            is_near( in_uv.x     , out_uvs     [i].x ) &&
            is_near( in_uv.y     , out_uvs     [i].y ) &&
            is_near( in_normal.x , out_normals [i].x ) &&
            is_near( in_normal.y , out_normals [i].y ) &&
            is_near( in_normal.z , out_normals [i].z )
            ){
            result = i;
            return true;
        }
    }
    // No other vertex could be used instead.
    // Looks like we'll have to add it to the VBO.
    return false;
}

void indexVBO_slow(
                   std::vector<GLKVector3> & in_vertices,
                   std::vector<GLKVector2> & in_uvs,
                   std::vector<GLKVector3> & in_normals,
                   
                   std::vector<unsigned short> & out_indices,
                   std::vector<GLKVector3> & out_vertices,
                   std::vector<GLKVector2> & out_uvs,
                   std::vector<GLKVector3> & out_normals
                   ){
    // For each input vertex
    for ( unsigned int i=0; i<in_vertices.size(); i++ ){
        
        // Try to find a similar vertex in out_XXXX
        unsigned short index;
        bool found = getSimilarVertexIndex(in_vertices[i], in_uvs[i], in_normals[i],     out_vertices, out_uvs, out_normals, index);
        
        if ( found ){ // A similar vertex is already in the VBO, use it instead !
            out_indices.push_back( index );
        }else{ // If not, it needs to be added in the output data.
            out_vertices.push_back( in_vertices[i]);
            out_uvs     .push_back( in_uvs[i]);
            out_normals .push_back( in_normals[i]);
            out_indices .push_back( (unsigned short)out_vertices.size() - 1 );
        }
    }
}

- (NSString*)getMinimap {
    NSMutableString *string = [NSMutableString string];
    for(int x = 0; x < mazeLength; x++){
        for(int z = 0; z < mazeLength; z++){
           
            if (z == roundf(cameraZ) && x == roundf(cameraX)) {
                float rotDegrees = GLKMathRadiansToDegrees(cameraHorizontalRot);
                if (rotDegrees > 337.5 || rotDegrees <= 22.5) {
                    [string appendString:@"@↓"];
                } else if (rotDegrees > 22.5 && rotDegrees <= 67.5) {
                    [string appendString:@"@↘"];
                } else if (rotDegrees > 67.5 && rotDegrees <= 112.5) {
                    [string appendString:@"@→"];
                } else if (rotDegrees > 112.5 && rotDegrees <= 157.5) {
                    [string appendString:@"@↗"];
                } else if (rotDegrees > 157.5 && rotDegrees <= 202.5) {
                    [string appendString:@"@↑"];
                } else if (rotDegrees > 202.5 && rotDegrees <= 247.5) {
                    [string appendString:@"@↖"];
                } else if (rotDegrees > 247.5 && rotDegrees <= 292.5) {
                    [string appendString:@"@←"];
                } else if (rotDegrees > 292.5 && rotDegrees <= 337.5) {
                    [string appendString:@"@↙"];
                }
            } else {
                if(mazeArray[x][z]){
                    //[string appendString:@"  "];
                    [string appendString:@"#"];
                } else {
                    //[string appendString:@"██"];
                    [string appendString:@"*"];
                }
            }
        }
        [string appendString:@"\n"];
    }
    return string;
}

@end

/*

// An array of 3 vectors which represents 3 vertices
static const GLfloat g_vertex_buffer_data[] = {
    -1.0f,-1.0f,-1.0f, // triangle 1 : begin
    -1.0f,-1.0f, 1.0f,
    -1.0f, 1.0f, 1.0f, // triangle 1 : end
    1.0f, 1.0f,-1.0f,  // triangle 2 : begin
    -1.0f,-1.0f,-1.0f,
    -1.0f, 1.0f,-1.0f, // triangle 2 : end
    1.0f,-1.0f, 1.0f,
    -1.0f,-1.0f,-1.0f,
    1.0f,-1.0f,-1.0f,
    1.0f, 1.0f,-1.0f,
    1.0f,-1.0f,-1.0f,
    -1.0f,-1.0f,-1.0f,
    -1.0f,-1.0f,-1.0f,
    -1.0f, 1.0f, 1.0f,
    -1.0f, 1.0f,-1.0f,
    1.0f,-1.0f, 1.0f,
    -1.0f,-1.0f, 1.0f,
    -1.0f,-1.0f,-1.0f,
    -1.0f, 1.0f, 1.0f,
    -1.0f,-1.0f, 1.0f,
    1.0f,-1.0f, 1.0f,
    1.0f, 1.0f, 1.0f,
    1.0f,-1.0f,-1.0f,
    1.0f, 1.0f,-1.0f,
    1.0f,-1.0f,-1.0f,
    1.0f, 1.0f, 1.0f,
    1.0f,-1.0f, 1.0f,
    1.0f, 1.0f, 1.0f,
    1.0f, 1.0f,-1.0f,
    -1.0f, 1.0f,-1.0f,
    1.0f, 1.0f, 1.0f,
    -1.0f, 1.0f,-1.0f,
    -1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f,
    -1.0f, 1.0f, 1.0f,
    1.0f,-1.0f, 1.0f
};

// One color for each vertex. They were generated randomly.
static const GLfloat g_color_buffer_data[] = {
    0.583f,  0.771f,  0.014f,
    0.609f,  0.115f,  0.436f,
    0.327f,  0.483f,  0.844f,
    0.822f,  0.569f,  0.201f,
    0.435f,  0.602f,  0.223f,
    0.310f,  0.747f,  0.185f,
    0.597f,  0.770f,  0.761f,
    0.559f,  0.436f,  0.730f,
    0.359f,  0.583f,  0.152f,
    0.483f,  0.596f,  0.789f,
    0.559f,  0.861f,  0.639f,
    0.195f,  0.548f,  0.859f,
    0.014f,  0.184f,  0.576f,
    0.771f,  0.328f,  0.970f,
    0.406f,  0.615f,  0.116f,
    0.676f,  0.977f,  0.133f,
    0.971f,  0.572f,  0.833f,
    0.140f,  0.616f,  0.489f,
    0.997f,  0.513f,  0.064f,
    0.945f,  0.719f,  0.592f,
    0.543f,  0.021f,  0.978f,
    0.279f,  0.317f,  0.505f,
    0.167f,  0.620f,  0.077f,
    0.347f,  0.857f,  0.137f,
    0.055f,  0.953f,  0.042f,
    0.714f,  0.505f,  0.345f,
    0.783f,  0.290f,  0.734f,
    0.722f,  0.645f,  0.174f,
    0.302f,  0.455f,  0.848f,
    0.225f,  0.587f,  0.040f,
    0.517f,  0.713f,  0.338f,
    0.053f,  0.959f,  0.120f,
    0.393f,  0.621f,  0.362f,
    0.673f,  0.211f,  0.457f,
    0.820f,  0.883f,  0.371f,
    0.982f,  0.099f,  0.879f
};

// Two UV coordinatesfor each vertex. They were created with Blender. You'll need to learn this yourself.
static const GLfloat g_uv_buffer_data[] = {
    0.000059f, 1.0f-0.000004f,
    0.000103f, 1.0f-0.336048f,
    0.335973f, 1.0f-0.335903f,
    1.000023f, 1.0f-0.000013f,
    0.667979f, 1.0f-0.335851f,
    0.999958f, 1.0f-0.336064f,
    0.667979f, 1.0f-0.335851f,
    0.336024f, 1.0f-0.671877f,
    0.667969f, 1.0f-0.671889f,
    1.000023f, 1.0f-0.000013f,
    0.668104f, 1.0f-0.000013f,
    0.667979f, 1.0f-0.335851f,
    0.000059f, 1.0f-0.000004f,
    0.335973f, 1.0f-0.335903f,
    0.336098f, 1.0f-0.000071f,
    0.667979f, 1.0f-0.335851f,
    0.335973f, 1.0f-0.335903f,
    0.336024f, 1.0f-0.671877f,
    1.000004f, 1.0f-0.671847f,
    0.999958f, 1.0f-0.336064f,
    0.667979f, 1.0f-0.335851f,
    0.668104f, 1.0f-0.000013f,
    0.335973f, 1.0f-0.335903f,
    0.667979f, 1.0f-0.335851f,
    0.335973f, 1.0f-0.335903f,
    0.668104f, 1.0f-0.000013f,
    0.336098f, 1.0f-0.000071f,
    0.000103f, 1.0f-0.336048f,
    0.000004f, 1.0f-0.671870f,
    0.336024f, 1.0f-0.671877f,
    0.000103f, 1.0f-0.336048f,
    0.336024f, 1.0f-0.671877f,
    0.335973f, 1.0f-0.335903f,
    0.667969f, 1.0f-0.671889f,
    1.000004f, 1.0f-0.671847f,
    0.667979f, 1.0f-0.335851f
};
 
 
 - (void) setupCube1{
 // Generate 1 buffer, put the resulting identifier in vertexbuffer
 glGenBuffers(1, &vertexbuffer);
 // The following commands will talk about our 'vertexbuffer' buffer
 glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
 // Give our vertices to OpenGL.
 glBufferData(GL_ARRAY_BUFFER, sizeof(g_vertex_buffer_data), g_vertex_buffer_data, GL_STATIC_DRAW);
 
 //Generate color buffer
 glGenBuffers(1, &colorbuffer);
 glBindBuffer(GL_ARRAY_BUFFER, colorbuffer);
 glBufferData(GL_ARRAY_BUFFER, sizeof(g_color_buffer_data), g_color_buffer_data, GL_STATIC_DRAW);
 
 }

 - (void) drawCube1{
 
 glUniformMatrix4fv(glGetUniformLocation(PROGRAM_HANDLE, "P"), 1, FALSE, (const float *)ProjectionMatrix.m);
 glUniformMatrix4fv(glGetUniformLocation(PROGRAM_HANDLE, "MV"), 1, FALSE, (const float *)GLKMatrix4Multiply(ViewMatrix, Model).m);
 
 
 // 1st attribute buffer : vertices
 glEnableVertexAttribArray(0);
 glBindBuffer(GL_ARRAY_BUFFER, vertexbuffer);
 glVertexAttribPointer(
 0,                  // attribute 0. No particular reason for 0, but must match the layout in the shader.
 3,                  // size
 GL_FLOAT,           // type
 GL_FALSE,           // normalized?
 0,                  // stride
 (void*)0            // array buffer offset
 );
 
 
 //glEnableVertexAttribArray(1); glBindBuffer(GL_ARRAY_BUFFER, textureID); glVertexAttribPointer(1,2,GL_FLOAT,  GL_FALSE, 0,(void*)0 );
 glEnableVertexAttribArray(1); glBindBuffer(GL_ARRAY_BUFFER, uvBuffer); glVertexAttribPointer(1,2,GL_FLOAT,  GL_FALSE, 0,(void*)0 );
 
 // Draw
 glDrawArrays(GL_TRIANGLES, 0, vertices.size()); // Starting from vertex 0; 3 vertices total -> 1 triangle
 //glDrawElements(GL_TRIANGLES, vertices.size() / sizeof(GLKVector3), GL_FLOAT, 0);
 glDisableVertexAttribArray(0);
 glDisableVertexAttribArray(1);
 }
 
*/
