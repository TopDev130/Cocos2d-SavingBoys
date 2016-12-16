//
//  LevelSelectLayer.h
//  SavingBoys
//
//  Created by jds on 10/7/14.
//
//

#import "cocos2d.h"

@interface LevelSelectLayer : CCLayer
{
    CCSprite*           m_background;
    CCMenuItemImage*    m_level[20];
}

+(CCScene*) scene;
-(id)       init;

-(void) onBack;
-(void) onLevel:(id)sender;
-(void) onSound;
@end
