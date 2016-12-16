//
//  MenuLayer.m
//  SavingBoys
//
//  Created by admin on 10/9/14.
//
//

#import "MenuLayer.h"
#import "GameLayer.h"
#import "LevelSelectLayer.h"

@implementation MenuLayer

+(CCScene*) scene
{
    CCScene* pScene = [CCScene node];
    MenuLayer* pLayer = [MenuLayer node];
    [pScene addChild:pLayer];
    return pScene;
}

-(id) init
{
    self = [super init];
    if (self)
    {
        CGSize size = [[CCDirector sharedDirector] winSize];
        
        background = [CCSprite spriteWithFile:@"main_bg.png"];
        float bgWidth = background.contentSize.width;
        float bgHeight = background.contentSize.height;
        float scaleX = size.width / bgWidth;
        float scaleY = size.height / bgHeight;
        [background setScaleX:scaleX];
        [background setScaleY:scaleY];
        [background setPosition:ccp(size.width / 2, size.height / 2)];
        [self addChild:background];
        
        CCSprite *sprTitle = [CCSprite spriteWithFile:@"main_title.png"];
        [sprTitle setPosition:ccp(bgWidth/2, bgHeight * 0.7f)];
        [background addChild:sprTitle];
        
        CCSprite * sprStar = [CCSprite spriteWithFile:@"main_star.png"];
        [sprStar setPosition:ccp(bgWidth / 2, bgHeight * 0.7f)];
        [background addChild:sprStar];
        
        [sprStar runAction:[CCRepeatForever actionWithAction:
                           [CCSequence actions:
                            [CCDelayTime actionWithDuration:1],
                            [CCFadeOut actionWithDuration:1],
                            [CCDelayTime actionWithDuration:0.5f],
                            [CCFadeIn actionWithDuration:1],
                            nil]]];
        
        CCMenuItemImage* itemSoundOff = [CCMenuItemImage itemFromNormalImage:@"menu_sound.png" selectedImage:@"menu_sound_disable.png"];
        CCMenuItemImage* itemSoundOn = [CCMenuItemImage itemFromNormalImage:@"menu_sound_disable.png" selectedImage:@"menu_sound.png"];
        CCMenuItemToggle* btnSound = [CCMenuItemToggle itemWithTarget:self selector:@selector(onSound) items:itemSoundOff, itemSoundOn, nil];
        [btnSound setPosition:ccp(bgWidth * 0.93f, bgHeight * 0.92f)];
        
        CCMenuItemImage* btnStart = [CCMenuItemImage itemFromNormalImage:@"menu_start.png" selectedImage:@"menu_start_sel.png" target:self selector:@selector(onStart)];
        CCMenuItemImage* btnContinue = [CCMenuItemImage itemFromNormalImage:@"menu_continue.png" selectedImage:@"menu_continue_sel.png" target:self selector:@selector(onContinue)];
        CCMenuItemImage* btnRate = [CCMenuItemImage itemFromNormalImage:@"menu_rate.png" selectedImage:@"menu_rate_sel.png" target:self selector:@selector(onRate)];
        [btnStart setPosition:ccp(bgWidth / 2, bgHeight * 0.42)];
        [btnContinue setPosition:ccp(bgWidth / 2, bgHeight * 0.3)];
        [btnRate setPosition:ccp(bgWidth / 2, bgHeight * 0.18)];
        
        CCMenu* pMenu = [CCMenu menuWithItems:btnSound, btnStart, btnContinue, btnRate, nil];
        
        [pMenu setPosition:CGPointZero];
        
        [background addChild:pMenu];
        
        
    }
    return self;
}


-(void) onStart
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.2f scene:[LevelSelectLayer scene]]];
}

-(void) onContinue
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    int level = [[userDefaults valueForKey:@"level"] intValue];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.2f scene:[GameLayer sceneWithLevel:level+1]]];
}

-(void) onRate
{
    
}

-(void) onSound
{
    
}

@end
