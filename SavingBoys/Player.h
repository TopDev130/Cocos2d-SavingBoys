//
//  Player.h
//  SavingBoys
//
//  Created by jds on 10/4/14.
//
//

#import "cocos2d.h"


typedef enum {
    FallDownStatus = 0,
    WORKINGSTATUS,
    DigDownStatus,
    DigBesideStatus,
    UmbrellaStatus,
    StopStatus,
    StairStatus,
    PineappleStatus,
}PLAYERSTATUS;

@class GameLayer;

@interface Player : CCSprite
{
    CCSprite*       m_pMap;
    PLAYERSTATUS    m_playerStatus;
    PLAYERSTATUS    m_prevStatus;
    
    CCLabelTTF*     m_lblPineapple;
    
    float           m_velocityX;
    float           m_velocityY;
    
    int             m_nStairInterval;
    int             m_nStair;
    int             m_nPineapple;
    int             m_nDig;
    BOOL            m_bUmbrella;
    BOOL            m_bDigBeside;
    BOOL            m_bPineapple;
    
    GameLayer*      m_gameLayer;
    CGPoint         m_ptHome;
}

+(Player*)  createWithMap:(CCSprite*)map withGameLayer:(GameLayer*)gameLayer;

-(id)       initWithMap:(CCSprite*)map withGameLayer:(GameLayer*)gameLayer;
-(int)      getValueFromLocation:(CGPoint)location;
-(void)     setValueToLocation:(CGPoint)location withValue:(int)value;

-(BOOL)     checkCollisions;

-(void)     moveAction;
-(void)     fallDownAnimation;
-(void)     workingAnimation;
-(BOOL)     workingCheckCollision;
-(void)     digBesideAnimation;
-(void)     digDownAnimation;
-(void)     stairAnimation;
-(void)     stairWorking;
-(void)     stopAnimtion;
-(void)     pineappleAnimation;
-(void)     showParticle;
-(void)     discardAnimation;
-(void)     discardMeWithBomb;
-(void)     enterHome : (CGRect)rect;
-(void)     enterHomeAnimation;
-(void)     hideMe;

-(CGRect)   getPlayerRect;
-(void)     setStatus:(PLAYERSTATUS)status;

@end
