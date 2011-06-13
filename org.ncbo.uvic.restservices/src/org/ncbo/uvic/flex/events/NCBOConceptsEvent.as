package org.ncbo.uvic.flex.events
{

	/**
	 * Holds an Array of NCBOConcept objects.
	 *
	 * @author Chris Callendar
	 */
	public class NCBOConceptsEvent extends NCBOEvent 
	{
		
		public var ontologyVersionID:String;
		
		public function NCBOConceptsEvent(nodes:Array = null, type:String = "NCBOConceptsEvent", 
										  error:Error = null, ontologyVersionID:String = "0") {
			super(nodes, type, error);
			this.ontologyVersionID = ontologyVersionID;
		}
		
		/**
		 * Returns the resulting concepts.
		 */
		public function get concepts():Array {
			return collection;
		}
		
	}
}