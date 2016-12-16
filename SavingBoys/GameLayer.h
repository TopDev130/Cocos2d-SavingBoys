//
//  GameLayer
//  SavingBoys
//
//  Created by jds on 10/4/14.
//
//

#import "cocos2d.h"
#import "Player.h"
#import "ResultLayer.h"

typedef enum {
    UMBRELLA = 0,
    PINEAPPLE,
    STOP,
    STAIR,
    DIGBESIDE,
    DIGDOWN,
    PLUS,
    MINUS,
    PAUSE,
    FASTER,
    DISCARD,
    COMMANDCOUNTER,
    NORMALSPEED,
    RESUME,
    NONE,
}COMMANDTYPE;

@interface GameLayer : CCLayer
{
    int         m_nLevel;
    int         m_nMoveInterval;
    int         m_nOut;
    int         m_nHome;
    int         m_nDead;
    
    float       m_fTime;
    float       m_fTimeEffect;
    
    CCLabelTTF* m_lblOut;
    CCLabelTTF* m_lblHome;
    CCLabelTTF* m_lblTime;
    
    CCSprite*   m_pMap;
    
    CGPoint     m_ptPrev;
    
    CGPoint     m_ptStart;
    CGPoint     m_ptHome;
    CGRect      m_rectHome;
    
    int         m_nNeedSaveRatio;
    int         m_nPlayerNumber;
    int         m_nPlayerCounter;
    
    int         m_nCommandLimit[COMMANDCOUNTER];
    
    COMMANDTYPE         m_commandType;
    
    CCLabelTTF*         m_lblCmdNumber[COMMANDCOUNTER];
    CCLabelTTF*         m_lblCmdClickNumber[COMMANDCOUNTER];
    CCMenuItemToggle*   m_menuItem[COMMANDCOUNTER];
    
    CCSprite*           m_controlBar;
    CCSprite*           m_statusBar;
    
    int         m_nAppearIndex;
    int         m_nAppearCounter;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) sceneWithLevel:(int)level;

-(void) getMapWithLevel:(int)level;
-(id)   initWithLevel:(int)level;

-(void) getTMXObjects;
-(void) getCommandProperties : (NSDictionary*)properties;
-(void) showMenus;

-(void) buttonAnimation:(CCSprite*) sprButton withType:(COMMANDTYPE) type;
-(CCTexture2D*) getTextureWithType:(COMMANDTYPE)type;
-(void) showLabels;
-(void) showDoorHome;
-(void) showOpenDoor;

-(void) addPlayer;

-(void) updatePlayers;
-(void) showStatus;

-(void) showDialog:(DialogType)type;
-(int)  getNeedSaveRatio;
-(int)  getSavedRatio;

-(void) onPause;
-(void) onCommand:(id) sender;
-(void) setVisibleMenu:(COMMANDTYPE)type;
-(void) setCommandType:(COMMANDTYPE)type;

-(void) stopPlayers;
-(void) resumePlayers;
-(void) discardPlayers;

-(void) increaseDead;

-(void) commandToPlayer:(Player*)player;

@end
