package hxgamemode;

#if !cpp
#error 'GameMode supports only C++ target platforms.'
#end

/**
 * This class provides access to the GameMode daemon, enabling processes to request and control performance optimizations on Linux systems.
 */
@:buildXml('<include name="${haxelib:hxgamemode}/project/Build.xml" />')
@:include('gamemode_client.h')
@:unreflective
extern class GamemodeClient
{
	/**
	 * Retrieves a string describing the last error encountered by any of the GameMode functions.
	 *
	 * @return A string representing the last error message.
	 */
	@:native('gamemode_error_string')
	static function error_string():cpp.ConstCharStar;

	/**
	 * Requests that GameMode starts for the current process.
	 *
	 * @return 0 if the request was sent successfully.
	 *         -1 if the request failed.
	 */
	@:native('gamemode_request_start')
	static function request_start():Int;

	/**
	 * Requests that GameMode ends for the current process.
	 *
	 * @return 0 if the request was sent successfully.
	 *         -1 if the request failed.
	 */
	@:native('gamemode_request_end')
	static function request_end():Int;

	/**
	 * Queries the current status of GameMode for the current process.
	 *
	 * @return 0 if GameMode is inactive.
	 *         1 if GameMode is active.
	 *         2 if GameMode is active and this client is registered.
	 *         -1 if the query failed.
	 */
	@:native('gamemode_query_status')
	static function query_status():Int;

	/**
	 * Requests that GameMode starts for another process specified by its PID.
	 *
	 * @param pid The process ID of the target process.
	 * @return 0 if the request was sent successfully.
	 *         -1 if the request failed.
	 *         -2 if the request was rejected.
	 */
	@:native('gamemode_request_start_for')
	static function request_start_for(pid:cpp.PID_T):Int;

	/**
	 * Requests that GameMode ends for another process specified by its PID.
	 *
	 * @param pid The process ID of the target process.
	 * @return 0 if the request was sent successfully.
	 *         -1 if the request failed.
	 *         -2 if the request was rejected.
	 */
	@:native('gamemode_request_end_for')
	static function request_end_for(pid:cpp.PID_T):Int;

	/**
	 * Queries the current status of GameMode for another process specified by its PID.
	 *
	 * @param pid The process ID of the target process.
	 * @return 0 if GameMode is inactive.
	 *         1 if GameMode is active.
	 *         2 if GameMode is active and this client is registered.
	 *         -1 if the query failed.
	 */
	@:native('gamemode_query_status_for')
	static function query_status_for(pid:cpp.PID_T):Int;
}
