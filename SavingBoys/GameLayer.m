//
//  GameLayer.m
//  SavingBoys
//
//  Created by lion on 10/4/14.
//  Copyright __MyCompanyName__ 2014. All rights reserved.
//


// Import the interfaces
#import "GameLayer.h"

#define UPDATE_INTERVAL 5
#define APPEAR_INTERVAL 0.06f
#define DOOR_TAG 1000
#define GAME_TIME 300.0f

char*   g_MapValue = nil;
int     g_nWidth = 0;
int     g_nHeight = 0;
float   g_mapScale = 1;

NSMutableArray* g_playerArray;

// GameLayer implementation
@implementation GameLayer

+(CCScene *) sceneWithLevel:(int)level
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	GameLayer *layer = [[[GameLayer alloc] initWithLevel:level] autorelease];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}



-(void) getMapWithLevel:(int)level
{
 	
	CGContextRef			context = nil;
	void*					data = nil;;
	CGColorSpaceRef			colorSpace;
	CGImageAlphaInfo		info;

    if(g_MapValue != nil)
        free(g_MapValue);
    
    
    //////////// loading map
    NSString *fullpath = [CCFileUtils fullPathFromRelativePath:[NSString stringWithFormat:@"map%02d.png", level]];
    
    UIImage *jpg = [[UIImage alloc] initWithContentsOfFile:fullpath];
    UIImage *png = [[UIImage alloc] initWithData:
                    UIImagePNGRepresentation(jpg)];
    
    CGImageRef CGImage = png.CGImage;
    
	g_nWidth = CGImageGetWidth(CGImage);
	g_nHeight = CGImageGetHeight(CGImage);

    g_MapValue = (char*)malloc(g_nHeight*g_nWidth);
  
    colorSpace = CGColorSpaceCreateDeviceRGB();
    data = malloc(g_nHeight * g_nWidth * 4);
    info = kCGImageAlphaPremultipliedLast;
    context = CGBitmapContextCreate(data, g_nWidth, g_nHeight, 8, 4 * g_nWidth, colorSpace, info | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
	
	CGContextClearRect(context, CGRectMake(0, 0, g_nWidth, g_nHeight));
	CGContextTranslateCTM(context, 0, 0);
	CGContextDrawImage(context, CGRectMake(0, 0, g_nWidth, g_nHeight), CGImage);

    for(int i=0; i<g_nHeight; i++)
    {
        for(int j=0; j<g_nWidth; j++)
        {
            g_MapValue[i*g_nWidth+j] = ((int*)data)[i*g_nWidth+j] == 0 ? 0 : 1;
        }
    }
    free(data);
    [png release];
    [jpg release];

}


// on "init" you need to initialize your instance
-(id) initWithLevel:(int)level
{
	
	if( (self=[super init])) {
        
        m_nLevel = level;
        m_nOut = m_nHome = m_nDead = 0;
        m_fTime = GAME_TIME;
        m_fTimeEffect = 0;
        m_nMoveInterval = UPDATE_INTERVAL;
        m_nAppearIndex = 0;
        m_nAppearCounter = 50;
        m_commandType = NONE;
        
        CGSize size = [[CCDirector sharedDirector] winSize];
        
        m_pMap = [CCSprite spriteWithFile:[NSString stringWithFormat:@"map%02d.png", m_nLevel]];
        g_mapScale = (size.height * 5 / 6) / m_pMap.contentSize.height;
        [m_pMap setAnchorPoint:CGPointZero];
        [m_pMap setScale:g_mapScale];
        [m_pMap setPosition:ccp(0, size.height / 6)];
        
        [self addChild:m_pMap];
        
        m_controlBar = [CCSprite spriteWithFile:@"game_control_bar.png"];
        float barScaleX = size.width / m_controlBar.contentSize.width;
        float barScaleY = (size.height / 6) / m_controlBar.contentSize.height;
        [m_controlBar setAnchorPoint:CGPointZero];
        [m_controlBar setScaleX:barScaleX];
        [m_controlBar setScaleY:barScaleY];
        [m_controlBar setPosition:CGPointZero];
        
        [self addChild:m_controlBar];
        
        m_statusBar = [CCSprite spriteWithFile:@"game_status_bar.png"];
        [m_statusBar setAnchorPoint:ccp(1,0)];
        [m_statusBar setPosition:ccp(m_controlBar.contentSize.width, m_controlBar.contentSize.height)];
        [m_statusBar setOpacity:200];
        [m_controlBar addChild:m_statusBar];
        
        CCMenuItemImage* pauseItem = [CCMenuItemImage itemFromNormalImage:@"stop.png" selectedImage:@"stop.png" target:self selector:@selector(onPause)];
        CCMenu* pPauseMenu = [CCMenu menuWithItems:pauseItem, nil];
        [pPauseMenu setPosition:ccp(m_controlBar.contentSize.width * 0.9, m_controlBar.contentSize.height/2)];
        [pauseItem setScale:0.8];
        [m_controlBar addChild:pPauseMenu];
        
        [self getMapWithLevel:m_nLevel];
        [self getTMXObjects];
        
        [self showMenus];
        
        g_playerArray = [[NSMutableArray alloc] init];
		
        
        [self showDoorHome];
        
        [self schedule:@selector(addPlayer) interval:APPEAR_INTERVAL];
        [self schedule:@selector(updatePlayers) interval:0.01];
        
        self.isTouchEnabled = YES;
        
	}
	return self;
}

-(void) getTMXObjects
{
    
    CCTMXTiledMap* tileMap = [CCTMXTiledMap tiledMapWithTMXFile:[NSString stringWithFormat:@"%02d.tmx", m_nLevel]];
    CCTMXObjectGroup* objectGroup = [tileMap objectGroupNamed:@"Objects"];
    
    int numObjects = objectGroup.objects.count;
    
    for (int i = 0; i < numObjects; i++)
    {
        NSDictionary* properties = [objectGroup.objects objectAtIndex:i];
        NSString* strType = [properties valueForKey:@"type"];
        
        NSComparisonResult resultCompare = [strType compare:@"start"];
        if (resultCompare == NSOrderedSame) {
            m_nNeedSaveRatio = [[properties valueForKey:@"saveRatio"] intValue];
            m_nPlayerNumber = [[properties valueForKey:@"playerNumber"] intValue];
            m_nPlayerCounter = m_nPlayerNumber;
            
            float x = [[properties valueForKey:@"x"] floatValue];
            float y = [[properties valueForKey:@"y"] floatValue];
            float width = [[properties valueForKey:@"width"] floatValue];
            float height = [[properties valueForKey:@"height"] floatValue];
            
            m_ptStart = ccp((x + width / 2), y + height / 2);
            
            [self getCommandProperties:properties];
            
        }
        
        resultCompare = [strType compare:@"home"];
        if (resultCompare == NSOrderedSame)
        {
            float x = [[properties valueForKey:@"x"] floatValue];
            float y = [[properties valueForKey:@"y"] floatValue];
            float width = [[properties valueForKey:@"width"] floatValue];
            float height = [[properties valueForKey:@"height"] floatValue];
            
            m_ptHome = ccp((x + width/2), (y + height / 2));
            m_rectHome = CGRectMake(x, y, width, height);
        }
    }
    
}

-(void) getCommandProperties:(NSDictionary *)properties
{

    m_nCommandLimit[UMBRELLA] = [[properties valueForKey:@"umbrella"] intValue];
    m_nCommandLimit[PINEAPPLE] = [[properties valueForKey:@"pineapple"] intValue];
    m_nCommandLimit[STOP] = [[properties valueForKey:@"stop"] intValue];
    m_nCommandLimit[STAIR] = [[properties valueForKey:@"stair"] intValue];
    m_nCommandLimit[DIGDOWN] = [[properties valueForKey:@"digDown"] intValue];
    m_nCommandLimit[DIGBESIDE] = [[properties valueForKey:@"digBeside"] intValue];
    m_nCommandLimit[PLUS] = 50;
    m_nCommandLimit[MINUS] = 50;
    m_nCommandLimit[PAUSE] = 0;
    m_nCommandLimit[FASTER] = 0;
    m_nCommandLimit[DISCARD] = 0;
    
}

-(void) showMenus
{
    CGSize size = [[CCDirector sharedDirector] winSize];
    float ntoolbarWidth = 50;
    for (unsigned int i = 0; i < COMMANDCOUNTER; i++)
    {
        CCMenuItemImage* normalItem = [CCMenuItemImage itemFromNormalImage:@"game_control_button.png" selectedImage:@"game_control_button_sel.png"];
        CCMenuItemImage* clickItem = [CCMenuItemImage itemFromNormalImage:@"game_control_button_sel.png" selectedImage:@"game_control_button.png"];
        
        
        float width = normalItem.contentSize.width;
        float height = normalItem.contentSize.height;
        float scale = size.height / 6 / height;
        
        /////////////////////////// show number on button //////////////////////////
        
        m_lblCmdNumber[i] = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", m_nCommandLimit[i]] fontName:@"Arial" fontSize:40];
        [m_lblCmdNumber[i] setPosition:ccp(width / 2, height * 0.78f)];
        [m_lblCmdNumber[i] setColor:ccc3(255, 255, 255)];
        [normalItem addChild:m_lblCmdNumber[i]];
        
        m_lblCmdClickNumber[i] = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", m_nCommandLimit[i]] fontName:@"Arial" fontSize:40];
        [m_lblCmdClickNumber[i] setPosition:ccp(width / 2, height *0.78f)];
        [m_lblCmdClickNumber[i] setColor:ccc3(255, 255, 255)];
        [clickItem addChild:m_lblCmdClickNumber[i]];
        
        /////////////////////////////// show button without number ///////////////////////////////
        if (i == PAUSE || i == FASTER || i == DISCARD) {
            normalItem = [CCMenuItemImage itemFromNormalImage:@"game_extra_button.png" selectedImage:@"game_extra_button_sel.png"];
            clickItem = [CCMenuItemImage itemFromNormalImage:@"game_extra_button_sel.png" selectedImage:@"game_extra_button.png"];
        }
        //////////////////////////////////////////////////////////////////////////////////////////
        
        m_menuItem[i] = [CCMenuItemToggle itemWithTarget:self selector:@selector(onCommand:) items:normalItem, clickItem, nil];
        [m_menuItem[i] setAnchorPoint:CGPointZero];
        
        [m_menuItem[i] setScale:scale];
        
        [m_menuItem[i] setPosition:ccp(ntoolbarWidth , 0)];
        ntoolbarWidth += m_menuItem[i].contentSize.width * scale;
        
        /////////////////////////set icon image on button/////////////////////////////////////////
        
        CCSprite* sprClickCmd = [CCSprite spriteWithTexture:[self getTextureWithType:(COMMANDTYPE)i]];
        [sprClickCmd setPosition:ccp(width/2, height / 3)];
        [sprClickCmd setScale:1.5f];
        [clickItem addChild:sprClickCmd];
        
        [self buttonAnimation:sprClickCmd withType:(COMMANDTYPE)i];
        
        CCSprite* sprCommand = [CCSprite spriteWithTexture:[self getTextureWithType:(COMMANDTYPE)i]];
        [sprCommand setPosition:ccp(width / 2, height / 3)];
        [sprCommand setScale:1.5f];
        [normalItem addChild:sprCommand];

        
        
        
    }

    CCMenu* pMenu = [CCMenu menuWithItems:m_menuItem[UMBRELLA], m_menuItem[PINEAPPLE], m_menuItem[STOP], m_menuItem[STAIR], m_menuItem[DIGBESIDE], m_menuItem[DIGDOWN], m_menuItem[PLUS], m_menuItem[MINUS], m_menuItem[PAUSE], m_menuItem[FASTER], m_menuItem[DISCARD], nil];
    [pMenu setAnchorPoint:ccp(0, 0)];
    [pMenu setPosition:CGPointZero];
    [self addChild:pMenu];
    
    
    NSString* strInformation = [NSString stringWithFormat:@"Save %d of %d boys!",m_nPlayerNumber * m_nNeedSaveRatio / 100, m_nPlayerNumber];
    CCLabelTTF* lblInformation = [CCLabelTTF labelWithString:strInformation fontName:@"Marker Felt" fontSize:64];
    [lblInformation setPosition:ccp(m_statusBar.contentSize.width/2, m_statusBar.contentSize.height/2)];
    [lblInformation setScale:0.5f];
    [m_statusBar addChild:lblInformation z:100 tag:1];
    
    [lblInformation runAction:[CCSequence actions:
                              [CCScaleTo actionWithDuration:0.5f scale:1],
                              [CCDelayTime actionWithDuration:5.0f],
                              [CCFadeOut actionWithDuration:0.5f],
                              [CCCallFunc actionWithTarget:self selector:@selector(showLabels)],
                               nil]];
    
}

-(void) buttonAnimation:(CCSprite*) sprButton withType:(COMMANDTYPE)type
{
    CCAnimation* clickAnimation = [CCAnimation animation];
  
    switch (type) {
            
        case UMBRELLA:
            for (int i = 1; i <= 6; i++)
            {
                [clickAnimation addFrameWithFilename:[NSString stringWithFormat:@"umbrella%d.png",i]];
            }
            [clickAnimation setDelay:0.2f];
            break;
        case PINEAPPLE:
            for (int i = 1; i <= 10; i++)
            {
                [clickAnimation addFrameWithFilename:[NSString stringWithFormat:@"bomb%d.png",i]];
            }
            [clickAnimation setDelay:0.2f];
            break;
        case STOP:
            for (int i = 1; i <= 20; i++)
            {
                [clickAnimation addFrameWithFilename:[NSString stringWithFormat:@"stop%d.png",i]];
            }
            [clickAnimation setDelay:0.1f];
            break;
        case STAIR:
            for (int i = 1; i <= 5; i++)
            {
                [clickAnimation addFrameWithFilename:[NSString stringWithFormat:@"stair%d.png",i]];
            }
            [clickAnimation setDelay:0.2f];
            break;
        case DIGBESIDE:
            for (int i = 1; i <= 12; i++)
            {
                [clickAnimation addFrameWithFilename:[NSString stringWithFormat:@"digBeside%d.png",i]];
            }
            [clickAnimation setDelay:0.2f];
            break;
        case DIGDOWN:
            for (int i = 1; i <= 4; i++)
            {
                [clickAnimation addFrameWithFilename:[NSString stringWithFormat:@"digDown%d.png",i]];
            }
            [clickAnimation setDelay:0.2f];
            break;
        case PLUS:
            for (int i = 1; i <= 2; i++)
            {
                [clickAnimation addFrameWithFilename:[NSString stringWithFormat:@"plus%d.png",i]];
            }
            [clickAnimation setDelay:0.1f];
            break;
        case MINUS:
            for (int i = 1; i <= 2; i++)
            {
                [clickAnimation addFrameWithFilename:[NSString stringWithFormat:@"minus%d.png",i]];
            }
            [clickAnimation setDelay:0.1f];
            break;
        case PAUSE:
            for (int i = 1; i <= 2; i++)
            {
                [clickAnimation addFrameWithFilename:[NSString stringWithFormat:@"footprint%d.png",i]];
            }
            [clickAnimation setDelay:0.1f];
            break;
        case FASTER:
            for (int i = 1; i <= 2; i++)
            {
                [clickAnimation addFrameWithFilename:[NSString stringWithFormat:@"faster%d.png",i]];
            }
            [clickAnimation setDelay:0.1f];
            break;
        case DISCARD:
            for (int i = 1; i <= 2; i++)
            {
                [clickAnimation addFrameWithFilename:[NSString stringWithFormat:@"discard%d.png",i]];
            }
            [clickAnimation setDelay:0.2f];
            break;
            
        default:
            
            break;
    }
    
    CCAnimate* clickAnimate = [CCAnimate actionWithAnimation:clickAnimation];
    
    CCRepeatForever* repeat = [CCRepeatForever actionWithAction:clickAnimate];
    [sprButton runAction:repeat];
    
}

-(CCTexture2D*) getTextureWithType:(COMMANDTYPE)type
{
    CCTexture2D* texture;
    
    switch (type) {
            
        case UMBRELLA:
            texture = [[CCTextureCache sharedTextureCache] addImage:@"umbrella1.png"];
            break;
        case PINEAPPLE:
            texture = [[CCTextureCache sharedTextureCache] addImage:@"bomb1.png"];
            break;
        case STOP:
            texture = [[CCTextureCache sharedTextureCache] addImage:@"stop1.png"];
            break;
        case STAIR:
            texture = [[CCTextureCache sharedTextureCache] addImage:@"stair1.png"];
            break;
        case DIGBESIDE:
            texture = [[CCTextureCache sharedTextureCache] addImage:@"digBeside1.png"];
            break;
        case DIGDOWN:
            texture = [[CCTextureCache sharedTextureCache] addImage:@"digDown1.png"];
            break;
        case PLUS:
            texture = [[CCTextureCache sharedTextureCache] addImage:@"plus1.png"];
            break;
        case MINUS:
            texture = [[CCTextureCache sharedTextureCache] addImage:@"minus1.png"];
            break;
        case PAUSE:
            texture = [[CCTextureCache sharedTextureCache] addImage:@"footprint1.png"];
            break;
        case FASTER:
            texture = [[CCTextureCache sharedTextureCache] addImage:@"faster1.png"];
            break;
        case DISCARD:
            texture = [[CCTextureCache sharedTextureCache] addImage:@"discard1.png"];
            break;
            
        default:
            
            break;
    }
    
    return texture;
    
}


-(void) showLabels
{
    [m_statusBar removeChildByTag:1 cleanup:YES];
    
    m_lblOut = [CCLabelTTF labelWithString:@"Out:0" fontName:@"Marker Felt" fontSize:48];
    [m_lblOut setPosition:ccp(m_statusBar.contentSize.width * 0.2f, m_statusBar.contentSize.height * 0.5)];
    [m_statusBar addChild:m_lblOut];
    
    m_lblTime = [CCLabelTTF labelWithString:@"Time:00:00" fontName:@"Marker Felt" fontSize:48];
    [m_lblTime setPosition:ccp(m_statusBar.contentSize.width * 0.5f, m_statusBar.contentSize.height * 0.5f)];
    [m_statusBar addChild:m_lblTime];
    
    m_lblHome = [CCLabelTTF labelWithString:@"Home:0" fontName:@"Marker Felt" fontSize:48];
    [m_lblHome setPosition:ccp(m_statusBar.contentSize.width * 0.8f, m_statusBar.contentSize.height * 0.5f)];
    [m_statusBar addChild:m_lblHome];
}


-(void) showDoorHome
{
    CCSprite* sprDoor = [CCSprite spriteWithFile:@"door_close.png"];
    [sprDoor setPosition:m_ptStart];
    [m_pMap addChild:sprDoor z:1000 tag:DOOR_TAG];
    
    CCDelayTime* delay = [CCDelayTime actionWithDuration:2.5f];
    CCCallFunc* callShow = [CCCallFunc actionWithTarget:self selector:@selector(showOpenDoor)];
    CCSequence* seq = [CCSequence actions:delay, callShow, nil];
    [sprDoor runAction:seq];
    
    
}

-(void) showOpenDoor
{
    CCSprite* sprDoor = (CCSprite*)[m_pMap getChildByTag:DOOR_TAG];
    [sprDoor setTexture:[[CCTextureCache sharedTextureCache] addImage:@"door_open.png"]];
    
}

#pragma mark -start-

-(void) addPlayer
{
    m_nAppearIndex += 1;
    if (m_nAppearIndex > m_nAppearCounter)
    {
        m_nAppearIndex = 0;
        
        if (m_nPlayerCounter < 1) {
            [self unschedule:@selector(addPlayer)];
        }else
        {
            Player* player = [Player createWithMap:m_pMap withGameLayer:self];
            [player setPosition:m_ptStart];
            [m_pMap addChild:player z:10];
            [g_playerArray addObject:player];
            m_nPlayerCounter -= 1;
        }
    }
    
    
}


-(void) updatePlayers
{
    
    m_fTime -= 0.01;
    if (m_fTime < 0.5f)
    {
        [self showDialog:TIMEOUT];
        return;
    }
    
    
    if ( m_nOut == 0 && ((m_nOut + m_nHome + m_nDead) == m_nPlayerNumber) ) {
        
        if ([self getSavedRatio] >= m_nNeedSaveRatio)
            [self showDialog:SUCCESS];
        else
            [self showDialog:LOSE];
        return;
        
    }
    for(int loop = 0; loop < m_nMoveInterval; loop++)
    {
        for (int i = 0; i < g_playerArray.count; i++)
        {
            
            Player* player = [g_playerArray objectAtIndex:i];
            
            if (CGRectContainsPoint(m_rectHome, player.position)) {
                [player enterHome:m_rectHome];
                m_nHome +=1;
                break;
            }
            [player moveAction];
        }
    }
    
    m_nOut = g_playerArray.count;
    [self showStatus];
}

-(void) showStatus
{
    [m_lblOut setString:[NSString stringWithFormat:@"Out:%d", m_nOut]];
    [m_lblHome setString:[NSString stringWithFormat:@"Home:%d", m_nHome]];
    int minutes = m_fTime / 60;
    int seconds = (int)m_fTime % 60;
    [m_lblTime setString:[NSString stringWithFormat:@"Time:%02d:%02d", minutes, seconds]];
    
    if (minutes < 1) {
        m_fTimeEffect += 0.01;
        if (m_fTimeEffect > 0.3f) {
            if (m_lblTime.color.g == 0)
                [m_lblTime setColor:ccc3(255, 255, 255)];
            else
                [m_lblTime setColor:ccc3(255, 0, 0)];
            
            m_fTimeEffect = 0;
        }
        
    }
    
}


#pragma mark -

-(void) showDialog:(DialogType)type
{
    
    [self stopPlayers];
    
    ResultLayer* resultLayer = Nil;
    switch (type) {
        case SUCCESS:
            {
                NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
                int level = [[userDefaults valueForKey:@"level"] intValue];
                if (level < m_nLevel) {
                    [userDefaults setInteger:m_nLevel forKey:@"level"];
                }
            
                resultLayer = [ResultLayer resultLayerWithLevel:SUCCESS withLevel:m_nLevel withGameLayer:self];
                [self addChild:resultLayer];
            }
            break;
        case LOSE:
            resultLayer = [ResultLayer resultLayerWithLevel:LOSE withLevel:m_nLevel withGameLayer:self];
            [self addChild:resultLayer];
            break;
        case PAUSEGAME:
            resultLayer = [ResultLayer resultLayerWithLevel:PAUSEGAME withLevel:m_nLevel withGameLayer:self];
            [self addChild:resultLayer];
            break;
        case TIMEOUT:
            resultLayer = [ResultLayer resultLayerWithLevel:TIMEOUT withLevel:m_nLevel withGameLayer:self];
            [self addChild:resultLayer];
            break;
            
        default:
            break;
    }
}
-(int) getNeedSaveRatio
{
    return m_nNeedSaveRatio;
}

-(int) getSavedRatio
{
    int savedRatio = (float)m_nHome / (float)m_nPlayerNumber * 100;
    return savedRatio;
}

#pragma mark -

-(void) onPause
{
    
    [self showDialog:PAUSEGAME];
}

-(void) onCommand:(id) sender
{
    CCMenuItemToggle* clickItem = (CCMenuItemToggle*)sender;
    int selectIndex = [clickItem selectedIndex];
    
    for (unsigned int i = 0; i < COMMANDCOUNTER; i++)
    {
        if (clickItem == m_menuItem[i]) {
            if (selectIndex == 1) {
                [self setVisibleMenu:i];
                [self setCommandType:i];
                if (i == PLUS || i == MINUS || i == DISCARD) {
                    [clickItem setSelectedIndex:0];
                }
                
            }
            else if (selectIndex == 0)
            {
                switch (i) {
                    case FASTER:
                        
                        [self setCommandType:NORMALSPEED];
                        break;
                        
                    case PAUSE:
                        [self setCommandType:RESUME];
                        break;
                    default:
                        [self setCommandType:NONE];
                        break;
                }
                
            }
        }
    }
}

-(void) setVisibleMenu:(COMMANDTYPE)type
{
    if (type ==PLUS || type ==MINUS || type == PAUSE || type == FASTER || type == DISCARD)
    {
        return;
    }
    for (unsigned int i = 0; i < COMMANDCOUNTER; i++) {
        if (i != type && i != FASTER) {
            [m_menuItem[i] setSelectedIndex:0];
        }
    }
}

-(void) setCommandType:(COMMANDTYPE)type
{
    NSString* str;
    switch (type) {
        case PLUS:
            if (m_nCommandLimit[PLUS] == 99) {
                break;
            }
            m_nCommandLimit[PLUS] += 1;
            str = [NSString stringWithFormat:@"%d", m_nCommandLimit[PLUS]];
            [m_lblCmdNumber[PLUS] setString:str];
            [m_lblCmdClickNumber[PLUS] setString:str];
            m_nAppearCounter -= 1;
            break;
        case MINUS:
            if (m_nCommandLimit[MINUS] == 1) {
                break;
            }
            m_nCommandLimit[MINUS] -= 1;
            str = [NSString stringWithFormat:@"%d", m_nCommandLimit[MINUS]];
            [m_lblCmdNumber[MINUS] setString:str];
            [m_lblCmdClickNumber[MINUS] setString:str];
            m_nAppearCounter += 1;
            break;
        case PAUSE:
            for (unsigned int i = 0; i < COMMANDCOUNTER; i++)
            {
                if (i != PAUSE)
                    m_menuItem[i].isEnabled = NO;
            }
            [self stopPlayers];
            break;
        case RESUME:
            for (unsigned int i = 0; i < COMMANDCOUNTER; i++)
            {
                m_menuItem[i].isEnabled = YES;
            }
            [self resumePlayers];
            break;
        case FASTER:
            m_nMoveInterval = m_nMoveInterval * 3;
            break;
            
        case NORMALSPEED:
            m_nMoveInterval = UPDATE_INTERVAL;
            break;
            
        case DISCARD:
            
            [self discardPlayers];
            break;
        case NONE:
            m_commandType = NONE;
        default:
            m_commandType = type;
            break;
    }
    
}


-(void) stopPlayers
{
    for (int i = 0; i < g_playerArray.count; i++) {
        Player* player = [g_playerArray objectAtIndex:i];
        [player stopAllActions];
    }
    [self unscheduleAllSelectors];
}

-(void) resumePlayers
{
    
    [self schedule:@selector(addPlayer) interval:APPEAR_INTERVAL];
    [self schedule:@selector(updatePlayers) interval:0.01];
    
}

-(void) discardPlayers
{
    for (int i = 0; i < g_playerArray.count; i++) {
        
        Player* player = (Player*)[g_playerArray objectAtIndex:i];
        [player discardAnimation];
    }
    if (g_playerArray.count > 0) {
        [self discardPlayers];
    }
}

-(void) increaseDead
{
    m_nDead += 1;
}

#pragma mark -touchEvent-

-(void) registerWithTouchDispatcher
{
    [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:kCCMenuTouchPriority swallowsTouches:NO];
}


-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint location = [touch locationInView:touch.view];
    location = [[CCDirector sharedDirector] convertToGL:location];
    m_ptPrev = location;
    
    CGRect touchRect = CGRectMake(location.x - 15, location.y - 15, 30, 30);
    for (Player* player in g_playerArray)
    {
        CGRect rect = player.boundingBox;
        rect.origin = ccpAdd(ccp(rect.origin.x * g_mapScale, rect.origin.y * g_mapScale), m_pMap.position);
        rect.size.width *= g_mapScale;
        rect.size.height *= g_mapScale;
    
        
        if (CGRectIntersectsRect(rect, touchRect)) {
            
            [self commandToPlayer:player];
            break;
        }
    }
    
    return YES;
}

