package org.ncbo.uvic.flex.events
{
	import flash.events.Event;
	
	import org.ncbo.uvic.flex.model.IConcept;

	public class NCBOConceptLoadedEvent extends Event
	{
		
		public static const CONCEPT_LOADED:String = "conceptLoadedEvent";
		
		public var concept:IConcept;
		
		public function NCBOConceptLoadedEvent(type:String, concept:IConcept) {
			super(type);
			this.concept = concept;
		}
		
		public function get conceptID():String {
			return concept.id;
		}
		
	}
}