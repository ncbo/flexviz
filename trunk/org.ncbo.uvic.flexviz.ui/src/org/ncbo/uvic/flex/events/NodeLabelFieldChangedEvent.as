package org.ncbo.uvic.flex.events
{
	import flash.events.Event;

	/**
	 * Fired when the node label field changes.
	 * 
	 * @author Chris Callendar
	 * @date July 15th, 2009
	 */
	public class NodeLabelFieldChangedEvent extends Event
	{
		
		public static const NODE_LABEL_FIELD_CHANGED:String = "nodeLabelFieldChanged";
		
		public var labelField:String;
		
		public function NodeLabelFieldChangedEvent(field:String) {
			super(NODE_LABEL_FIELD_CHANGED);
			this.labelField = field;
		}
		
	}
}