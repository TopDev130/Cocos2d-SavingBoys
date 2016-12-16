//
//  Player.m
//  SavingBoys
//
//  Created by lion on 10/4/14.
//
//

#import "Player.h"
#import "GameLayer.h"

#define WORKING_TAG 100
#define DIGDOWN_TAG 200
#define DIGBESIDE_TAG 300
#define STAIR_TAG 400
#define UMBRELLA_TAG 500
#define STOP_TAG 600

#define DIG_LEN 200
#define STAIR_LEN   10
#define STAIR_INTERVAL 30
#define GRAVITY (0.5f)
#define VELOCITY_X 2

extern char*    g_MapValue;
extern int      g_nWidth;
extern int      g_nHeight;
extern float    g_mapScale;
extern NSMutableArray* g_playerArray;

@implementation Player

+(Player*) createWithMap:(CCSprite *)map withGameLayer:(GameLayer *)gameLayer
{
    return [[[self alloc] initWithMap:map withGameLayer:gameLayer] autorelease];
}

-(id) initWithMap:(CCSprite *)map withGameLayer:(GameLayer *)gameLayer
{
    if ((self = [super initWithFile:@"walking1.png"]))
    {
        
        m_bUmbrella = NO;
        m_bPineapple = NO;
        m_nPineapple = 100;
        m_nDig = 0;
        m_velocityX = VELOCITY_X;
        m_velocityY = 0;
        m_nStair = 0;
        m_nStairInterval = 0;
        m_gameLayer = gameLayer;
        m_pMap = map;
        
        CGSize playerSize = self.contentSize;
        
        m_lblPineapple = [CCLabelTTF labelWithString:@"" fontName:@"Arial" fontSize:32];
        [m_lblPineapple setPosition:ccp(self.position.x + playerSize.width/2, self.position.y + playerSize.height * 1.5)];
        [self addChild:m_lblPineapple z:100];
        
    }
    return self;

}

-(int) getValueFromLocation:(CGPoint)location
{
    int index = g_nWidth * (g_nHeight - (int)location.y) + (int) location.x;
    if (index > (g_nHeight * g_nWidth)) {
        return -1;
    }
    return g_MapValue[index];
    
}

-(void) setValueToLocation:(CGPoint)location withValue:(int)value
{
    int index = g_nWidth * (g_nHeight - (int)location.y) + (int) location.x;
    if (index > (g_nWidth * g_nHeight)) {
        return;
    }
    g_MapValue[index] = value;
}

-(BOOL) checkCollisions
{
    
    if (m_playerStatus == StairStatus || m_playerStatus == StopStatus) {
        return YES;
    }
   
    CGRect bouningBox = self.boundingBox;
    CGSize playerSize = bouningBox.size;
    
    CGPoint leftBottom = bouningBox.origin;
    CGPoint centerBottom = ccpAdd(leftBottom, ccp(playerSize.width / 2,0));
    
    CGPoint forwardBottom = leftBottom;
    CGPoint forwardTop = ccpAdd(leftBottom, ccp(0, playerSize.width));
    
    if (m_velocityX > 0)
    {
        forwardBottom = ccpAdd(forwardBottom, ccp(playerSize.width, 0));
        forwardTop = ccpAdd(forwardTop, ccp(playerSize.width, 0));
    }
    
    
    if (forwardTop.x > g_nWidth) {
        m_velocityX = -m_velocityX;
        m_velocityY = 0;
        m_playerStatus = WORKINGSTATUS;
        return YES;
    }else if (forwardTop.x < 0)
    {
        m_velocityX = -m_velocityX;
        m_velocityY = 0;
        m_playerStatus = WORKINGSTATUS;
        return YES;
    }
    
    
    int mapValue = 0;
    
    if (m_playerStatus == DigBesideStatus)
    {
        int i;
        for (i = forwardBottom.y; i < forwardTop.y ; i++)
        {
            mapValue = [self getValueFromLocation:ccp(forwardTop.x, i)];
            if (mapValue != 0)
                break;
        }
        if (i == forwardTop.y) {
            [self digBesideAnimation];
            
            m_playerStatus = FallDownStatus;
        }else
            return YES;
    }
    
    mapValue = [self getValueFromLocation:centerBottom];
    if (mapValue == -1) {
       
        [g_playerArray removeObject:self];
        [m_gameLayer increaseDead];
        [self showParticle];
        [self removeFromParentAndCleanup:YES];
       
        return NO;
    }
    if (mapValue == 0)
    {
        m_playerStatus = FallDownStatus;
        
    }
    else
    {
        if (m_playerStatus != DigDownStatus){
            
            m_playerStatus = WORKINGSTATUS;
            if (m_velocityY < -20) {
                [g_playerArray removeObject:self];
                [m_gameLayer increaseDead];
                [self showParticle];
                [self removeFromParentAndCleanup:YES];
                
                return NO;
            }
            m_velocityY = 0;
        }
    }
    return YES;
    
    
}

