#import "ViewController.h"

@interface ViewController (){
    Renderer *myRenderer;
    bool displayMinimap;
}
@end

@implementation ViewController

float delta_x = 0, delta_y = 0, delta_z = 0;
float translationVal = 2.0;

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
     //Single tap handler
     UITapGestureRecognizer *singleFingerTap =
     [[UITapGestureRecognizer alloc] initWithTarget:self
     action:@selector(handleSingleTap:)];
     [self.view addGestureRecognizer:singleFingerTap];
     
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
   
    displayMinimap = true;
}


- (void)update
{
    [myRenderer update];
    _mapLabel.text = (displayMinimap)?[myRenderer getMinimap]:@"";
     [myRenderer translateNPC:delta_x secondDelta:delta_y thirdDelta:delta_z];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
     [myRenderer draw:rect];
}

//toggles npc ai movement via double tap
- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
    myRenderer._isMoving = !myRenderer._isMoving;
}

//Camera transformations
- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint vel = [recognizer velocityInView:self.view];
    [myRenderer rotateCamera:vel.x secondDelta:vel.y];
    [myRenderer translateCameraForward:vel.x secondDelta:vel.y];
}

- (IBAction)btn1Handler:(id)sender { //toggle camera collision
    myRenderer._cameraCollisionEnabled = !myRenderer._cameraCollisionEnabled;
    if(myRenderer._cameraCollisionEnabled){
      [sender setTitle:@"camCollide" forState:UIControlStateNormal];
    }else{
      [sender setTitle:@"!camCollide" forState:UIControlStateNormal];
    }
    
}

- (IBAction)btn2Handler:(id)sender { //toggle minimap
    displayMinimap = !displayMinimap;
    if(displayMinimap){
        [sender setTitle:@"minimap" forState:UIControlStateNormal];
    }else{
        [sender setTitle:@"!minimap" forState:UIControlStateNormal];
    }
}


- (IBAction)btn5Handler:(id)sender { //reset
    [myRenderer reset];
    delta_x = delta_z = delta_y = 0;
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

//scale npc
- (IBAction)sliderHandler1:(id)sender {
    if(myRenderer._isMoving || ![myRenderer isSameCell]) return;
    //NSLog(@"SliderValue ... %@",[NSString stringWithFormat:@"%f", self.slider.value]);
    [myRenderer scaleModel:self.slider.value];
}

- (IBAction)translateNpcx:(id)sender {
    if(myRenderer._isMoving) return; //if not stationary, return
    
    if(self.xSlider.value < -1){ //translate x in negative direction
        delta_x = -translationVal;
    }else if(self.xSlider.value > 1){
        delta_x = translationVal;
    }else{
        delta_x = 0;
    }
}

- (IBAction)translateNpcY:(id)sender {
    if(myRenderer._isMoving) return;
    
    if(self.ySlider.value < -1){ //translate y in negative direction
        delta_y = -translationVal;
    }else if(self.ySlider.value > 1){
        delta_y = translationVal;
    }else{
        delta_y = 0;
    }
}

- (IBAction)translateNpcZ:(id)sender {
    
    if(myRenderer._isMoving) return;
    
    if(self.zSlider.value < -1){ //translate z in negative direction
        delta_z = -translationVal;
    }else if(self.zSlider.value > 1){
        delta_z = translationVal;
    }else{
        delta_z = 0;
    }
    
}

- (IBAction)rotateNpc:(id)sender {
    
     if(myRenderer._isMoving || ![myRenderer isSameCell]) return;
    
    [myRenderer setNpcRotY:self.rotationSlider.value];

}


/* Tap gestures currently empty, to be implemented if needed */
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
}

- (void)handleTwoFingerPan:(UIPanGestureRecognizer *)recognizer
{
}

@end



























