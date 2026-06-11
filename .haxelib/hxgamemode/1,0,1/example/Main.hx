package;

import hxgamemode.GamemodeClient;

class Main
{
	public static function main():Void
	{
		// Request we start game mode
		if (GamemodeClient.request_start() != 0)
		{
			Sys.println('Failed to request gamemode start: ${GamemodeClient.error_string()}...');
			Sys.exit(1);
		}
		else
			Sys.println('Succesfully requested gamemode to start...');

		// Simulate running a game
		Sys.sleep(10);

		// Request we end game mode (optional)
		if (GamemodeClient.request_end() != 0)
		{
			Sys.println('Failed to request gamemode end: ${GamemodeClient.error_string()}...');
			Sys.exit(1);
		}
		else
			Sys.println('Succesfully requested gamemode to end...');
	}
}