-(void) moveAction
{
    if (m_bPineapple) {
        m_nPineapple -= 1;
        int ntime = m_nPineapple / 20 + 1;
        [m_lblPineapple setString:[NSString stringWithFormat:@"%d", ntime]];
        if (ntime < 1) {
            [self pineappleAnimation];
            return;
        }
    }
    if ([self checkCollisions] == NO) {
        return;
    }
    
    switch (m_playerStatus) {
        case FallDownStatus:
            
            [self fallDownAnimation];
            break;
            
        case WORKINGSTATUS:
            
            [self workingAnimation];
            break;
            
        case DigDownStatus:
            
            [self digDownAnimation];
            break;
        case DigBesideStatus:
            
            [self digBesideAnimation];
            break;
            
        case StairStatus:
            [self stairAnimation];
            break;
            
        case StopStatus:
            [self stopAnimtion];
            break;
        default:
            break;
    }
}

#pragma mark -

-(void) fallDownAnimation
{
    
    if (m_prevStatus == DigDownStatus)
    {
        CCSprite* sprDig = [CCSprite spriteWithFile:@"dig.png"];
        float sprScaleX = self.contentSize.width / sprDig.contentSize.width;
        float sprScaleY = self.contentSize.height / sprDig.contentSize.height;
        [sprDig setScaleX:sprScaleX];
        [sprDig setScaleY:sprScaleY];
        
        [sprDig setPosition:self.position];
        [m_pMap addChild:sprDig z:1];
        m_prevStatus = FallDownStatus;
    }
    
    if (m_bUmbrella) {
        if (m_prevStatus == FallDownStatus) {
            
            if (m_velocityY < -10)
            {
                if ([self getActionByTag:UMBRELLA_TAG] == nil)
                {
                    [self stopAllActions];
                    
                    CCAnimation* umbrellaAnimation = [CCAnimation animation];
                    for (int i = 1; i <= 6; i++) {
                        [umbrellaAnimation addFrameWithFilename:[NSString stringWithFormat:@"umbrella%d.png", i]];
                    }
                    
                    [umbrellaAnimation setDelay:0.2];
                    CCAnimate* umbrellaAnimate = [CCAnimate actionWithAnimation:umbrellaAnimation];
                    CCRepeatForever* repeat = [CCRepeatForever actionWithAction:umbrellaAnimate];
                    [repeat setTag:UMBRELLA_TAG];
                    [self runAction:repeat];
                    
                }
                m_velocityY = -2;
                [self setPosition:ccpAdd(self.position, ccp(0, m_velocityY))];
                
            }else
            {
                m_velocityY -= GRAVITY;
                [self setPosition:ccpAdd(self.position, ccp(0, m_velocityY))];
            }
            
        }
        
    }else
    {
        
        m_velocityY = m_velocityY - GRAVITY;
        [self setPosition:ccpAdd(self.position, ccp(0, m_velocityY))];
        
    }
    m_prevStatus = FallDownStatus;
    
}

