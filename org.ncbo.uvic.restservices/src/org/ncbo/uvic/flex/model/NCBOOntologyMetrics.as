package org.ncbo.uvic.flex.model
{
	
	/**
	 * Defines the metrics associated with ontologies.
	 * 
	 * @author Chris Callendar
	 * @date December 23rd, 2009
	 */
	public class NCBOOntologyMetrics
	{
		
		public var ontologyVersionID:String;
		public var ontology:IOntology;
		public var numClasses:int;
		public var numAxioms:int;
		public var numIndividuals:int;
		public var numProperties:int;
		public var maxDepth:int;
		public var maxNumSiblings:int;
		public var avgNumSiblings:int; 
		
		public function NCBOOntologyMetrics() {
		}

		public function get ontologyName():String {
			return (ontology ? ontology.name : "");
		}

	}
}