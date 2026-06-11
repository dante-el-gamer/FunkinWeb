package extension.iarcore.ios;

#if ios
/**
 * A class for managing in-app reviews on iOS Devices using StoreKit.
 */
@:buildXml('<include name="${haxelib:extension-iarcore}/project/iarcore-ios/Build.xml" />')
@:headerInclude('iar_core.hpp')
class IARIOS
{
	/**
	 * Requests an in-app review from the user, if appropriate for the current platform and context.
	 */
	public static function requestReview():Void
	{
		requestReviewIAR();
	}

	@:native('IAR_RequestReview')
	@:noCompletion
	extern private static function requestReviewIAR():Void;
}
#end