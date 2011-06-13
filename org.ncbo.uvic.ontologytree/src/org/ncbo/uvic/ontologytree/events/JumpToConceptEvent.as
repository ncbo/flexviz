package org.ncbo.uvic.ontologytree.events
{
	import flash.events.Event;

	/**
	 * This event is fired when the user searches for a concept by name in the
	 * Jump To box.
	 * 
	 * @author Chris Callendar
	 * @date April 29th, 2009
	 */
	public class JumpToConceptEvent extends Event
	{
		
		public static const JUMP_TO_CONCEPT:String = "jumpToConcept";
		
		public var conceptName:String;
		
		public function JumpToConceptEvent(conceptName:String) {
			super(JUMP_TO_CONCEPT);
			this.conceptName = conceptName;
		}
		
	}
}