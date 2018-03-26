//
//  ViewController.h
//  HelloOpenGL
//
//  Created by SwordArt on 2018-02-12.
//  Copyright © 2018 SwordArt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseEffect.h"
#import "Renderer.h"

@interface ViewController : GLKViewController
@property (weak, nonatomic) IBOutlet UILabel *mapLabel;
@property (weak, nonatomic) IBOutlet UISlider *slider;


@end

