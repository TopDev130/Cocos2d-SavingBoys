//
//  ResultLayer
//  SavingBoys
//
//  Created by jds on 10/9/14.
//
//


#import "cocos2d.h"

typedef enum{
    PAUSEGAME = 0,
    SUCCESS,
    LOSE,
    TIMEOUT,
}DialogType;

@class GameLayer;

@interface ResultLayer : CCLayerColor
{
    int             m_nLevel;
    DialogType      m_nType;
    
    CGSize          m_winSize;
    
    CCSprite*       m_dialogBackground;
    CCSprite*       m_sprTitle;
    
    GameLayer*      m_gameLayer;
}

+(ResultLayer*) resultLayerWithLevel:(DialogType)type withLevel:(int)level withGameLayer:(GameLayer*)gameLayer;

-(id)   initWithLevel:(DialogType)type withLevel:(int)level withGameLayer:(GameLayer*)gameLayer;


-(void) registerWithTouchDispatcher;
-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event;

-(void) showDialog;
-(void) showMenus;

-(void) initPauseDialog;
-(void) initSuccessDialog;
-(void) initLoseDialog;
-(void) initTimeoutDialog;
-(void) showInformation;

-(void) showLabelWithScaleAction:(CCLabelTTF*)label;


-(void) onResume;
-(void) onReplay;
-(void) onMenu;
-(void) onNext;

@end
