//  Modified by Daniel Tian (February 13, 2018)
//

#ifndef Renderer_h
#define Renderer_h
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/glext.h>
#include "BaseEffect.h"

@interface Renderer : GLKViewController //Originally NSO object

@property bool _isRotating;

- (void)setup:(GLKView *)view;
- (void)setupShaders;
- (void)update;
- (void)rotateCamera:(float)xDelta secondDelta:(float)zDelta;
- (void)translateCameraForward:(float)xDelta secondDelta:(float)zDelta;
- (void)draw:(CGRect)drawRect;

@end

#endif /* Renderer_h */