-(void) workingAnimation
{
    
    if ([self getActionByTag:WORKING_TAG] == nil && m_playerStatus != StairStatus) {
        
        [self stopAllActions];
        
        CCAnimation* workingAnimation = [CCAnimation animation];
        for (int i = 1; i <= 6; i++)
        {
            [workingAnimation addFrameWithFilename:[NSString stringWithFormat:@"walking%d.png", i]];
        }
        [workingAnimation setDelay:0.1];
        CCAnimate* workingAnimate = [CCAnimate actionWithAnimation:workingAnimation];
        CCRepeatForever* repeat = [CCRepeatForever actionWithAction:workingAnimate];
        [repeat setTag:WORKING_TAG];
        [self runAction:repeat];
        
    }
    
    if ([self workingCheckCollision] == NO)
        return;
   
    
    if (m_velocityX < 0 )
        [self setFlipX:YES];
    else
        [self setFlipX:NO];
   
    
    [self setPosition:ccpAdd(self.position, ccp(m_velocityX, 0))];
    
}

-(BOOL) workingCheckCollision
{
    CGRect bouningBox = self.boundingBox;
    CGSize playerSize = bouningBox.size;
    CGPoint leftBottom = bouningBox.origin;
    
    CGPoint forwardBottom = ccpAdd(leftBottom, ccp(playerSize.width/2+1, 0));
    CGPoint forwardTop = ccpAdd(leftBottom, ccp(playerSize.width/2+1, playerSize.height));
    CGPoint forwardCenter = ccpAdd(leftBottom, ccp(playerSize.width/2+1, playerSize.height * 0.5f));
    
    if (m_velocityX < 0) {
        forwardBottom.x -= 2;
        forwardCenter.x -= 2;
        forwardTop.x -= 2;
    }
    
    int pixelValue = 0;
    
    if (m_bDigBeside)
    {
        for (int i = forwardTop.y; i > forwardBottom.y; i--)
        {
            pixelValue = [self getValueFromLocation:ccp(forwardBottom.x, i)];
            if (pixelValue != 0)
            {
                m_playerStatus = DigBesideStatus;
                m_bDigBeside = NO;
                return NO;
                break;
            }
        }
        return YES;
        
    }else
    {
        for (int i = forwardTop.y; i > forwardCenter.y; i--)
        {
            pixelValue = [self getValueFromLocation:ccp(forwardTop.x, i)];
            if (pixelValue != 0)
            {
                if (pixelValue == 2 && m_velocityX < 0)
                    break;
                if (pixelValue == 3 && m_velocityX > 0) 
                    break;
                m_velocityX = -m_velocityX;
                
                if (m_velocityX < 0 )
                    [self setFlipX:YES];
                else
                    [self setFlipX:NO];
                [self setPosition:ccpAdd(self.position, ccp(m_velocityX, 0))];
                return YES;
                
                break;
            }
        }
        
        for (int i = forwardCenter.y; i > forwardBottom.y-1 ; i--)
        {
            pixelValue = [self getValueFromLocation:ccp(forwardTop.x, i)];
            if (pixelValue != 0) {
                if (pixelValue == 2 && m_velocityX < 0)
                    continue;
                if (pixelValue == 3 && m_velocityX > 0)
                    continue;
                [self setPosition:ccpAdd(self.position, ccp(m_velocityX, i - forwardBottom.y))];
                return NO;
                break;
            }
        }
        

        
    }
    
    
    
        
    return YES;

}


