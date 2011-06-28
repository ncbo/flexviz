package events
{
	import flash.events.Event;
	import flash.events.MouseEvent;

	/**
	 * Fired when a link is clicked.
	 * 
	 * @author Chris Callendar
	 * @date August 13th, 2009
	 */
	public class LinkEvent extends Event
	{
		
		public static const LINK_CLICKED:String 	= "linkClicked";
		
		public var linkObject:Object;
		// the mouse event that triggered this event
		public var mouseEvent:MouseEvent;

		public function LinkEvent(type:String, linkObject:Object, mouseEvent:MouseEvent = null) {
			super(type);
			this.linkObject = linkObject;
			this.mouseEvent = mouseEvent;
		}
		
		public function get ctrlKey():Boolean {
			return (mouseEvent != null) && mouseEvent.ctrlKey;
		}
				
	}
}