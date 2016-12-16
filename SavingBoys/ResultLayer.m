//
//  ResultLayer.m
//  SavingBoys
//
//  Created by lion on 9/24/14.
//
//

#import "ResultLayer.h"
#import "LevelSelectLayer.h"
#import "GameLayer.h"

#define DIALOG_ZORDER 1
#define TITLE_ZORDER 2
#define MENU_ZORDER 2


@implementation ResultLayer

+(ResultLayer*) resultLayerWithLevel:(DialogType)type withLevel:(int)level withGameLayer:(GameLayer*)gameLayer
{
    return [[[ResultLayer alloc] initWithLevel:type withLevel:level withGameLayer:gameLayer] autorelease];
}

-(id) initWithLevel:(DialogType)type withLevel:(int)level withGameLayer:(GameLayer*)gameLayer
{
    if ( (self = [super initWithColor:ccc4(0, 0, 0, 180)]) ) {
        
        m_nLevel = level;
        m_nType = type;
        m_gameLayer = gameLayer;
        
        m_winSize = [[CCDirector sharedDirector] winSize];
        
        
        self.isTouchEnabled = YES;
        
        [self showDialog];
        
        [self setVisible:NO];
        CCDelayTime* delay = [CCDelayTime actionWithDuration:1];
        CCCallFunc* call = [CCCallFunc actionWithTarget:self selector:@selector(showMe)];
        CCSequence* seq = [CCSequence actions:delay, call, nil];
        [self runAction:seq];
        
    }
    return self;
}

-(void) showMe
{
    [self setVisible:YES];
}

-(void) registerWithTouchDispatcher
{
    [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:kCCMenuTouchPriority swallowsTouches:YES];
    
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    return YES;
}

#pragma mark -

-(void) showDialog
{
    if (m_nType != PAUSEGAME) {
        m_dialogBackground = [CCSprite spriteWithFile:@"game_dialog.png"];
        
        float bgScaleX = m_winSize.width / m_dialogBackground.contentSize.width;
        float bgScaleY = m_winSize.height / m_dialogBackground.contentSize.height;
        [m_dialogBackground setScaleX:bgScaleX];
        [m_dialogBackground setScaleY:bgScaleY];
        [m_dialogBackground setPosition:ccp(m_winSize.width/2, m_winSize.height / 2)];
        
        [self addChild:m_dialogBackground];
        
    }
    
    [self showMenus];
    
}

-(void) showMenus
{
    switch (m_nType) {
            
        case PAUSEGAME:
            
            [self initPauseDialog];
            break;
            
        case SUCCESS:
            
            [self initSuccessDialog];
            break;
            
        case LOSE:
            
            [self initLoseDialog];
            break;
            
        case TIMEOUT:
            
            [self initTimeoutDialog];
            break;
            
        default:
            break;
    }
    
}

-(void) initPauseDialog
{
  
    m_dialogBackground = [CCSprite spriteWithFile:@"pause_bg.png"];
    float bgWidth = m_dialogBackground.contentSize.width;
    float bgHeight = m_dialogBackground.contentSize.height;
    float bgScaleX = m_winSize.width / bgWidth;
    float bgScaleY = m_winSize.height / bgHeight;
    [m_dialogBackground setScaleX:bgScaleX];
    [m_dialogBackground setScaleY:bgScaleY];
    [m_dialogBackground setPosition:ccp(m_winSize.width/2, m_winSize.height / 2)];
    
    [self addChild:m_dialogBackground];
    
    CCMenuItemImage* resumeMenu = [CCMenuItemImage itemFromNormalImage:@"pause_resume.png" selectedImage:@"pause_resume_sel.png" target:self selector:@selector(onResume)];
    CCMenuItemImage* replayMenu = [CCMenuItemImage itemFromNormalImage:@"pause_replay.png" selectedImage:@"pause_replay_sel.png" target:self selector:@selector(onReplay)];
    CCMenuItemImage* menuMenu = [CCMenuItemImage itemFromNormalImage:@"pause_menu.png" selectedImage:@"pause_menu_sel.png" target:self selector:@selector(onMenu)];
    
    [resumeMenu setPosition:ccp(bgWidth / 2, bgHeight *0.65f)];
    [replayMenu setPosition:ccp(bgWidth / 2, bgHeight * 0.5f)];
    [menuMenu setPosition:ccp(bgWidth / 2, bgHeight * 0.35f)];
    
    CCMenu* pMenu = [CCMenu menuWithItems:resumeMenu, replayMenu, menuMenu, nil];
    [pMenu setPosition:CGPointZero];
    [m_dialogBackground addChild:pMenu];
    
}

