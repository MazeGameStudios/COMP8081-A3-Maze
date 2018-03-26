
#ifndef Renderer_h
#define Renderer_h
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/glext.h>
#include "BaseEffect.h"

@interface Renderer : GLKViewController //Originally NSO object

@property bool _isRotating;
@property bool _isMoving;
@property bool _cameraCollisionEnabled;

@property bool _spotlightToggle;
@property bool _fogToggle;
@property bool _fogUseExp;
@property bool _isDay;


- (void)setup:(GLKView *)view;
- (void)setupShaders;
- (void)update;
- (void)reset;
- (NSString*)getMinimap;
- (void)rotateCamera:(float)xDelta secondDelta:(float)zDelta;
- (void)translateCameraForward:(float)xDelta secondDelta:(float)zDelta;
- (void)draw:(CGRect)drawRect;

@end

#endif /* Renderer_h */
