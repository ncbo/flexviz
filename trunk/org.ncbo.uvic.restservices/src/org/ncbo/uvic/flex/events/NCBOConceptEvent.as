package org.ncbo.uvic.flex.events
{
	import flex.utils.ArrayUtils;
	
	import org.ncbo.uvic.flex.model.NCBOConcept;

	/**
	 * Holds a single NCBOConcept which is the result of an event.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBOConceptEvent extends NCBOConceptsEvent
	{
		
		public function NCBOConceptEvent(concept:NCBOConcept = null, error:Error = null, 
										 ontologyVersionID:String = "0") {
			super(ArrayUtils.toArray(concept), "NCBOConceptEvent", error, ontologyVersionID);
		}
		
		public function get concept():NCBOConcept {
			return (item as NCBOConcept);
		}
		
	}
}