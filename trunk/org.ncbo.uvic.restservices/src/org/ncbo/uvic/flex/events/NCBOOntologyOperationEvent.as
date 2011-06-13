package org.ncbo.uvic.flex.events
{
	import org.ncbo.uvic.flex.model.NCBOOntology;
	
	/**
	 * Returned from the ontology operation.  Contains a single ontology.
	 * 
	 * @author Chris Callendar
	 * @date March 2nd, 2009
	 */
	public class NCBOOntologyOperationEvent extends NCBOOperationEvent
	{
		
		private var _ontology:NCBOOntology;
		
		public function NCBOOntologyOperationEvent(ontology:NCBOOntology, error:Error = null) {
			super(null, null, error);
			_ontology = ontology;
		}
		
		public function get ontology():NCBOOntology {
			return _ontology;
		}
		
	}
}