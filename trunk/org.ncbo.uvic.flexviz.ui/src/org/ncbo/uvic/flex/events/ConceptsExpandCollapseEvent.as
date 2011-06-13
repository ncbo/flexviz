package org.ncbo.uvic.flex.events
{
	import flash.events.Event;
	
	import org.ncbo.uvic.flex.model.NCBOConcept;

	/**
	 * Fired when one or more concepts are expanded or collapsed in the graph.
	 * 
	 * @author Chris Callendar
	 * @date June 30th, 2009
	 */
	public class ConceptsExpandCollapseEvent extends Event
	{
		
		public static const CONCEPTS_EXPANDED:String = "conceptsExpanded";
		public static const CONCEPTS_COLLAPSED:String = "conceptsCollapsed";
		
		private var _concepts:Array;
		
		public function ConceptsExpandCollapseEvent(type:String, concepts:Array) {
			super(type);
			this._concepts = concepts;
		}
		
		public function get concepts():Array {
			return _concepts;
		}
		
		override public function clone():Event {
			return new ConceptsExpandCollapseEvent(type, concepts);
		}
		
	}
}