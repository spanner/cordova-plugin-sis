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

// listenForMessages stashes a callback for use in newBroadcastMessages or newLocationbasedMessages.

- (void)listenForMessages:(CDVInvokedUrlCommand*)command
{
    messagingCallbackId = command.callbackId;
    NSLog(@">>  sis_ios____listenForMessages <- %@", messagingCallbackId);
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:messagingCallbackId];
}

// listenForMapItems stashes a callback for use in newMapContent.

- (void)listenForMapItems:(CDVInvokedUrlCommand*)command
{
    mappingCallbackId = command.callbackId;
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:mappingCallbackId];
}

// getAllMapItems gets... all map items, and returns them directly. Silence if none.

- (void)getAllMapItems:(CDVInvokedUrlCommand*)command
{
    NSDictionary *mapData = [self mapContents];
    if (mapData) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:mapData];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

/*
    The rest of the listeners relay directly the SIS SDK command with the same name.
    They generally return void so we don't call back.
 */


- (void)deleteMessageWithId:(CDVInvokedUrlCommand *)command
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
    Both methods go back to SIS to collect a list of unread messages and then deliver it in sanitized form to the 
    cordova view through the callback channel designated by messagingCallbackId.
*/

- (void)newBroadcastMessages:(NSNotification *)notification
{
    NSLog(@"sis_ios____newBroadcastMessages -> %@", messagingCallbackId);
    if (messagingCallbackId) {
        NSArray *messages = [[SISMessagingManager sharedManager] allUnreadBroadcastMessages];
        NSArray *messageContents = [self messageContents:messages];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:messageContents];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:messagingCallbackId];
    }
}

- (void)newLocationbasedMessages:(NSNotification *)notification
{
    if (messagingCallbackId) {
        NSArray *messages = [[SISMessagingManager sharedManager] allUnreadLocationBasedMessages];
        NSArray *messageContents = [self messageContents:messages];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:messageContents];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:messagingCallbackId];
    }
}

/*
    Map data is dynamic and might change. For us this is a very rare event so rather than trying to manage
    variation we just throw it away and re-fetch the whole set. It comes to us as a dictionary and is passed
    on unsanitised to the cordova view through the callback channel designated by mappingCallbackId.
 */

- (void)newMapContent:(NSNotification *)notification
{
    if (mappingCallbackId) {
        NSDictionary *mapContents = [self mapContents];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:mapContents];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:messagingCallbackId];
    }
}


#pragma mark - SIS data packaging

/*
    THe full map package is quite complicated so we are not yet trying to process it here.
 */

- (NSDictionary *)mapContents
{
    NSDictionary *mapData = [[SISMappingModule sharedManager] getCompleteMapData];
    return mapData;
}

/*
 Messages always come to us as a list and are delivered to cordova as json objects like:
 
 [{
    id: string,
    date: Date,
    title: string,
    text: string,
    channel: string
 }]
 
 */

- (NSArray *)messageContents:(NSArray *)messages
{
    NSMutableArray *messageDictArray = [NSMutableArray array];
    [messages enumerateObjectsUsingBlock:^(SISMessage *message, NSUInteger idx, BOOL *stop) {
        SISMessageChannel *channel = [message channel];
        NSDictionary *messageDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                                     [message messageId], @"id",
                                     [message sendDate], @"date",
                                     [message localizedTitle], @"title",
                                     [message localizedText], @"text",
                                     [channel localizedName], @"channel",
                                     nil];
        [messageDictArray addObject:messageDict];
    }];
    return messageDictArray;
}

@end
