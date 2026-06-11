package org.haxe.extension;

import com.google.android.play.core.review.ReviewInfo;
import com.google.android.play.core.review.ReviewManager;
import com.google.android.play.core.review.ReviewManagerFactory;
import com.google.android.play.core.review.testing.FakeReviewManager;

import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;

import java.util.ArrayList;
import java.util.List;

import org.haxe.extension.Extension;
import org.haxe.lime.HaxeObject;

/**
 * The IARCore class provides functionality for integrating in-app reviews using the Google Play In-App Reviews API.
 * 
 * It provides methods to initialize review managers and request in-app review flows (real or fake).
 * 
 * @see https://developer.android.com/guide/playcore/in-app-review/kotlin-java
 */
public class IARCore extends Extension
{
	private static HaxeObject haxeObject = null;
	private static ReviewManager reviewManager = null;
	private static FakeReviewManager fakeManager = null;

	public static void init(HaxeObject object)
	{
		haxeObject = object;

		try
		{
			reviewManager = ReviewManagerFactory.create(mainContext);

			fakeManager = new FakeReviewManager(mainContext);
		}
		catch (Exception e)
		{
			if (haxeObject != null)
				haxeObject.call1("onLog", e.toString());
		}
	}

	public static void requestAndLaunchReviewFlow()
	{
		if (reviewManager == null)
		{
			if (haxeObject != null)
				haxeObject.call1("onLog", "ReviewManager is not initialized.");

			return;
		}

		Task<ReviewInfo> requestReview = reviewManager.requestReviewFlow();

		requestReview.addOnCompleteListener(new OnCompleteListener<ReviewInfo>()
		{
			@Override
			public void onComplete(Task<ReviewInfo> task)
			{
				if (task.isSuccessful())
				{
					Task<Void> launchReviewFlow = reviewManager.launchReviewFlow(mainActivity, task.getResult());

					launchReviewFlow.addOnCompleteListener(new OnCompleteListener<Void>()
					{
						@Override
						public void onComplete(Task<Void> flowTask)
						{
							if (haxeObject != null)
								haxeObject.call1("onReviewCompleted", flowTask.isSuccessful());
						}
					});
				}
				else
				{
					if (haxeObject != null)
						haxeObject.call1("onReviewError", task.getException().toString());
				}
			}
		});
	}

	public static void requestAndLaunchFakeReviewFlow()
	{
		if (fakeManager == null)
		{
			if (haxeObject != null)
				haxeObject.call1("onLog", "FakeReviewManager is not initialized.");

			return;
		}

		Task<ReviewInfo> requestReview = fakeManager.requestReviewFlow();

		requestReview.addOnCompleteListener(new OnCompleteListener<ReviewInfo>()
		{
			@Override
			public void onComplete(Task<ReviewInfo> task)
			{
				if (task.isSuccessful())
				{
					Task<Void> launchReviewFlow = fakeManager.launchReviewFlow(mainActivity, task.getResult());

					launchReviewFlow.addOnCompleteListener(new OnCompleteListener<Void>()
					{
						@Override
						public void onComplete(Task<Void> flowTask)
						{
							if (haxeObject != null)
								haxeObject.call1("onReviewCompleted", flowTask.isSuccessful());
						}
					});
				}
				else
				{
					if (haxeObject != null)
						haxeObject.call1("onReviewError", task.getException().toString());
				}
			}
		});
	}
}
