//
// @author: Daniel Tian
// @date:   March 26, 2018
//
//

#import "Renderer.h"
#import <Foundation/Foundation.h>
#include <chrono>
#include <iostream>
#include <fstream>      // std::ifstream
#include <sstream>      // std::istringstream
#include <vector>
#include <iterator>
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
    
    GLuint floorTextureID;
    GLuint npcTextureID;
    GLuint textureSkyID;
    GLuint textureWallID, textureWallLeftID, textureWallRightID, textureWallBothID;
    
    //Camera, movement
    GLKMatrix4 Model, ViewMatrix, ProjectionMatrix;
    
    GLKVector3 position;

    float initialFoV;
    float moveSpeed;
    float rotationSensitivity;
    
    float cameraHorizontalRot;
    float cameraVerticalRot;
    
    float cameraX, cameraY, cameraZ;
    
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
    GLuint vertexbuffer2;     // buffers for 2nd obj
    GLuint normalbuffer2;
    GLuint uvBuffer2;
    GLuint elementBuffer2;

}

@end

@implementation Renderer

@synthesize _isMoving;
@synthesize _cameraCollisionEnabled;
@synthesize _spotlightToggle;
@synthesize _fogToggle;
@synthesize _fogUseExp;
@synthesize _isDay;
@synthesize npcRotY;

float collisionOffset = 0.9;
float edgeLength = 0.8; //length of a squares edge

const int mazeSize = 8;
const int mazeLength = mazeSize * 2 + 1;
const int mazeEntrance = (mazeSize % 2)?mazeSize: mazeSize - 1;
bool mazeArray[mazeLength][mazeLength];
int totalWalls = 0;

bool both, west, east;

float npcX = 0, npcZ = mazeEntrance, npcY = .4, npcSpeed = 3, npcScale = .4;
int maxMoveFrames = 120, currentFrames = 60;

const float MAX_DISTANCE_TO_PLAYER = 1.5;

typedef struct{
    float x;
    float z;
}MyVec2;

MyVec2 coordinates[mazeLength*mazeLength];

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
    
    GenerateMaze();
    
    //initial camera info
    cameraX = -4; cameraY = 1.5; cameraZ = mazeEntrance; cameraHorizontalRot = 1.6111011;
    position.x = 0; position.y = 0; position.z = 0; cubeScale = 1;
    initialFoV = 75.0; moveSpeed = .3; rotationSensitivity = 0.0005;
    
    _cameraCollisionEnabled = true;
    _isMoving = false;
    _isDay = true;
    
    //set clear color
    glClearColor(135.0/255.0, 206.0/255.0, 250.0/255.0, 1.0f);
    glGenVertexArraysOES(1, &VertexArrayID);
    glBindVertexArrayOES(VertexArrayID);
    // Enable depth test
    glEnable(GL_DEPTH_TEST);
    // Accept fragment if it closer to the camera than the former one
    glDepthFunc(GL_LESS);
    // Cull triangles which normal is not towards the camera
    glEnable(GL_CULL_FACE);
    
    
    //Setup collision for all walls of the maze
    int i = 0;
    for (size_t x = 0; x < sizeof(*mazeArray) / sizeof(**mazeArray); ++x){
        for (size_t z = 0; z < sizeof(mazeArray)  / sizeof(*mazeArray);  ++z) {
            if (!mazeArray[x][z]) {  //true = path, false = wall
                coordinates[i].x  = x;
                coordinates[i++].z = z;
            }
        }
    }
    
    [_shader prepareToDraw];

    glUniform1i(glGetUniformLocation(PROGRAM_HANDLE, "texSampler"), 0);
    glUniform1f(glGetUniformLocation(PROGRAM_HANDLE, "fogEnd"), 8.0);
    glUniform1f(glGetUniformLocation(PROGRAM_HANDLE, "fogDensity"), 0.25);
    glUniform1f(glGetUniformLocation(PROGRAM_HANDLE, "spotlightCutoff"), cosf(M_PI/12)); // cos(30deg / 2)
    glUniform4f(glGetUniformLocation(PROGRAM_HANDLE, "spotlightColor"), 0.5, 0.5, 0.5, 1.0);
    
    textureWallID = [self setupTexture:@"diamond.jpg"];
    textureWallLeftID = [self setupTexture:@"mc_gold.png"];
    textureWallRightID = [self setupTexture:@"mc_redstone.png"];
    textureWallBothID = [self setupTexture:@"greywall.jpg"];
    
    floorTextureID = [self setupTexture:@"realistic_stone.jpg"];
    textureSkyID = [self setupTexture:@"sky.jpg"];
    npcTextureID = [self setupTexture:@"diamond.jpg"];
    
    indices = [self setupVBO:@"cube_mit" vertexBuffer:vertexbuffer uvBuffer:uvBuffer normalBuffer:normalbuffer elementBuffer:elementBuffer];  //Walls and floor rendered as cubes with different textures and scale
    
    indices2 = [self setupVBO:@"dog" vertexBuffer:vertexbuffer2 uvBuffer:uvBuffer2 normalBuffer:normalbuffer2 elementBuffer:elementBuffer2]; //Our npc

    
}


