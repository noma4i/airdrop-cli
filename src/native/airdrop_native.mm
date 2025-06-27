#include <node_api.h>
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

// MARK: - Constants
static const NSTimeInterval kRunLoopInterval = 0.1;
static const NSRect kDefaultSourceFrame = NSMakeRect(0, 0, 400, 100);
static const NSRect kDefaultWindowFrame = NSMakeRect(0, 0, 1, 1);

// MARK: - AirDropSyncDelegate Interface
@interface AirDropSyncDelegate : NSObject <NSSharingServiceDelegate>
@property (nonatomic, assign) BOOL completed;
@property (nonatomic, strong, nullable) NSError *error;
@end

// MARK: - AirDropSyncDelegate Implementation
@implementation AirDropSyncDelegate

- (void)sharingService:(NSSharingService *)sharingService
        willShareItems:(NSArray *)items {
}

- (void)sharingService:(NSSharingService *)sharingService
         didShareItems:(NSArray *)items {
    [self completeWithError:nil];
}

- (void)sharingService:(NSSharingService *)sharingService
    didFailToShareItems:(NSArray *)items
                  error:(NSError *)error {
    [self completeWithError:error];
}

- (NSRect)sharingService:(NSSharingService *)sharingService
sourceFrameOnScreenForShareItem:(id)item {
    return kDefaultSourceFrame;
}

- (NSWindow *)sharingService:(NSSharingService *)sharingService
            sourceWindowForShareItems:(NSArray *)items
                  sharingContentScope:(NSSharingContentScope *)sharingContentScope {
    return [self createSourceWindow];
}

// MARK: - Private Methods
- (void)completeWithError:(nullable NSError *)error {
    self.error = error;
    self.completed = YES;
    CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
}

- (NSWindow *)createSourceWindow {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:kDefaultWindowFrame
                                                   styleMask:NSWindowStyleMaskClosable
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    [window center];
    window.level = NSPopUpMenuWindowLevel;
    [window makeKeyAndOrderFront:nil];
    return window;
}

@end

// MARK: - Helper Functions
static NSURL* ConvertJSStringToNSURL(napi_env env, napi_value js_string) {
    size_t str_size;
    napi_get_value_string_utf8(env, js_string, NULL, 0, &str_size);

    char* str_value = (char*)malloc(str_size + 1);
    napi_get_value_string_utf8(env, js_string, str_value, str_size + 1, NULL);

    NSString *filePath = [NSString stringWithUTF8String:str_value];
    free(str_value);

    NSURL *url = nil;
    if ([filePath hasPrefix:@"http://"] || [filePath hasPrefix:@"https://"]) {
        url = [NSURL URLWithString:filePath];
    } else {
        url = [NSURL fileURLWithPath:filePath];
    }

    return url;
}

static void InitializeNSApplication() {
    NSApplication *app = [NSApplication sharedApplication];
    [app setActivationPolicy:NSApplicationActivationPolicyAccessory];
}

static void WaitForCompletion(AirDropSyncDelegate *delegate) {
    while (!delegate.completed) {
        NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:kRunLoopInterval];
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeout];
    }
}

// MARK: - Main Function
static napi_value ShareFile(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1];
    napi_get_cb_info(env, info, &argc, args, NULL, NULL);

    // Validate arguments
    if (argc < 1) {
        napi_throw_type_error(env, NULL, "Expected 1 argument: file path or URL");
        return NULL;
    }

    napi_valuetype valuetype;
    napi_typeof(env, args[0], &valuetype);

    if (valuetype != napi_string) {
        napi_throw_type_error(env, NULL, "First argument must be a string");
        return NULL;
    }

    NSURL *url = ConvertJSStringToNSURL(env, args[0]);

    if (!url) {
        napi_throw_error(env, NULL, "Invalid file path or URL provided");
        return NULL;
    }

    @autoreleasepool {
        InitializeNSApplication();

        NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNameSendViaAirDrop];

        if (!service) {
            napi_throw_error(env, NULL, "AirDrop service not available");
            return NULL;
        }

        NSArray *items = @[url];

        if (![service canPerformWithItems:items]) {
            napi_throw_error(env, NULL, "Cannot perform AirDrop with this item");
            return NULL;
        }

        AirDropSyncDelegate *delegate = [[AirDropSyncDelegate alloc] init];
        service.delegate = delegate;

        [service performWithItems:items];

        WaitForCompletion(delegate);

        NSError *error = delegate.error;
        [delegate release];

        if (error) {
            const char* errorMsg = [[error localizedDescription] UTF8String];
            napi_throw_error(env, NULL, errorMsg);
            return NULL;
        }

        napi_value result;
        napi_get_boolean(env, true, &result);
        return result;
    }
}

// MARK: - Module Initialization
static napi_value Init(napi_env env, napi_value exports) {
    napi_value fn;
    napi_create_function(env, NULL, 0, ShareFile, NULL, &fn);
    napi_set_named_property(env, exports, "shareFile", fn);
    return exports;
}

NAPI_MODULE(NODE_GYP_MODULE_NAME, Init)
