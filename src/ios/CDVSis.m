//
//  CDVSis.m
//  LordMayorShow
//
//  Created by William Ross on 14/10/2015.
//
//

#import "CDVSis.h"

@implementation CDVSis

NSString *messagingCallbackId;
NSString *mappingCallbackId;


- (void)pluginInitialize
{
    NSLog(@">>  sis_ios____pluginInitialize");

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newLocationbasedMessages:)
                                                 name:kSISNewLocationBasedMessagesNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newBroadcastMessages:)
                                                 name:kSISNewBroadcastMessagesNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newMapContent:)
                                                 name:kMapSISNewMapData
                                               object:nil];
}

#pragma mark - Cordova plugin helpers

/*
    listenForMessages stashes a callback for use in newBroadcastMessages or newLocationbasedMessages
    and calls back immediately the current set of unread messages.
 */

- (void)listenForMessages:(CDVInvokedUrlCommand*)command
{
    messagingCallbackId = command.callbackId;
    [self sendUnreadMessages];
}

/*
    listenForMapItems stashes a callback for use in newMapContent 
    and calls back immediately with the current map content.
*/

- (void)listenForMapItems:(CDVInvokedUrlCommand*)command
{
    mappingCallbackId = command.callbackId;
    [self sendMapContent];
}

/*
    getCompleteMapData gets all map items, and calls back directly. Silence if none.
 */

- (void)getCompleteMapData:(CDVInvokedUrlCommand*)command
{
    [self sendMapContent];
}

/*
    The rest of the listeners relay directly the SIS SDK command with the same name.
    They generally return void so we don't tend to call back.
 */


- (void)deleteMessage:(CDVInvokedUrlCommand *)command
{
    NSString *messageID = [command.arguments objectAtIndex:0];
    [[SISMessagingManager sharedManager] deleteMessageWithId:messageID];
}

- (void)markMessageAsRead:(CDVInvokedUrlCommand *)command
{
    NSString *messageID = [command.arguments objectAtIndex:0];
    [[SISMessagingManager sharedManager] markMessageAsRead:messageID];
}


#pragma mark - SIS listeners

/*
    Messages are incremental and never change after delivery.
    The arrival of one or more new messages will cause a notification that triggers either newBroadcastMessages
    or newLocationbasedMessages, depending on the type.
    Both methods go back to SIS to collect a list of all unread messages and then deliver it in sanitized form
    to the cordova view through the callback channel designated by messagingCallbackId.
*/

- (void)newBroadcastMessages:(NSNotification *)notification
{
// local notification
    
    [self sendUnreadMessages];
}

- (void)newLocationbasedMessages:(NSNotification *)notification
{
    [self sendUnreadMessages];
}

/*
    Map data is dynamic and might change. For us this is a very rare event so rather than trying to manage
    variation we just throw it away and re-fetch the whole set. It comes to us as a dictionary and is passed
    on unsanitised to the cordova view through the callback channel designated by mappingCallbackId.
 */

- (void)newMapContent:(NSNotification *)notification
{
    [self sendMapContent];
}


#pragma mark - SIS data packaging

/*
    Map data is organised into an object with keys for each SIS object type.
    No doubt there will be more for us to pass through but here's what you get at the moment:
    {
      categories: [{
        id: integer
        name: string
      }],
      pois: [{
        icon: url string
        title: string
        description: string
      }],
      routes: [{
        color: rgba(r,g,b,a) string
        paths: array of encoded path strings
        title: string
        description: string
      }],
      zones: [{
        color: rgba(r,g,b,a) string
        paths: array of encoded path strings
        title: string
        description: string
      }]
    }
 */

- (void)sendMapContent
{
    if (mappingCallbackId) {
        [self.commandDelegate runInBackground:^{
            NSDictionary *mapContents = [self mapContents];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:mapContents];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:messagingCallbackId];
        }];
    }
}

- (NSDictionary *)mapContents
{
    NSDictionary *mapData = [[SISMappingModule sharedManager] getCompleteMapData];
    NSDictionary *mapDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                             [self categoryContents:mapData[@"kMapSISCategoriesKey"]], @"categories",
                             [self poiContents:mapData[@"kMapSISPOIsKey"]], @"pois",
                             [self routeContents:mapData[@"kMapSISRoutesKey"]], @"routes",
                             [self zoneContents:mapData[@"kMapSISZonesKey"]], @"zones",
                             nil];
    return mapDict;
}

