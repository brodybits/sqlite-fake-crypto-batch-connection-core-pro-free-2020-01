#import <Cordova/CDVPlugin.h>

#import "SQLiteBatchCore.h"

#include "sqlite-connection-core.h"

@interface SQLiteDemoPlugin : CDVPlugin

- (void) openDatabaseConnection: (CDVInvokedUrlCommand *) commandInfo;

- (void) executeBatch: (CDVInvokedUrlCommand *) commandInfo;

@end

@implementation SQLiteDemoPlugin

- (void) openDatabaseConnection: (CDVInvokedUrlCommand *) commandInfo
{
  NSArray * _args = commandInfo.arguments;

  NSDictionary * options = (NSDictionary *)[_args objectAtIndex: 0];

  NSString * fullName = (NSString *)[options valueForKey: @"fullName"];

  const int flags = [(NSNumber *)[options valueForKey: @"flags"] intValue];

  // password key - null or empty if not present
  const char * key = [(NSString *)[options valueForKey: @"key"] cString];

  const int dbid = [SQLiteBatchCore openBatchConnection: fullName flags: flags];

  if (dbid < 0) {
    CDVPluginResult * openErrorResult =
      [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR
                        messageAsString: @"open error"];
    [self.commandDelegate sendPluginResult: openErrorResult
                                callbackId: commandInfo.callbackId];
  } else if (key != NULL && key[0] != '\0' && scc_key(dbid, key) != 0) {
    CDVPluginResult * openErrorResult =
      [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR
                        messageAsString: @"key error"];
    [self.commandDelegate sendPluginResult: openErrorResult
                                callbackId: commandInfo.callbackId];
  } else {
    CDVPluginResult * openResult =
      [CDVPluginResult resultWithStatus: CDVCommandStatus_OK
                           messageAsInt: dbid];
    [self.commandDelegate sendPluginResult: openResult
                                callbackId: commandInfo.callbackId];
  }
}

- (void) executeBatch: (CDVInvokedUrlCommand *) commandInfo
{
  // execute in background
  dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [self executeBatchNow: commandInfo];
    });
}

- (void) executeBatchNow: (CDVInvokedUrlCommand *) commandInfo
{
  NSArray * _args = commandInfo.arguments;

  const int connection_id = [(NSNumber *)[_args objectAtIndex: 0] intValue];

  NSArray * data = [_args objectAtIndex: 1];

  NSArray * results = [SQLiteBatchCore executeBatch: connection_id data: data];

  CDVPluginResult * batchResult =
    [CDVPluginResult resultWithStatus: CDVCommandStatus_OK
                       messageAsArray: results];

  [self.commandDelegate sendPluginResult: batchResult
                              callbackId: commandInfo.callbackId];
}

@end
