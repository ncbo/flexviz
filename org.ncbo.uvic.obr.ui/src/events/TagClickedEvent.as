package events
{
	import flash.events.Event;
	import flash.events.MouseEvent;

	public class TagClickedEvent extends Event
	{
		
		public static const TAG_CLICKED:String = "tagClicked";
		
		public var item:Object;
		public var mouseEvent:MouseEvent;
		
		public function TagClickedEvent(type:String, item:Object, mouseEvent:MouseEvent = null) {
			super(type);
			this.item = item;
			this.mouseEvent = mouseEvent;
		}
		
		public function get ctrlKey():Boolean {
			return (mouseEvent && mouseEvent.ctrlKey);
		}
		
	}
}