-(void) initSuccessDialog
{
    
    [self showInformation];
    int saveRatio = [m_gameLayer getSavedRatio];
    if (saveRatio == 100)
        m_sprTitle = [CCSprite spriteWithFile:@"superb.png"];
    else
        m_sprTitle = [CCSprite spriteWithFile:@"game_success_title.png"];
    [m_sprTitle setPosition:ccp(m_dialogBackground.contentSize.width/2, m_dialogBackground.contentSize.height * 0.7f)];
    [m_dialogBackground addChild:m_sprTitle];
    
    CCMenuItemImage* replayMenu = [CCMenuItemImage itemFromNormalImage:@"menu_replay.png" selectedImage:@"menu_replay_sel.png" target:self selector:@selector(onReplay)];
    CCMenuItemImage* nextMenu = [CCMenuItemImage itemFromNormalImage:@"menu_forward.png" selectedImage:@"menu_forward_sel.png" target:self selector:@selector(onNext)];
    CCMenuItemImage* menuMenu = [CCMenuItemImage itemFromNormalImage:@"menu_menu.png" selectedImage:@"menu_menu_sel.png" target:self selector:@selector(onMenu)];

    CCMenu* pMenu = [CCMenu menuWithItems:replayMenu, nextMenu, menuMenu, nil];
    [pMenu alignItemsHorizontallyWithPadding:15];
    [pMenu setPosition:ccp(m_dialogBackground.contentSize.width/2, m_dialogBackground.contentSize.height * 0.3)];
    [m_dialogBackground addChild:pMenu];
    
    
    
}

-(void) initLoseDialog
{
    [self showInformation];
    int savedRatio = [m_gameLayer getSavedRatio];
    if (savedRatio == 0)
        m_sprTitle = [CCSprite spriteWithFile:@"RockBottom.png"];
    else
        m_sprTitle = [CCSprite spriteWithFile:@"mayhem.png"];
    [m_sprTitle setPosition:ccp(m_dialogBackground.contentSize.width/2, m_dialogBackground.contentSize.height * 0.7f)];
    [m_dialogBackground addChild:m_sprTitle];
    
    CCMenuItemImage* replayMenu = [CCMenuItemImage itemFromNormalImage:@"menu_replay.png" selectedImage:@"menu_replay_sel.png" target:self selector:@selector(onReplay)];
    CCMenuItemImage* menuMenu = [CCMenuItemImage itemFromNormalImage:@"menu_menu.png" selectedImage:@"menu_menu_sel.png" target:self selector:@selector(onMenu)];
    
    CCMenu* pMenu = [CCMenu menuWithItems:replayMenu, menuMenu, nil];
    [pMenu alignItemsHorizontallyWithPadding:50];
    [pMenu setPosition:ccp(m_dialogBackground.contentSize.width/2, m_dialogBackground.contentSize.height * 0.3)];
    [m_dialogBackground addChild:pMenu];
    
}

-(void) initTimeoutDialog
{
    [self showInformation];
    
    m_sprTitle = [CCSprite spriteWithFile:@"timeout.png"];
    [m_sprTitle setPosition:ccp(m_dialogBackground.contentSize.width/2, m_dialogBackground.contentSize.height * 0.7f)];
    [m_dialogBackground addChild:m_sprTitle];
    
    CCMenuItemImage* replayMenu = [CCMenuItemImage itemFromNormalImage:@"menu_replay.png" selectedImage:@"menu_replay_sel.png" target:self selector:@selector(onReplay)];
    CCMenuItemImage* menuMenu = [CCMenuItemImage itemFromNormalImage:@"menu_menu.png" selectedImage:@"menu_menu_sel.png" target:self selector:@selector(onMenu)];
    
    CCMenu* pMenu = [CCMenu menuWithItems:replayMenu, menuMenu, nil];
    [pMenu alignItemsHorizontallyWithPadding:50];
    [pMenu setPosition:ccp(m_dialogBackground.contentSize.width/2, m_dialogBackground.contentSize.height * 0.3)];
    [m_dialogBackground addChild:pMenu];
}

-(void) showInformation
{
    
    int needSaveRatio = [m_gameLayer getNeedSaveRatio];
    int savedRatio = [m_gameLayer getSavedRatio];
    
    NSString* strNeedSaveRatio = [NSString stringWithFormat:@"You needed %d%%!", needSaveRatio];
    CCLabelTTF* lblNeedRatio = [CCLabelTTF labelWithString:strNeedSaveRatio fontName:@"Marker Felt" fontSize:64];
    [lblNeedRatio setPosition:ccp(m_dialogBackground.contentSize.width / 2, m_dialogBackground.contentSize.height * 0.54)];
    [m_dialogBackground addChild:lblNeedRatio z:TITLE_ZORDER];
    
    NSString* strSavedRatio = [NSString stringWithFormat:@"You rescued %d%%!", savedRatio];
    CCLabelTTF* lblSavedRatio = [CCLabelTTF labelWithString:strSavedRatio fontName:@"Marker Felt" fontSize:64];
    [lblSavedRatio setPosition:ccp(m_dialogBackground.contentSize.width / 2, m_dialogBackground.contentSize.height * 0.46)];
    [m_dialogBackground addChild:lblSavedRatio z:TITLE_ZORDER];
    
}

-(void) showLabelWithScaleAction:(CCLabelTTF *)label
{
    [label setScale:0];
    
    CCScaleTo* scaleto = [CCScaleTo actionWithDuration:1.5f scale:1];
    CCEaseBounceOut* bounce = [CCEaseBounceOut actionWithAction:scaleto];
    [label runAction:bounce];
}


#pragma mark -menuHandler-

-(void) onResume
{
    [m_gameLayer resumePlayers];
    [self removeFromParentAndCleanup:YES];
}

-(void) onReplay
{
    [[CCDirector sharedDirector] replaceScene:[GameLayer sceneWithLevel:m_nLevel]];
    
}

-(void) onMenu
{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.2f scene:[LevelSelectLayer scene]]] ;
}

-(void) onNext
{
    
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.2f scene:[GameLayer sceneWithLevel:m_nLevel+1]]];
}

@end
