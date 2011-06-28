package util
{
	
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	
	/**
	 * Utility funtions for working with the SharedObject class.
	 * 
	 * @author Chris Callendar
	 * @date March 8th, 2010
	 */
	public class Shared
	{
		
		private static const FILE:String = "OBS_cache";
		
		private static const PREVIOUS_ELEMENTS:String = "previousElements";
		
		/**
		 * Saves the previously searched for elements into the SharedObject.
		 */
		public static function savePreviousElements(elements:Array):void {
			try {
				SharedObject.defaultObjectEncoding = ObjectEncoding.AMF3;
				var shared:SharedObject = SharedObject.getLocal(FILE, "/");
				shared.data[PREVIOUS_ELEMENTS] = elements;
				// not needed
				//shared.flush();
			} catch (error:Error) {
				trace("Error saving previous elements to shared data");
				trace(error);
			}
		}
		
		/**
		 * Loads and returns all the previously search for elements from the SharedObject.
		 */
		public static function loadPreviousElements():Array {
			var elements:Array = new Array();
			try {
				SharedObject.defaultObjectEncoding = ObjectEncoding.AMF3;
				var shared:SharedObject = SharedObject.getLocal(FILE, "/");
				var array:Array = (shared.data[PREVIOUS_ELEMENTS] as Array);
				if (array != null) {
					for each (var item:Object in array) {
						if (item && item.hasOwnProperty("elementID") && item.hasOwnProperty("resourceID")) {
							var resEl:ResourceElementID = new ResourceElementID(item["elementID"], item["resourceID"]);
							elements.push(resEl);
						}
					}
				}
			} catch (error:Error) {
				trace("Error loading previous elements from shared data");
				trace(error);
			}
			return elements;
		}
		
		
		
	}
}