package org.ncbo.uvic.flex.events
{
	import flash.events.Event;
	
	import org.ncbo.uvic.flex.NCBOToolTipProperties;

	/**
	 * Fired when the node or arc tooltip properties change.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBOToolTipChangedEvent extends Event
	{
		
		public static const NODE_TOOLTIP_CHANGED:String = "Node tooltips changed";
		public static const ARC_TOOLTIP_CHANGED:String  = "Arc tooltips changed";
		
		private var _properties:NCBOToolTipProperties;
		
		public function NCBOToolTipChangedEvent(type:String, properties:NCBOToolTipProperties) {
			super(type);
			this._properties = properties;
		}
		
		public function get tooltipProperties():NCBOToolTipProperties {
			return _properties;
		}
		
	}
}