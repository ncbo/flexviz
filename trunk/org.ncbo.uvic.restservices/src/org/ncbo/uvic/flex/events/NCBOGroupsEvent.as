package org.ncbo.uvic.flex.events
{

	/**
 	 * Contains the sorted array of NCBOOntologyGroup objects.
 	 * 
 	 * @author Chris Callendar
 	 * @date September 10th, 2009
 	 */
	public class NCBOGroupsEvent extends NCBOEvent
	{
		
		public function NCBOGroupsEvent(groups:Array = null, error:Error = null) {
			super(groups, "NCBOGroupsEvent", error);
		}

		public function get groups():Array {
			return collection;
		}
		
	}
}