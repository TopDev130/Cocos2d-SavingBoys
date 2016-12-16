//
//  MenuLayer.h
//  SavingBoys
//
//  Created by jds on 10/9/14.
//
//

#import "cocos2d.h"

@interface MenuLayer : CCLayer
{
    CCSprite* background;
}
+(CCScene*) scene;
-(id)   init;

-(void) onStart;
-(void) onContinue;
-(void) onRate;
-(void) onSound;

@end
