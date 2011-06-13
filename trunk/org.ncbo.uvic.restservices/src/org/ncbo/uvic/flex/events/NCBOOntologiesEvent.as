package org.ncbo.uvic.flex.events
{

	/**
	 * Holds an Array of the NCBOOntology objects.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBOOntologiesEvent extends NCBOEvent
	{
		
		public function NCBOOntologiesEvent(ontologies:Array = null, error:Error = null) {
			super(ontologies, "NCBOOntologiesEvent", error);
		}

		public function get ontologies():Array {
			return collection;
		}
		
	}
}