package org.ncbo.uvic.flex
{
	
	/**
	 * Stores the parameters needed for sending data to the rest service and for handling the result.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBORestParams
	{
		
		public var url:String;
		public var xmlHandler:Function;
		public var callback:Function;
		public var allowMultipleCalls:Boolean;
		public var alertErrors:Boolean;
		
		/** Time spent on the server. */
		public var serverTime:int;
		/** Time spent parsing the xml. */
		public var parseTime:int;
		
		/** The number of times trying to resend the request. */ 
		public var retryCount:int; 
		
		public var log:Boolean;
		
		public function NCBORestParams(url:String, xmlHandler:Function, callback:Function, 
							allowMultipleCalls:Boolean, alertErrors:Boolean = true, log:Boolean = true) {
			this.url = url;
			this.xmlHandler = xmlHandler;
			this.callback = callback;
			this.allowMultipleCalls = allowMultipleCalls;
			this.alertErrors = alertErrors;
			this.retryCount = 0;
			this.log = log;
		}
			
		public function toString():String {
			return url;
		}
		
		public function get totalTime():int {
			return serverTime + parseTime;
		}
		
		public function get time():String {
			return totalTime + " ms";
		}
		
	}
}