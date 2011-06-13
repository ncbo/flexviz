package org.ncbo.uvic.flex.events
{
	import flash.events.Event;

	/**
	 * Fired when an item is logged.
	 * 
	 * @author Chris Callendar
	 * @date October 28th, 2009
	 */
	public class NCBOLogEvent extends Event
	{
		
		public static const ITEM_LOGGED:String = "itemLogged";
		
		private var _item:Object;
		
		public function NCBOLogEvent(type:String, item:Object) {
			super(type);
			this._item = item;
		}
		
		public function get item():Object {
			return _item;
		}
		
		override public function clone():Event {
			return new NCBOLogEvent(type, item);
		}
		
	}
}