- (void)update {
    
    //Projection matrix
    float aspect = (float)theView.drawableWidth / (float)theView.drawableHeight;
    ProjectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(initialFoV), aspect, 0.1, 1000.0);
    
    ViewMatrix = GLKMatrix4MakeYRotation(cameraHorizontalRot);
    //ViewMatrix = GLKMatrix4RotateX(ViewMatrix, cameraVerticalRot);
    ViewMatrix = GLKMatrix4Translate(ViewMatrix, -cameraX, -cameraY, -cameraZ);
    if(_isMoving) [self moveNPC];
}

-(void)spotlight_fog_uniforms{
    
    glUniform1i(glGetUniformLocation(PROGRAM_HANDLE, "spotlight"), _spotlightToggle);
    glUniform1i(glGetUniformLocation(PROGRAM_HANDLE, "fog"), _fogToggle);
    glUniform1i(glGetUniformLocation(PROGRAM_HANDLE, "fogUseExp"), _fogUseExp);
    if (_isDay) {
        glUniform4f(glGetUniformLocation(PROGRAM_HANDLE, "ambientColor"), 1,1,1, 1.000); //0.784, 0.706, 0.627, 1.000
        glUniform4f(glGetUniformLocation(PROGRAM_HANDLE, "fogColor"), 0.784, 0.706, 0.627, 1.000);
        glClearColor(135.0/255.0, 206.0/255.0, 250.0/255.0, 1.0f);
    } else {
        glUniform4f(glGetUniformLocation(PROGRAM_HANDLE, "ambientColor"), 0.250, 0.250, 0.500, 1.000);
        glUniform4f(glGetUniformLocation(PROGRAM_HANDLE, "fogColor"), 0.125, 0.125, 0.250, 1.000);
        glClearColor(0.125, 0.125, 0.251, 1.000);
    }
    
}