-(void) digBesideAnimation
{
    
    if (m_nDig > DIG_LEN) {
        m_playerStatus = WORKINGSTATUS;
        m_nDig = 0;
        return;
    }
    m_nDig += 1;
    if ([self getActionByTag:DIGBESIDE_TAG] == nil) {
        
        [self stopAllActions];
        
        CCAnimation* workingAnimation = [CCAnimation animation];
        for (int i = 1; i < 13; i++) {
            [workingAnimation addFrameWithFilename:[NSString stringWithFormat:@"digBeside%d.png", i]];
        }
        
        [workingAnimation setDelay:0.1];
        CCAnimate* workingAnimate = [CCAnimate actionWithAnimation:workingAnimation];
        CCRepeatForever* repeat = [CCRepeatForever actionWithAction:workingAnimate];
        [repeat setTag:DIGBESIDE_TAG];
        [self runAction:repeat];
        
    }
    if (m_velocityX < 0)
        [self setFlipX:YES];
    else
        [self setFlipX:NO];
    
    CGSize size = self.contentSize;
    CGPoint leftBottom = self.boundingBox.origin;
    CGPoint rightTop = ccpAdd(leftBottom, ccp(size.width, size.height));
    
    for (int i = leftBottom.x; i < rightTop.x; i++)
    {
        for (int j = leftBottom.y; j < rightTop.y + 5; j++) {
            [self setValueToLocation:ccp(i, j) withValue:0];
        }
        
    }
    CCSprite* sprDig = [CCSprite spriteWithFile:@"discard.png"];
    float sprScaleX = self.contentSize.height / sprDig.contentSize.width;
    float sprScaleY = self.contentSize.width / sprDig.contentSize.height;
    [sprDig setScaleX:sprScaleX];
    [sprDig setScaleY:sprScaleY];
    [sprDig setRotation:-90];
    [sprDig setPosition:self.position];
    [m_pMap addChild:sprDig];
    
    if (m_velocityX > 0)
    {
        [sprDig setFlipX:NO];
        [self setPosition:ccpAdd(self.position, ccp(1,0))];
        
    }else
    {
        [self setPosition:ccpAdd(self.position, ccp(-1,0))];
        [sprDig setFlipX:YES];
    }
    m_prevStatus = m_playerStatus;
    
    
}

-(void) digDownAnimation
{
    
    
    if ([self getActionByTag:DIGDOWN_TAG] == nil) {
        
        [self stopAllActions];
        
        CCAnimation* workingAnimation = [CCAnimation animation];
        for (int i = 1; i <= 4; i++) {
            [workingAnimation addFrameWithFilename:[NSString stringWithFormat:@"digDown%d.png", i]];
        }
        [workingAnimation setDelay:0.1];
        CCAnimate* workingAnimate = [CCAnimate actionWithAnimation:workingAnimation];
        CCRepeatForever* repeat = [CCRepeatForever actionWithAction:workingAnimate];
        [repeat setTag:DIGDOWN_TAG];
        [self runAction:repeat];
        
    }
    
    CGSize size = self.contentSize;
    CGPoint leftBottom = ccpAdd(self.position, ccp(-size.width/2, -size.height/2));
    CGPoint rightTop = ccpAdd(self.position, ccp(size.width/2, size.height/2));

    for (int i = leftBottom.x; i < rightTop.x + 1; i++)
    {
        for (int j = leftBottom.y; j < rightTop.y; j++) {
            [self setValueToLocation:ccp(i, j) withValue:0];
        }
        
    }
    CCSprite* sprDig = [CCSprite spriteWithFile:@"dig.png"];
    float sprScaleX = self.contentSize.width / sprDig.contentSize.width;
    float sprScaleY = self.contentSize.height / sprDig.contentSize.height;
    [sprDig setScaleX:sprScaleX];
    [sprDig setScaleY:sprScaleY];
    
    [sprDig setPosition:self.position];
    [m_pMap addChild:sprDig];

    [self setPosition:ccpAdd(self.position, ccp(0,-1))];
    
    m_prevStatus = m_playerStatus;
    
}

