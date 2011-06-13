package org.ncbo.uvic.flex.events
{
	import org.ncbo.uvic.flex.model.NCBOOntology;

	/**
	 * Holds a single NCBOOntology object.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBOOntologyEvent extends NCBOEvent {
		
		public function NCBOOntologyEvent(ont:NCBOOntology = null, error:Error = null) {
			super((ont == null ? null : [ ont ]), "NCBOOntologyEvent", error);
		}
		
		public function get ontology():NCBOOntology {
			return (item as NCBOOntology);
		}
		
	}
}