- (void)draw:(CGRect)drawRect; {
    [_shader prepareToDraw];
    [self spotlight_fog_uniforms];
    glClear ( GL_COLOR_BUFFER_BIT |GL_DEPTH_BUFFER_BIT );
    
    Model = GLKMatrix4Translate(GLKMatrix4Identity, 125, 100, mazeEntrance+50);
    Model = GLKMatrix4Scale(Model, 1, 600, 600);
    Model = GLKMatrix4RotateY(Model, 20);
    [self drawVBO_Cube:textureSkyID];
    
    
    Model = GLKMatrix4Translate(GLKMatrix4Identity, npcX, npcY, npcZ);
    Model = GLKMatrix4Scale(Model, npcScale, npcScale, npcScale);
    Model = GLKMatrix4RotateY(Model, npcRotY);
    [self drawVBO_Model:npcTextureID];
    
    
    for (int x = 0; x < sizeof(*mazeArray) / sizeof(**mazeArray); ++x){  //x = row, c = column -- +x is north, +z = east
        for (int z = 0; z < sizeof(mazeArray)  / sizeof(*mazeArray);  ++z) {
            
            if (mazeArray[x][z]) {  //true = floor, aka path
                
                Model = GLKMatrix4Scale(Model, 1, 1, 1);
                Model = GLKMatrix4Translate(GLKMatrix4Identity, x, 0, z);
                [self drawVBO_Cube:floorTextureID];
                
            }else{  //false = wall
                
                Model = GLKMatrix4Translate(GLKMatrix4Identity, x, 0, z);
                Model = GLKMatrix4Scale(Model, 1, 1, 1);    //floor will be a 1x.1x1 cube
                [self drawVBO_Cube:floorTextureID];
                
                Model = GLKMatrix4Translate(GLKMatrix4Identity, x, 1.5, z);
                Model = GLKMatrix4Scale(Model, 1, 2, 1);    //scale of maze wall, 1m by 1m, 2m in height
                
                //walls on both sides: a wall exists to the east and west of current wall. +z direction is east
                if(z-1 >= 0 && z+1 < mazeLength){
                    both = (!mazeArray[x][z-1] && !mazeArray[x][z+1]);
                }else{
                    both = false;
                }
                
                //walls on left side only - wall exists to the -z direction: west of current wall
                if(z-1 >= 0){
                    if(z == mazeLength-1){
                        west = (!mazeArray[x][z-1] && true); //false - current true - false --> wall to the left, but path on the right
                    }else{
                        west = (!mazeArray[x][z-1] && mazeArray[x][z+1]); //false - current true - false --> wall to the left, but path on the right
                    }
                }else{
                    west = false;
                }
                
                //walls on right side only - wall exists to the +z direction: east of current wall
                if(z+1 < mazeLength){
                   
                    if(z == 0){
                         east = (true && !mazeArray[x][z+1]); //true - current wall - false --> wall to the right, but path on the left
                    }else{
                         east = (mazeArray[x][z-1] && !mazeArray[x][z+1]); //true - current wall - false --> wall to the right, but path on the left
                    }
                }else{
                    east = false;
                }
                
                if(both){
                    [self drawVBO_Cube:textureWallBothID]; //wall on both sides (left and right)
                }
                else if(west){ //wall on the left only
                    [self drawVBO_Cube:textureWallLeftID];
                }
                else if(east){ //wall on the right only
                    [self drawVBO_Cube:textureWallRightID];
                }
                else{
                    [self drawVBO_Cube:textureWallID];
                }
                
                both = east = west = false;
            }
        }

    }
    
    
}

- (void)reset {
    cameraX = -4; cameraY = 1.5; cameraZ = mazeEntrance; cameraHorizontalRot = 1.6111011;
    npcX = 0; npcZ = mazeEntrance; npcRotY = 1.7; npcSpeed = 3; npcScale = 0.8;
    _isMoving = false;
}

- (void)rotateCamera:(float)xDelta secondDelta:(float)yDelta {
    //cameraVerticalRot += (yDelta * rotationSensitivity); rotates camera vertically
    cameraHorizontalRot -= xDelta * rotationSensitivity;
}


- (void)moveNPC{
    
    if(currentFrames++ >= maxMoveFrames){
        npcRotY = RandomFloat(0, 6.28055);
        currentFrames = 0;
    }
    
    if (npcRotY > 2 * M_PI) npcRotY -= 2 * M_PI;
    if (npcRotY < 0.0) npcRotY += 2 * M_PI;
    
    //check if npc is trying to leave one of two possible entrances
    if(npcX < 0){
        npcX = 0.1;
        npcRotY = RandomFloat(0, 6.28055);
        return;
    }else if(npcX > mazeLength){
        npcX = mazeLength-0.1;
        npcRotY = RandomFloat(0, 6.28055);
        return;
    }
    
    for(const MyVec2 &vec2 : coordinates){
        
        if(abs(npcX - vec2.x) < edgeLength && abs(npcZ - vec2.z ) < edgeLength){  //collided with something
            
            if(vec2.x == 0 && vec2.z == 0)  break;
            
            npcRotY = RandomFloat(0, 6.28055);
            
            if(abs(npcX - vec2.x) > abs(npcZ - vec2.z)){
                
                if(npcX > vec2.x) //hitting the wall from a greater x value
                    npcX = vec2.x + collisionOffset;
                if(npcX < vec2.x) //hitting wall from smaller x value
                    npcX = vec2.x - collisionOffset;
                
            }else{
                if(npcZ > vec2.z)  npcZ = vec2.z + collisionOffset;
                
                if(npcZ < vec2.z)  npcZ = vec2.z - collisionOffset;
            }
            
            return;
        }
    }
    
    npcZ -= cos(npcRotY) * npcSpeed * 0.01;
    npcX += sin(npcRotY) * npcSpeed * 0.01;
}