-(void) stairAnimation
{
    if (m_nStairInterval < STAIR_INTERVAL)
    {
        m_nStairInterval += 1;
        return;
    }
    m_nStairInterval = 0;
    
    if (m_nStair > STAIR_LEN) {
        m_nStair = 0;
        m_playerStatus = WORKINGSTATUS;
        return;
    }
    m_nStair +=1;
    
    if ([self getActionByTag:STAIR_TAG] == nil) {
        
        [self stopAllActions];
        
        CCAnimation* workingAnimation = [CCAnimation animation];
        for (int i = 1; i <= 5; i++)
        {
            [workingAnimation addFrameWithFilename:[NSString stringWithFormat:@"stair%d.png", i]];
           
        }
        [workingAnimation setDelay:0.2];
        CCAnimate* workingAnimate = [CCAnimate actionWithAnimation:workingAnimation];
        CCRepeatForever* repeat = [CCRepeatForever actionWithAction:workingAnimate];
        [repeat setTag:STAIR_TAG];
        [self runAction:repeat];
        
    }
    
    
    CGSize playerSize = self.boundingBox.size;
    
    CGPoint forwardBottom = ccpAdd(self.position, ccp(m_velocityX / abs(m_velocityX) * 20, -playerSize.height/2-5));
    
    CCSprite* stair = [CCSprite spriteWithFile:@"stair.png"];
    [stair setAnchorPoint:ccp(0.5,0)];
    [stair setPosition:forwardBottom];
    [m_pMap addChild:stair];
    
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 32; j++) {
            if (m_velocityX > 0)
                [self setValueToLocation:ccp(forwardBottom.x+j-16, forwardBottom.y + i) withValue:2];
            else
                [self setValueToLocation:ccp(forwardBottom.x+j-16, forwardBottom.y + i) withValue:3];
        
        }
    }

    [self stairWorking];
}

-(void) stairWorking
{
    CGRect bouningBox = self.boundingBox;
    CGSize playerSize = bouningBox.size;
    CGPoint leftBottom = bouningBox.origin;
    
    CGPoint forwardBottom = ccpAdd(leftBottom, ccp(0, playerSize.height * 0.3f));
    CGPoint forwardTop = ccpAdd(leftBottom, ccp(0, playerSize.height));
    
    if (m_velocityX > 0) {
        forwardBottom = ccpAdd(leftBottom, ccp(playerSize.width, playerSize.height * 0.3f));
        forwardTop = ccpAdd(leftBottom, ccp(playerSize.width, playerSize.height));
        
    }
    
    
    int pixelValue = 0;
    
    for (int i = forwardTop.y; i > forwardBottom.y; i--)
    {
        pixelValue = [self getValueFromLocation:ccp(forwardTop.x, i)];
        if (pixelValue != 0)
        {
            
            m_velocityX = -m_velocityX;
            m_playerStatus = WORKINGSTATUS;
            m_nStair = 0;
            return;
            
        }
    }
    
    [self setPosition:ccpAdd(self.position, ccp(m_velocityX / abs(m_velocityX) * 16, 8))];
    
}

-(void) stopAnimtion
{
    if ([self getActionByTag:STOP_TAG] == nil) {
        
        [self stopAllActions];
        
        CCAnimation* stopAnimation = [CCAnimation animation];
        for (int i = 1; i <= 20; i++)
        {
            [stopAnimation addFrameWithFilename:[NSString stringWithFormat:@"stop%d.png", i]];
         
        }
        [stopAnimation setDelay:0.1];
        CCAnimate* stopAnimate = [CCAnimate actionWithAnimation:stopAnimation];
        CCRepeatForever* repeat = [CCRepeatForever actionWithAction:stopAnimate];
        [repeat setTag:STOP_TAG];
        [self runAction:repeat];
        
    }
    
    CGPoint leftBottom = self.boundingBox.origin;
    CGSize playerSize = self.boundingBox.size;
    
    for (int i = 0; i < playerSize.width; i++) {
        for (int j = 0; j < playerSize.height * 2; j++) {
            [self setValueToLocation:ccp(leftBottom.x + i, leftBottom.y + j) withValue:4];
        }
    }
    
    
}

-(void) pineappleAnimation
{
    [g_playerArray removeObject:self];
    
    CCAnimation* pAnimation = [CCAnimation animation];
    [pAnimation addFrameWithFilename:@"pineapple1.png"];
    [pAnimation addFrameWithFilename:@"pineapple2.png"];
    [pAnimation setDelay:0.1f];
    CCAnimate* pAnimate = [CCAnimate actionWithAnimation:pAnimation];
    CCRepeatForever* repeat = [CCRepeatForever actionWithAction:pAnimate];
    [self runAction:repeat];
    
    CCDelayTime* delay = [CCDelayTime actionWithDuration:0.5f];
    CCCallFunc* callParticle = [CCCallFunc actionWithTarget:self selector:@selector(showParticle)];
    CCCallFunc* calldiscard = [CCCallFunc actionWithTarget:self selector:@selector(discardMeWithBomb)];
    CCSequence* seq = [CCSequence actions:delay, callParticle, calldiscard, nil];
    [self runAction:seq];
    
}

