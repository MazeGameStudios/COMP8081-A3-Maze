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
    /*
    //CGPoint location = [recognizer locationInView:[recognizer.view superview]];
    //glClearColor(0,.9,0, 1.0);
    if(tempVal == 0){
        red = 0;
        green = 1.0;
        blue = 0.0;
        
        scale = 1.0;
        tempVal = 1;
    }else if(tempVal == 1){
        red = 0;
        green = 0;
        blue = 1;
        scale = 2.0;
        tempVal = 2;
    }else if(tempVal == 2){
        red = 1;
        green = 0;
        blue = 0;
        tempVal++;
        scale = 3.0;
        tempVal = 0;
    }*/
}

//translate and rotate camera
- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint vel = [recognizer velocityInView:self.view];
    
    if(togglePan){ //rotate
        [myRenderer rotateCamera:vel.x secondDelta:vel.y];
    }else{  //translate cam
        [myRenderer translateCameraForward:vel.x secondDelta:vel.y];
    }

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

- (IBAction)togglePan:(id)sender {
    togglePan = !togglePan;
}

//looking around horizontally and vertically.
- (void)handleTwoFingerPan:(UIPanGestureRecognizer *)recognizer
{
    
}

@end



