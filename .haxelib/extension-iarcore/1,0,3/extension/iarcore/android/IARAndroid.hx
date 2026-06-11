package extension.iarcore.android;

#if android
import lime.app.Event;
import lime.system.JNI;

/**
 * A class for managing in-app reviews on Android using Google Play's In-App Review API.
 */
class IARAndroid
{
	/** Event for logging debug messages. */
	public static final onLog:Event<String->Void> = new Event<String->Void>();

	/** Event triggered when a review flow completes. */
	public static final onReviewCompleted:Event<Bool->Void> = new Event<Bool->Void>();

	/** Event triggered when a review flow fails. */
	public static final onReviewError:Event<String->Void> = new Event<String->Void>();

	/** Cache for storing created static JNI method references. */
	@:noCompletion
	private static var staticMethodsCache:Map<String, Dynamic> = [];

	/**
	 * Initializes the review manager by calling the corresponding Java method and registering the callback object.
	 */
	public static function init():Void
	{
		final initJNI:Null<Dynamic> = createJNIStaticMethod('org/haxe/extension/IARCore', 'init', '(Lorg/haxe/lime/HaxeObject;)V');

		if (initJNI != null)
			initJNI(new IARAndroidCallbackObject());
	}

	/**
	 * Requests the in-app review information and launches the review dialog when ready.
	 */
	public static function requestAndLaunchReviewFlow():Void
	{
		final requestAndLaunchReviewFlowJNI:Null<Dynamic> = createJNIStaticMethod('org/haxe/extension/IARCore', 'requestAndLaunchReviewFlow', '()V');

		if (requestAndLaunchReviewFlowJNI != null)
			requestAndLaunchReviewFlowJNI();
	}

	/**
	 * Requests and launches a fake review flow (typically used for testing).
	 */
	public static function requestAndLaunchFakeReviewFlow():Void
	{
		final requestAndLaunchFakeReviewFlowJNI:Null<Dynamic> = createJNIStaticMethod('org/haxe/extension/IARCore', 'requestAndLaunchFakeReviewFlow', '()V');

		if (requestAndLaunchFakeReviewFlowJNI != null)
			requestAndLaunchFakeReviewFlowJNI();
	}

	/**
	 * Retrieves or creates a cached static method reference.
	 * @param className The name of the Java class containing the method.
	 * @param methodName The name of the method to call.
	 * @param signature The JNI method signature string (e.g., "()V", "(Ljava/lang/String;)V").
	 * @param cache Whether to cache the result (default true).
	 * @return A dynamic reference to the static method, or null if it couldn't be created.
	 */
	@:noCompletion
	private static function createJNIStaticMethod(className:String, methodName:String, signature:String, cache:Bool = true):Null<Dynamic>
	{
		@:privateAccess
		className = JNI.transformClassName(className);

		final key:String = '$className::$methodName::$signature';

		if (cache && !staticMethodsCache.exists(key))
			staticMethodsCache.set(key, JNI.createStaticMethod(className, methodName, signature));
		else if (!cache)
			return JNI.createStaticMethod(className, methodName, signature);

		return staticMethodsCache.get(key);
	}
}

@:noCompletion
private class IARAndroidCallbackObject #if (lime >= "8.0.0") implements JNISafety #end
{
	public function new():Void {}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onLog(message:String):Void
	{
		if (IARAndroid.onLog != null)
			IARAndroid.onLog.dispatch(message);
	}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onReviewCompleted(success:Bool):Void
	{
		if (IARAndroid.onReviewCompleted != null)
			IARAndroid.onReviewCompleted.dispatch(success);
	}

	@:keep
	#if (lime >= "8.0.0")
	@:runOnMainThread
	#end
	public function onReviewError(error:String):Void
	{
		if (IARAndroid.onReviewError != null)
			IARAndroid.onReviewError.dispatch(error);
	}
}
#end
