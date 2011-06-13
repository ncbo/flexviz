package org.ncbo.uvic.flex
{
	
	/**
	 * Represents an error message returned from the Rest services.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBORestError extends Error
	{
		
		private var _shortMessage:String;
		private var _errorCode:String;
		private var _accessedResource:String;
		private var _accessDate:String;
		
		public function NCBORestError(longMessage:String = "", shortMessage:String = "", errorCode:String = "", accessedResource:String = "", accessDate:String = "") {
			super(longMessage);
			this._shortMessage = shortMessage;
			this._errorCode = errorCode;
			this._accessedResource = accessedResource;
			this._accessDate = accessDate;
		}
		
		public function get shortMessage():String {
			return _shortMessage;
		}
		
		public function get longMessage():String {
			return message;
		}
		
		public function get errorCode():String {
			return _errorCode;
		}
		
		public function get accessedResource():String {
			return _accessedResource;
		}
		
		public function get accessDate():String {
			return _accessDate;
		}

	}
}