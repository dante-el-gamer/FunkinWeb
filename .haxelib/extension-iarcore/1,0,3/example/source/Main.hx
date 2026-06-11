package;

#if android
import extension.iarcore.android.IARAndroid;
#elseif ios
import extension.iarcore.ios.IARIOS;
#end

class Main extends lime.app.Application
{
	public function new():Void
	{
		super();

		#if android
		IARAndroid.onLog.add(function(message:String):Void
		{
			trace('IAR Failed with "$message"');
		});
		IARAndroid.onReviewCompleted.add(function(success:Bool):Void
		{
			trace('IAR Review Completed with "${success ? 'Success' : 'Failure'}"');
		});
		IARAndroid.onReviewError.add(function(message:String):Void
		{
			trace('IAR Review Failed with "$message"');
		});
		#end
	}

	public override function onWindowCreate():Void
	{
		#if android
		IARAndroid.init();
		IARAndroid.requestAndLaunchReviewFlow();
		#elseif ios
		IARIOS.requestReview();
		#end
	}

	public override function render(context:lime.graphics.RenderContext):Void
	{
		switch (context.type)
		{
			case CAIRO:
				context.cairo.setSourceRGB(0.75, 1, 0);
				context.cairo.paint();
			case CANVAS:
				context.canvas2D.fillStyle = '#BFFF00';
				context.canvas2D.fillRect(0, 0, window.width, window.height);
			case DOM:
				context.dom.style.backgroundColor = '#BFFF00';
			case FLASH:
				context.flash.graphics.beginFill(0xBFFF00);
				context.flash.graphics.drawRect(0, 0, window.width, window.height);
			case OPENGL | OPENGLES | WEBGL:
				context.webgl.clearColor(0.75, 1, 0, 1);
				context.webgl.clear(context.webgl.COLOR_BUFFER_BIT);
			default:
		}
	}
}
