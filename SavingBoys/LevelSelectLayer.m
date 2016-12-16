//
//  LevelSelectLayer.m
//  SavingBoys
//
//  Created by admin on 10/9/14.
//
//

#import "LevelSelectLayer.h"
#import "MenuLayer.h"
#import "GameLayer.h"

@implementation LevelSelectLayer

+(CCScene*) scene
{
    CCScene*            pScene = [CCScene node];
    LevelSelectLayer*   pLayer = [LevelSelectLayer node];
    [pScene addChild:pLayer];
    return pScene;
}

-(id) init
{
    self = [super init];
    if (self)
    {
        CGSize size = [[CCDirector sharedDirector] winSize];
        
        m_background = [CCSprite spriteWithFile:@"level_bg.png"];
        float bgWidth = m_background.contentSize.width;
        float bgHeight = m_background.contentSize.height;
        float scaleX = size.width / bgWidth;
        float scaleY = size.height / bgHeight;
        [m_background setScaleX:scaleX];
        [m_background setScaleY:scaleY];
        [m_background setPosition:ccp(size.width / 2, size.height / 2)];
        [self addChild:m_background];
    
        
        CCMenuItemImage* btnBack = [CCMenuItemImage itemFromNormalImage:@"menu_back.png" selectedImage:@"menu_back_sel.png" target:self selector:@selector(onBack)];
        CCMenu* pBackMenu = [CCMenu menuWithItems:btnBack, nil];
        [pBackMenu setPosition:ccp(bgWidth * 0.12f, bgHeight * 0.18f)];
        [m_background addChild:pBackMenu];
        
        int successlevel = [[[NSUserDefaults standardUserDefaults]valueForKey:@"level"] intValue];
        
        for (int i = 0; i < 20; i++)
        {
            NSString* str = [NSString stringWithFormat:@"level_%d.png", i+1];
            NSString* strSel = [NSString stringWithFormat:@"level_%d_sel.png", i+1];
            m_level[i] = [CCMenuItemImage itemFromNormalImage:str selectedImage:strSel disabledImage:@"level_lock.png" target:self selector:@selector(onLevel:)];
            [m_level[i] setScale:0.9f];
            if (i > successlevel) {
                m_level[i].isEnabled = NO;
            }
        }
        
        CCMenu* pLevelFirst = [CCMenu menuWithItems:m_level[0], m_level[1], m_level[2], m_level[3], m_level[4], nil];
        CCMenu* pLevelSecond = [CCMenu menuWithItems:m_level[5], m_level[6], m_level[7], m_level[8], m_level[9], nil];
        CCMenu* pLevelThird = [CCMenu menuWithItems:m_level[10], m_level[11], m_level[12], m_level[13], m_level[14], nil];
        CCMenu* pLevelFourth = [CCMenu menuWithItems:m_level[15], m_level[16], m_level[17], m_level[18], m_level[19], nil];
        
        [pLevelFirst alignItemsHorizontallyWithPadding:40];
        [pLevelSecond alignItemsHorizontallyWithPadding:40];
        [pLevelThird alignItemsHorizontallyWithPadding:40];
        [pLevelFourth alignItemsHorizontallyWithPadding:40];
        
        [pLevelFirst setPosition:ccp(bgWidth *0.52, bgHeight * 0.75)];
        [pLevelSecond setPosition:ccp(bgWidth * 0.52, bgHeight * 0.58)];
        [pLevelThird setPosition:ccp(bgWidth *0.52, bgHeight * 0.41)];
        [pLevelFourth setPosition:ccp(bgWidth * 0.52, bgHeight * 0.24)];
        
        [m_background addChild:pLevelFirst];
        [m_background addChild:pLevelSecond];
        [m_background addChild:pLevelThird];
        [m_background addChild:pLevelFourth];
        
        CCMenuItemImage* itemSoundOff = [CCMenuItemImage itemFromNormalImage:@"menu_sound.png" selectedImage:@"menu_sound_disable.png"];
        CCMenuItemImage* itemSoundOn = [CCMenuItemImage itemFromNormalImage:@"menu_sound_disable.png" selectedImage:@"menu_sound.png"];
        CCMenuItemToggle* btnSound = [CCMenuItemToggle itemWithTarget:self selector:@selector(onSound) items:itemSoundOff, itemSoundOn, nil];
        [btnSound setPosition:ccp(bgWidth * 0.93f, bgHeight * 0.92f)];
        CCMenu* pSoundMenu = [CCMenu menuWithItems:btnSound, nil];
        [pSoundMenu setPosition:CGPointZero];
        [m_background addChild:pSoundMenu];
        
    }
    
    return self;
}

-(void) onBack
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.2f scene:[MenuLayer scene]]];
}

-(void) onLevel:(id)sender
{
    
    for (int i = 0; i < 20; i++)
    {
        if (m_level[i] == (CCMenuItemImage*)sender)
        {
            [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.2f scene:[GameLayer sceneWithLevel:i+1]]];
            break;
        }
    }
    
}


-(void) onSound
{
    
}

@end
