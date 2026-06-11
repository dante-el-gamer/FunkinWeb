#import "iar_core.hpp"

#import <StoreKit/StoreKit.h>
#import <UIKit/UIKit.h>

void IAR_RequestReview(void)
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		if (@available(iOS 14.0, *))
		{
			UIWindowScene *firstScene = nil;

			for (UIWindowScene *connectedScene in UIApplication.sharedApplication.connectedScenes)
			{
				if (connectedScene.activationState == UISceneActivationStateForegroundActive)
				{
					firstScene = connectedScene;
					break;
				}
			}

			if (firstScene != nil)
				[SKStoreReviewController requestReviewInScene:firstScene];
		}
		else if (@available(iOS 10.3, *))
		{
			[SKStoreReviewController requestReview];
		}
	});
}