-(void) showParticle
{
    [self setVisible:NO];

    CCParticleSystem* particle = [CCParticleExplosion node];
    [particle setTexture:[[CCTextureCache sharedTextureCache] addImage:@"particle.png"]];
    [particle setPosition:self.position];
    [particle setTotalParticles:30];
    [particle setLife:0.5f];
    [particle setStartSize:1];
    [particle setEndSize:1];
    [m_pMap addChild:particle];
    
}

-(void) discardAnimation
{
    [g_playerArray removeObject:self];
    [self pineappleAnimation];
    
}

-(void) discardMeWithBomb
{
    CGSize playerSize = self.boundingBox.size;
    float radius = playerSize.height;
    CGPoint ptCenter = self.position;
    CGPoint ptLeftTop = ccpAdd(ptCenter, ccp(-radius, radius));
    CGPoint ptRightBottom = ccpAdd(ptCenter, ccp(radius, -radius));
    
    CCSprite* sprDiscard = [CCSprite spriteWithFile:@"discard.png"];
    [sprDiscard setPosition:ptCenter];
    [m_pMap addChild:sprDiscard];
    
    for (int i = ptLeftTop.x; i < ptRightBottom.x; i++) {
        for (int j = ptLeftTop.y; j > ptRightBottom.y; j--)
        {
            float x = ptCenter.x - i;
            float y = ptCenter.y - j;
            if ( (powf(x, 2) + powf(y, 2) ) < powf(radius, 2) ) {
                [self setValueToLocation:ccp(i, j) withValue:0];
            }
            
        }
    }
    
    [self removeFromParentAndCleanup:YES];
    [m_gameLayer increaseDead];
    
}

-(void) enterHome : (CGRect)rect
{
    [g_playerArray removeObject:self];
    
    CGSize homeSize = rect.size;
    CGPoint ptHomeCenter = ccp(rect.origin.x + homeSize.width / 2, rect.origin.y + homeSize.height * 0.5);
    CGPoint ptHomeBottom = ccp(rect.origin.x + homeSize.width / 2, rect.origin.y);
    m_ptHome = ptHomeCenter;
    
    [self runAction:[CCSequence actions:
                    [CCMoveTo actionWithDuration:1.0 position:ptHomeBottom],
                    [CCCallFunc actionWithTarget:self selector:@selector(enterHomeAnimation)],
                    
                    [CCMoveTo actionWithDuration:1.0 position:ptHomeCenter],
                    [CCCallFunc actionWithTarget:self selector:@selector(hideMe)],
                     nil]];
    
    
    
}

-(void) enterHomeAnimation
{
    CCAnimation* pAnimation = [CCAnimation animation];
    for (int i = 1; i <= 6; i++) {
        [pAnimation addFrameWithFilename:[NSString stringWithFormat:@"enterHome%d.png", i]];
    }
    [pAnimation setDelay:0.2f];
    CCAnimate* pAnimate = [CCAnimate actionWithAnimation:pAnimation];
    [self runAction:pAnimate];
    
    [self runAction:[CCSequence actions:
                     [CCMoveTo actionWithDuration:1.0 position:m_ptHome],
                     [CCCallFunc actionWithTarget:self selector:@selector(hideMe)],
                     nil]];
}

-(void) hideMe
{
    [self removeFromParentAndCleanup:YES];
}

#pragma mark -

-(CGRect) getPlayerRect
{
    return self.boundingBox;
}

-(void) setStatus:(PLAYERSTATUS)status
{
    
    switch (status) {
        case PineappleStatus:
            m_bPineapple = YES;
            break;
        case DigBesideStatus:
            if (m_playerStatus != STOP) {
                m_bDigBeside = YES;
            }
            break;
        case UmbrellaStatus:
            m_bUmbrella = YES;
            break;
        default:
            if (m_playerStatus == WORKINGSTATUS) {
                m_playerStatus = status;
            }
            break;
    }
   
    
}



@end