-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint location = [touch locationInView:touch.view];
    location = [[CCDirector sharedDirector] convertToGL:location];
    float gameViewHeight = [[CCDirector sharedDirector] winSize].height/6;
    
    if (location.y > gameViewHeight)
    {
        float distance = m_ptPrev.x - location.x;
        [m_pMap setPosition:ccp(m_pMap.position.x - distance, m_pMap.position.y)];
        
        m_ptPrev = location;
    }
    
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint ptCurrent = m_pMap.position;
    CGSize size = [[CCDirector sharedDirector] winSize];
    float minX = size.width - m_pMap.contentSize.width * g_mapScale;
    if (ptCurrent.x > 0) {
        [m_pMap setPosition:ccp(0, m_pMap.position.y)];
    
    }else if (ptCurrent.x < minX)
    {
        [m_pMap setPosition:ccp(minX, m_pMap.position.y)];
    }
    
    
}


-(void) commandToPlayer:(Player *)player
{
    if (m_commandType > COMMANDCOUNTER) {
        return;
    }
    if (m_nCommandLimit[m_commandType] == 0) {
        return;
    }
    m_nCommandLimit[m_commandType] -= 1;
    NSString* str = [NSString stringWithFormat:@"%d", m_nCommandLimit[m_commandType]];
    [m_lblCmdNumber[m_commandType] setString:str];
    [m_lblCmdClickNumber[m_commandType] setString:str];
    
    switch (m_commandType) {
        case UMBRELLA:
            [player setStatus:UmbrellaStatus];
            break;
            
        case PINEAPPLE:
            
            [player setStatus:PineappleStatus];
            break;
        case STOP:
            
            [player setStatus:StopStatus];
            break;
            
        case STAIR:
            
            [player setStatus:StairStatus];
            break;
            
        case DIGBESIDE:
            [player setStatus:DigBesideStatus];
            break;
        case DIGDOWN:
            [player setStatus:DigDownStatus];
            break;
            
        default:
            break;
    }
    
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	[super dealloc];
}
@end
