package org.ncbo.uvic.flex
{
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	
	/**
	 * Defines the version number and date, and also has a function
	 * for opening the history.html file in a new window.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBOVersion
	{
		
		public static const VERSION:String 	= "2.3.5";
		public static const DATE:String		= "November 9th, 2010";

		public static function get VERSION_DATE():String {
			return "v" + VERSION + ", " + DATE;
		}
		
		public static function openHistoryWindow():void {
			navigateToURL(new URLRequest("history.html"), "historyWindow");
		}
		
	}
}