#import <UIKit/UIKit.h>

@interface UIViewController (Private)
-(UIInterfaceOrientationMask)__supportedInterfaceOrientations; // iOS 6 - 11
-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation; // iOS 6 - 11
-(BOOL)isFullscreenVideoPlayerOrPresentingFullscreenVideoPlayer;
-(BOOL)isFullscreenVideoPlayer:(UIViewController *)arg1;
@end

@interface UIDevice (Private)
-(void)setOrientation:(UIInterfaceOrientation)arg1;
@end

@interface UIApplication (Private)
-(void)_setStatusBarOrientation:(UIInterfaceOrientation)arg1; // iOS 6 - 11
@end

@interface PreferencesAppController : UIApplication
-(void)popToRootOfSettingsSelectGeneral:(BOOL)arg1; // iOS 8 - 11 (Unsure about this)
@end

#define kIdentifier @"com.dgh0st.preferredrotation"
#define kSettingsPath @"/var/mobile/Library/Preferences/com.dgh0st.preferredrotation.plist"
#define kSettingsChangedNotification (CFStringRef)@"com.dgh0st.preferredrotation/settingschanged"

static BOOL isEnabled = YES;
static BOOL isHomescreenRotationDisabled = YES;
static BOOL isDisabledInCurrentApp = NO;
static BOOL isForceLandscapeVideosEnabled = YES;

%group homescreen
%hook SpringBoard
-(BOOL)homeScreenSupportsRotation { // iOS 8 - 11
	return isEnabled && isHomescreenRotationDisabled ? NO : %orig();
}

-(NSInteger)homeScreenRotationStyle { // iOS 8 - 11
	return isEnabled && isHomescreenRotationDisabled ? 0 : %orig();
}
%end
%end

%group applications
%hook UIViewController
/* Causes issues with split view controllers
-(BOOL)shouldAutorotate { // iOS 6 - 11
	BOOL result = %orig();
	// enable rotations for videos, otherwise disable auto rotation if only one interface is supported
	BOOL isVideoController = [self isKindOfClass:%c(AVPlayerViewController)] || [self isKindOfClass:%c(AVFullScreenViewController)] || [self isKindOfClass:%c(AVFullScreenPlaybackControlsViewController)];
	if (isVideoController) {
		result = YES;
	} else if (result && [self respondsToSelector:@selector(__supportedInterfaceOrientations)]) {
		UIInterfaceOrientationMask supportedOrientationsMask = [self __supportedInterfaceOrientations];
		BOOL isPortraitEnabled = supportedOrientationsMask & UIInterfaceOrientationMaskPortrait;
		BOOL isUpsideDownEnabled = supportedOrientationsMask & UIInterfaceOrientationMaskPortraitUpsideDown;
		BOOL isLandscapeLeftEnabled = supportedOrientationsMask & UIInterfaceOrientationMaskLandscapeLeft;
		BOOL isLandscapeRightEnabled = supportedOrientationsMask & UIInterfaceOrientationMaskLandscapeRight;
		if (isPortraitEnabled && !isUpsideDownEnabled && !isLandscapeLeftEnabled && !isLandscapeRightEnabled)
			result = NO;
		else if (!isPortraitEnabled && isUpsideDownEnabled && !isLandscapeLeftEnabled && !isLandscapeRightEnabled)
			result = NO;
		else if (!isPortraitEnabled && !isUpsideDownEnabled && isLandscapeLeftEnabled && !isLandscapeRightEnabled)
			result = NO;
		else if (!isPortraitEnabled && !isUpsideDownEnabled && !isLandscapeLeftEnabled && isLandscapeRightEnabled)
			result = NO;
		else
			result = YES;
	}
	return result;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)arg1 {
	BOOL result = %orig(arg1);
	if ([self respondsToSelector:@selector(__supportedInterfaceOrientations)]) {
		// open to supported interface orientation only
		UIInterfaceOrientationMask supportedOrientationsMask = [self __supportedInterfaceOrientations];
		// portrait preferred over landscape
		if ((supportedOrientationsMask & (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown)) > 0 && UIInterfaceOrientationIsLandscape(arg1)) // portrait supported only but is landscape
			result = NO;
		else if ((supportedOrientationsMask & UIInterfaceOrientationMaskLandscape) > 0 && UIInterfaceOrientationIsPortrait(arg1)) // landscape supported only but is portrait
			result = NO;
		else
			result = YES;
	}
	return result;
}*/