- (NSArray *)poiContents:(NSArray *)pois
{
    NSMutableArray *poiDictArray = [NSMutableArray array];
    [pois enumerateObjectsUsingBlock:^(SISPOIItem *poi, NSUInteger idx, BOOL *stop) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"YYYY-MM-dd'T'HH:mm:ssZZZ"];
        NSDictionary *poiDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 [poi icon], @"icon",
                                 [poi localizedTitle], @"title",
                                 [poi localizedDescription], @"description",
                                 nil];
        [poiDictArray addObject:poiDict];
    }];
    return poiDictArray;
}

- (NSArray *)routeContents:(NSArray *)routes
{
    NSMutableArray *routeDictArray = [NSMutableArray array];
    [routes enumerateObjectsUsingBlock:^(SISRoute *route, NSUInteger idx, BOOL *stop) {
        SISColor *color = [route color];
        NSString *rgba = [NSString stringWithFormat:@"rgba(%@,%@,%@,%@)", [color r], [color g], [color b], [color alpha]];
        NSDictionary *routeDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 rgba, @"color",
                                 [route routePaths], @"paths",
                                 [route localizedTitle], @"title",
                                 [route localizedDescription], @"description",
                                 nil];
        [routeDictArray addObject:routeDict];
    }];
    return routeDictArray;
}

- (NSArray *)zoneContents:(NSArray *)zones
{
    NSMutableArray *zoneDictArray = [NSMutableArray array];
    [zones enumerateObjectsUsingBlock:^(SISMapZone *zone, NSUInteger idx, BOOL *stop) {
        SISColor *color = [zone color];
        NSString *rgba = [NSString stringWithFormat:@"rgba(%@,%@,%@,%@)", [color r], [color g], [color b], [color alpha]];
        NSDictionary *pathsDict = [[zone zonee] dictionary];
        NSDictionary *zoneDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   rgba, @"color",
                                   pathsDict, @"paths",
                                   [zone localizedTitle], @"title",
                                   [zone localizedDescription], @"description",
                                   nil];
        [zoneDictArray addObject:zoneDict];
    }];
    return zoneDictArray;
}

- (NSArray *)categoryContents:(NSArray *)categories
{
    NSMutableArray *categoryDictArray = [NSMutableArray array];
    [categories enumerateObjectsUsingBlock:^(SISPOICategory *category, NSUInteger idx, BOOL *stop) {
        NSDictionary *categoryDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  [category categoryId], @"id",
                                  [category localizedName], @"name",
                                  nil];
        [categoryDictArray addObject:categoryDict];
    }];
    return categoryDictArray;
}

/*
 Messages always come to us as a list and are delivered to cordova as json objects like:
 
 [{
    id: integer as string,
    date: iso date string,
    title: string,
    text: string,
    channel: name as string
 }]
 
 */

- (void)sendUnreadMessages
{
    if (messagingCallbackId) {
        [self.commandDelegate runInBackground:^{
            NSArray *broadcastmessages = [[SISMessagingManager sharedManager] allUnreadBroadcastMessages];
            NSArray *locbasedmessages = [[SISMessagingManager sharedManager] allUnreadLocationBasedMessages];
            NSArray *messages = [broadcastmessages arrayByAddingObjectsFromArray:locbasedmessages];
            NSArray *messageContents = [self messageContents:messages];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:messageContents];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:messagingCallbackId];
        }];
    }
}

- (NSArray *)messageContents:(NSArray *)messages
{
    NSMutableArray *messageDictArray = [NSMutableArray array];
    [messages enumerateObjectsUsingBlock:^(SISMessage *message, NSUInteger idx, BOOL *stop) {
        SISMessageChannel *channel = [message channel];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"YYYY-MM-dd'T'HH:mm:ssZZZ"];
        NSDictionary *messageDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                     [message messageId], @"id",
                                     [dateFormatter stringFromDate:[message sendDate]], @"date",
                                     [message localizedTitle], @"title",
                                     [message localizedText], @"text",
                                     [channel localizedName], @"channel",
                                     nil];
        [messageDictArray addObject:messageDict];
    }];
    return messageDictArray;
}

@end
