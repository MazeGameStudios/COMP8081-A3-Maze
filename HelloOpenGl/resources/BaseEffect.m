//
//  BaseEffect.m
//  HelloOpenGL
//
//  Created by Daniel Tian on 2018-03-14.
//  Copyright © 2018 SwordArt. All rights reserved.
//

#import "BaseEffect.h"

@implementation BaseEffect{
    GLuint _programHandle;
    GLuint _modelViewProjectionMatrixUniform;
}

- (GLuint) compileShader: (NSString *) shaderName withType:(GLenum) shaderType{
    NSString * shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:nil];
    NSError * error;
    NSString * shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    
    if(!shaderString){
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    GLuint shaderHandle = glCreateShader(shaderType);
    
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if(compileSuccess == GL_FALSE){
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
}


- (void) compileVertexShader:(NSString *) vertexShader
              fragmentShader:(NSString *) fragmentShader{
    GLuint vertexShaderName = [self compileShader:vertexShader withType:GL_VERTEX_SHADER];
    GLuint fragmentShaderName = [self compileShader:fragmentShader withType:GL_FRAGMENT_SHADER];
    
    _programHandle = glCreateProgram(); //combination of a frag and vertex shader
    glAttachShader(_programHandle, vertexShaderName);   //attach 2 shaders - id for the vertex and frag shader objects.
    glAttachShader(_programHandle, fragmentShaderName);
    

    //glBindAttribLocation(_programHandle, VertexAttribPosition, "a_Position");
    //glBindAttribLocation(_programHandle, VertexAttribColor, "a_Color"); //c style string
    glLinkProgram(_programHandle);
    
    //self.modelViewMatrix = GLKMatrix4Identity;
    //_modelViewProjectionMatrixUniform = glGetUniformLocation(_programHandle, "u_modelViewProjectionMatrix");
    //printf("Matrix id is: %i", glGetUniformLocation(_programHandle, "position"));

    GLint linkSuccess;
    glGetProgramiv(_programHandle, GL_LINK_STATUS, &linkSuccess);
    
    if(linkSuccess == GL_FALSE){
        GLchar messages[256];
        glGetProgramInfoLog(_programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
}


- (void)prepareToDraw{
    glUseProgram(_programHandle);   //i want you to use this particular shader (vertex and fragment), cause your not limited to just one shader.
    //set uniforms?
}

- (instancetype)initWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *) fragmentShader{
    if((self = [super init])){
        [self compileVertexShader:vertexShader fragmentShader:fragmentShader];
    }
    return self;
}

@end