-(UIInterfaceOrientationMask)__supportedInterfaceOrientations { // iOS 6 - 11
	UIInterfaceOrientationMask result = %orig();
	if (isEnabled) {
		// force landscape for videos, otherwise portrait is preferred over landscape
		if ([self isFullscreenVideoPlayerOrPresentingFullscreenVideoPlayer]) {
			if (isForceLandscapeVideosEnabled)
				result = result & ~(UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown);
		} else if (!isDisabledInCurrentApp) {
			if ((result & (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown)) > 0) // portrait or upside down
				result = result & ~UIInterfaceOrientationMaskLandscape; // disable landscape (keep portrait upside down if available)
			else if ((result & UIInterfaceOrientationMaskLandscape) > 0) // landscape left or landscape right
				result = result & ~(UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown); // disable portrait and upside down
		}
	}
	return result;
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation { // iOS 6 - 11
	UIInterfaceOrientation result = %orig();
	if (isEnabled) {
		// open to landscape for videos, otherwise open to supported interface orientation only
		if ([self isFullscreenVideoPlayerOrPresentingFullscreenVideoPlayer]) {
			if (isForceLandscapeVideosEnabled && UIInterfaceOrientationIsPortrait(result))
				result = UIInterfaceOrientationLandscapeRight; // landscape right preferred over landscape left (I guess)
		} else if (!isDisabledInCurrentApp && [self respondsToSelector:@selector(__supportedInterfaceOrientations)]) {
			// open to supported interface orientation only
			UIInterfaceOrientationMask supportedOrientationsMask = [self __supportedInterfaceOrientations];
			// portrait preferred over landscape
			if ((supportedOrientationsMask & (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown)) > 0 && UIInterfaceOrientationIsLandscape(result)) // portrait supported only but is landscape
				result = UIInterfaceOrientationPortrait; // portrait preferred over upside down
			else if ((supportedOrientationsMask & UIInterfaceOrientationMaskLandscape) > 0 && UIInterfaceOrientationIsPortrait(result)) // landscape supported only but is portrait
				result = UIInterfaceOrientationLandscapeRight; // landscape right preferred over landscape left (I guess)
		}
	}
	return result;
}

-(UIInterfaceOrientation)splitViewControllerPreferredInterfaceOrientationForPresentation:(id)arg1 { // iOS 8 - 11
	UIInterfaceOrientation result = %orig(arg1);
	if (isEnabled && !isDisabledInCurrentApp && [self respondsToSelector:@selector(__supportedInterfaceOrientations)]) {
		// open to supported interface orientation only
		UIInterfaceOrientationMask supportedOrientationsMask = [self __supportedInterfaceOrientations];
		// portrait preferred over landscape
		if ((supportedOrientationsMask & (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown)) > 0 && UIInterfaceOrientationIsLandscape(result)) // portrait supported only but is landscape
			result = UIInterfaceOrientationPortrait; // portrait preferred over upside down
		else if ((supportedOrientationsMask & UIInterfaceOrientationMaskLandscape) > 0 && UIInterfaceOrientationIsPortrait(result)) // landscape supported only but is portrait
			result = UIInterfaceOrientationLandscapeRight; // landscape right preferred over landscape left (I guess)
	}
	return result;
}

-(void)viewDidLoad {
	%orig();

	if (isEnabled && ![self isFullscreenVideoPlayerOrPresentingFullscreenVideoPlayer] && !isDisabledInCurrentApp) {
		// open view controllers to preferred orientation to fix messages/other split view controller apps not opening to correct orientation (status bar and other things)
		UIApplication *application = [UIApplication sharedApplication];
		if (application != nil && [application respondsToSelector:@selector(_setStatusBarOrientation:)] && [self respondsToSelector:@selector(preferredInterfaceOrientationForPresentation)])
			[application _setStatusBarOrientation:[self preferredInterfaceOrientationForPresentation]];
	}
}
%end

%hook PreferencesAppController
-(BOOL)application:(id)arg1 didFinishLaunchingWithOptions:(id)arg2 { // iOS 6 - 11
	// fix settings app opening to general instead of root settings when opening it for first time from a landscape orientation
	BOOL result = %orig(arg1, arg2);
	if (isEnabled && !isDisabledInCurrentApp && result && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && [self respondsToSelector:@selector(popToRootOfSettingsSelectGeneral:)])
		[self popToRootOfSettingsSelectGeneral:NO];
	return result;
}
%end
%end

%group fullscreenVideos
%hook UIViewController
-(UIInterfaceOrientationMask)__supportedInterfaceOrientations { // iOS 6 - 11
	UIInterfaceOrientationMask result = %orig();
	// force landscape for videos, otherwise portrait is preferred over landscape
	if (isEnabled && [self isFullscreenVideoPlayerOrPresentingFullscreenVideoPlayer] && isForceLandscapeVideosEnabled)
		result = result & ~(UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown);
	return result;
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation { // iOS 6 - 11
	UIInterfaceOrientation result = %orig();
	// open to landscape for videos
	if (isEnabled && [self isFullscreenVideoPlayerOrPresentingFullscreenVideoPlayer] && isForceLandscapeVideosEnabled && UIInterfaceOrientationIsPortrait(result))
		result = UIInterfaceOrientationLandscapeRight; // landscape right preferred over landscape left (I guess)
	return result;
}
%end
%end

%group allApps
%hook UIViewController
-(void)viewDidAppear:(BOOL)arg1 {
	if (isEnabled && isForceLandscapeVideosEnabled) {
		// rotate videos to landscape
		UIDevice *currentDevice = [UIDevice currentDevice];
		if ([self isFullscreenVideoPlayer:self] && [UIViewController respondsToSelector:@selector(attemptRotationToDeviceOrientation)]) {
			if (currentDevice != nil && [currentDevice respondsToSelector:@selector(orientation)] && UIInterfaceOrientationIsPortrait([currentDevice orientation]) && [currentDevice respondsToSelector:@selector(setOrientation:)] && [self respondsToSelector:@selector(preferredInterfaceOrientationForPresentation)])
				[currentDevice setOrientation:[self preferredInterfaceOrientationForPresentation]];
			[UIViewController attemptRotationToDeviceOrientation];
		}
	}

	%orig(arg1);
}

%new
-(BOOL)isFullscreenVideoPlayerOrPresentingFullscreenVideoPlayer {
	if ([self isFullscreenVideoPlayer:self])
		return YES;
	UIViewController *currentViewController = self;
	while (currentViewController != nil) {
		if ([self isFullscreenVideoPlayer:currentViewController])
			return YES;
		else if ([currentViewController respondsToSelector:@selector(presentedViewController)])
			currentViewController = currentViewController.presentedViewController;
		else
			break;
	}
	return NO;
}

%new
-(BOOL)isFullscreenVideoPlayer:(UIViewController *)arg1 {
	return [arg1 isKindOfClass:%c(AVPlayerViewController)] || [arg1 isKindOfClass:%c(AVFullScreenViewController)] || [arg1 isKindOfClass:%c(AVFullScreenPlaybackControlsViewController)] || [arg1 isKindOfClass:%c(MPMoviePlayerViewController)];
}
%end
%end

static void reloadPrefs() {
	CFPreferencesAppSynchronize((CFStringRef)kIdentifier);

	NSDictionary *prefs = nil;
	if ([NSHomeDirectory() isEqualToString:@"/var/mobile"]) {
		CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (keyList != nil) {
			prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, (CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			if (prefs == nil)
				prefs = [NSDictionary dictionary];
			CFRelease(keyList);
		}
	} else {
		prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
	}

	isEnabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : YES;

	isHomescreenRotationDisabled = [prefs objectForKey:@"isHomescreenRotationDisabled"] ? [[prefs objectForKey:@"isHomescreenRotationDisabled"] boolValue] : YES;
	NSString *appId = [NSBundle mainBundle].bundleIdentifier;
	NSString *appKeyId = [NSString stringWithFormat:@"Disabled-%@", appId];
	isDisabledInCurrentApp = [prefs objectForKey:appKeyId] ? [[prefs objectForKey:appKeyId] boolValue] : NO;
	isForceLandscapeVideosEnabled = [prefs objectForKey:@"isForceLandscapeVideosEnabled"] ? [[prefs objectForKey:@"isForceLandscapeVideosEnabled"] boolValue] : YES;
}

%dtor {
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, kSettingsChangedNotification, NULL);
}

%ctor {
	reloadPrefs();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPrefs, kSettingsChangedNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

	if (isEnabled) {
		// exclude UIKit processes that aren't applications or springboard
		NSArray *args = [[NSProcessInfo processInfo] arguments];
		if (args != nil && args.count > 0) {
			NSString *execPath = args[0];
			if (execPath) {
				if ([[execPath lastPathComponent] isEqualToString:@"SpringBoard"]) { // homescreen
					%init(homescreen);
				} else if ([execPath rangeOfString:@"/Application"].location != NSNotFound) { // applications
					// YouTube, apparently doesn't need to be excluded as it has its own implementation of rotation for video
					// only initialize tweak if it isn't an excluded app (improve performance and stuff)
					%init(allApps);
					if (!isDisabledInCurrentApp)
						%init(applications);
					if (isForceLandscapeVideosEnabled)
						%init(fullscreenVideos);
				}
			}
		}
	}
}