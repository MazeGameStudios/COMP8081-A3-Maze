#import <GLKit/GLKit.h>
#import <Foundation/Foundation.h>

@interface BaseEffect : NSObject

@property (nonatomic, assign) GLuint programHandle;
//@property (nonatomic, assign) GLKMatrix4 modelViewMatrix;


- (id) initWithVertexShader: (NSString *) vertexShader
             fragmentShader: (NSString *) fragmentShader;

- (void)prepareToDraw;

@end
