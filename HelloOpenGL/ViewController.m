#import "ViewController.h"

@interface ViewController (){
    Renderer *myRenderer;
    bool togglePan;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Single tap handler
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:singleFingerTap];
    
    //Single finger double tap
    UITapGestureRecognizer *doubleTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [doubleTap setNumberOfTouchesRequired:1];
    [self.view addGestureRecognizer:doubleTap];
    
    //handles panning
    UIPanGestureRecognizer *panning =
    [[UIPanGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handlePan:)];
    [self.view addGestureRecognizer:panning];
    
    /*
    UIPanGestureRecognizer *twoFingerPan =
    [[UIPanGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleTwoFingerPan:)];
    twoFingerPan.delegate = self;
    twoFingerPan.minimumNumberOfTouches = 2;
    twoFingerPan.maximumNumberOfTouches = 2;
    [self.view addGestureRecognizer:twoFingerPan]; */
    
    
    //Setup open gl context
    myRenderer = [[Renderer alloc] init];
    GLKView *view = (GLKView *)self.view;
    [myRenderer setup:view];
    
    togglePan = true;
}


- (void)update
{
    [myRenderer update];
    _mapLabel.text = [myRenderer getMinimap];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    
     [myRenderer draw:rect];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
}

//
- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer { //toggles npc movement
    myRenderer._isMoving = !myRenderer._isMoving;
}

//translate and rotate camera
- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint vel = [recognizer velocityInView:self.view];
    
    [myRenderer rotateCamera:vel.x secondDelta:vel.y];
    [myRenderer translateCameraForward:vel.x secondDelta:vel.y];
    /*
     if( fabs( vel.x) > fabs( vel.y) ){
     if (vel.x > 0)
     {
     // user dragged towards the right
     //[glesRenderer translateRect:(translationDelta) secondDelta:(0.0f)];
     }
     else{
     // user dragged towards the left
     }
     }else{
     if(vel.y < 0){
     //up
     }
     else{
     //down
     }
     }
    */
}

//looking around horizontally and vertically.
- (void)handleTwoFingerPan:(UIPanGestureRecognizer *)recognizer
{
    
}

- (IBAction)btn1Handler:(id)sender { //toggle camera collision
    myRenderer._cameraCollisionEnabled = !myRenderer._cameraCollisionEnabled;
    if(myRenderer._cameraCollisionEnabled){
      [sender setTitle:@"cam collision" forState:UIControlStateNormal];
    }else{
      [sender setTitle:@"!cam collision" forState:UIControlStateNormal];
    }
    
}

- (IBAction)btn2Handler:(id)sender { //enables npc movement
    //myRenderer._isMoving = !myRenderer._isMoving;
}

- (IBAction)btn3Handler:(id)sender { //Toggles npc rotation
    if(!myRenderer._isMoving)
        myRenderer._isRotating = !myRenderer._isRotating;
}

- (IBAction)btn4Handler:(id)sender {
}

- (IBAction)btn5Handler:(id)sender { //reset
    [myRenderer reset];
}

- (IBAction)dayToggleBtn:(id)sender {
    myRenderer._isDay = !myRenderer._isDay;
    if(myRenderer._isDay){
        [sender setTitle:@"day" forState:UIControlStateNormal];
    }else{
        [sender setTitle:@"night" forState:UIControlStateNormal];
    }
}

- (IBAction)spotlightToggle:(id)sender {
    myRenderer._spotlightToggle = !myRenderer._spotlightToggle;
    if(myRenderer._spotlightToggle){
        [sender setTitle:@"spotlight" forState:UIControlStateNormal];
    }else{
        [sender setTitle:@"!spotlight" forState:UIControlStateNormal];
    }
}

- (IBAction)fogToggle:(id)sender {
    myRenderer._fogToggle = !myRenderer._fogToggle;
    if(myRenderer._fogToggle){
        [sender setTitle:@"fog" forState:UIControlStateNormal];
    }else{
        [sender setTitle:@"!fog" forState:UIControlStateNormal];
    }
}

- (IBAction)fogExpToggle:(id)sender {
    myRenderer._fogUseExp = !myRenderer._fogUseExp;
    if(myRenderer._fogUseExp){
        [sender setTitle:@"fog exp" forState:UIControlStateNormal];
    }else{
        [sender setTitle:@"!fog exp" forState:UIControlStateNormal];
    }
}

- (IBAction)sliderHandler1:(id)sender {

    NSLog(@"SliderValue ... %@",[NSString stringWithFormat:@"%f", self.slider.value]);
}

@end



























