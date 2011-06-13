package org.ncbo.uvic.flex.events
{
	import flash.events.Event;
	
	import flex.utils.ArrayUtils;
	
	/**
	 * Generic base object for all NCBO events.  Contains a collection of objects which may
	 * or may not be defined.
	 * 
	 * @author Chris Callendar
	 */ 
	public class NCBOEvent extends Event 
	{
		
		private var _collection:Array;
		private var _error:Error;
		
		public var serverTime:int;
		public var parseTime:int;
		private var _totalTime:int;
		
		public function NCBOEvent(array:Array, type:String, error:Error = null) {
			super(type);
			this._collection = (array == null ? [] : array);
			this._error = error;
			
			serverTime = 0;
			parseTime = 0;
			_totalTime = 0;
		}
		
		override public function toString():String {
			return type + "[" + _collection.join(", ") + "]";
		}
		
		public function get totalTime():int {
			return (_totalTime == 0 ? serverTime + parseTime : _totalTime);
		}
		
		public function set totalTime(time:int):void {
			_totalTime = time;
		}
		
		public function get time():String {
			if (totalTime > 1000) {
				return (totalTime / 1000).toFixed(1) + " s";
			}
			return totalTime + " ms";
		}
		
		public function get collection():Array {
			return _collection;
		}
		
		/** Returns the first item in the list, or null if the list is empty. */		
		public function get item():Object {
			return ArrayUtils.first(_collection);
		}
		
		public function get isError():Boolean {
			return (_error != null);
		}
		
		public function get error():Error { 
			return _error;
		}
		
		public function set error(err:Error):void {
			this._error = err;
		}
		
	}
}