-(void) translateNPC:(float)xDelta secondDelta:(float)yDelta thirdDelta:(float)zDelta{
    npcZ += zDelta * npcSpeed * 0.01;
    npcY += yDelta * npcSpeed * 0.01;
    npcX += xDelta * npcSpeed * 0.01;
}

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
    
    if(_cameraCollisionEnabled){
        for(const MyVec2 &vec2 : coordinates){
            
            if(abs(cameraX - vec2.x) < edgeLength && abs(cameraZ - vec2.z ) < edgeLength){
                
                if(vec2.x == 0 && vec2.z == 0)  break;
                //NSLog(@"Currently colliding!");
                
                if(abs(cameraX - vec2.x) > abs(cameraZ - vec2.z)){
                    if(cameraX > vec2.x)//hitting the wall from a greater x value
                        cameraX = vec2.x + .9;
                    if(cameraX < vec2.x)//hitting wall from smaller x value
                        cameraX = vec2.x - .9;
                }else{
                    if(cameraZ > vec2.z)
                        cameraZ = vec2.z + .9;
                    if(cameraZ < vec2.z)
                        cameraZ = vec2.z - .9;
                }
                
                return;
            }
        }
    }
    
    cameraZ -= cos(cameraHorizontalRot) * zDelta * 0.001;
    cameraX += sin(cameraHorizontalRot) * zDelta * 0.001;
}

- (void)scaleModel:(float)scale{
    npcScale = scale;
}

- (bool) isSameCell{
    return (sqrt(pow(cameraX-npcX, 2) + pow(cameraZ-npcZ,2)  ) <= MAX_DISTANCE_TO_PLAYER); //if further than 1.5 distance, return false
}

float RandomFloat(float min, float max)
{
    assert(max > min);
    float random = ((float) rand()) / (float) RAND_MAX;
    
    //Example: generate a float between 0 and (4.5-.78)
    // then add .78, giving you a float between .78 and 4.5
    float range = max - min;
    return (random*range) + min;
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

- (void) drawVBO_Cube:(GLuint)textureID{
    
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


- (void) drawVBO_Model:(GLuint)textureID{
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
                 [string appendString:@"📷"]; //🎥 🚘 📷
            }else if(z == roundf(npcZ) && x == roundf(npcX)){
                 [string appendString:@"🐰"]; //🐇
            } else {
                if(mazeArray[x][z]){
                    [string appendString:@"  "];
                } else {
                    [string appendString:@"██"];
                }
            }
        }
        [string appendString:@"\n"];
    }
    return string;
}


void GenerateMaze() {
    mazeArray[0][mazeEntrance] = true;
    mazeArray[mazeLength - 1][mazeEntrance] = true;
    DepthFirstSearch(1, 1);
}

void DepthFirstSearch(int x, int y) {
    // Sets current cell as visited.
    mazeArray[x][y] = true;
    // Sets orderOfSearch to a random permutation of {0,1,2,3}.
    int orderOfSearch[] = { 0, 1, 2, 3 };
    for (int i = 0; i < 4; i++) {
        int r = arc4random() % (4 - i) + i;
        int temp = orderOfSearch[r];
        orderOfSearch[r] = orderOfSearch[i];
        orderOfSearch[i] = temp;
    }
    // Tries to visit cells to the North, East, South, and West in order of orderOfSearch.
    for (int i = 0; i < 4; i++) {
        if ((orderOfSearch[0] == i) && (y + 2 < mazeLength) && (!mazeArray[x][y + 2])) {
            mazeArray[x][y + 1] = true;
            DepthFirstSearch(x, y + 2);
        } else if ((orderOfSearch[1] == i) && (x + 2 < mazeLength) && (!mazeArray[x + 2][y])) {
            mazeArray[x + 1][y] = true;
            DepthFirstSearch(x + 2, y);
        } else if ((orderOfSearch[2] == i) && (y - 2 >= 0) && (!mazeArray[x][y - 2])) {
            mazeArray[x][y - 1] = true;
            DepthFirstSearch(x, y - 2);
        } else if ((orderOfSearch[3] == i) && (x - 2 >= 0) && (!mazeArray[x - 2][y])) {
            mazeArray[x - 1][y] = true;
            DepthFirstSearch(x - 2, y);
        }else{
            totalWalls++;
        }
    }
}

@end
