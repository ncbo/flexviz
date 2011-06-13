package org.ncbo.uvic.flex.search
{
	import org.ncbo.uvic.flex.IRestService;
	import org.ncbo.uvic.flex.events.NCBOEvent;
	import org.ncbo.uvic.flex.events.NCBOOperationsEvent;
	import org.ncbo.uvic.flex.model.NCBOConcept;

	/**
	 * Performs the same operation on multiple concepts from one ontology.  
	 * The operation will be one of: load children, parents, neighborhood, or hierarchy to root.
	 * 
	 * @author Chris Callendar
	 */
	public class MultipleConceptsOperation extends /*ParallelOperation*/SequenceOperation 
	{
		
		private var _concepts:Array;
		
		public function MultipleConceptsOperation(service:IRestService, ontologyID:String, 
							concepts:Array, operationClass:Class, callbackFunction:Function = null) {
			super(service, ontologyID, (concepts.length > 0 ? NCBOConcept(concepts[0]) : null), callbackFunction);
			this._concepts = concepts;
			
			// we want to mark all the concepts as being seen so that they don't get put into the neighborConcepts array.  
			// first we have to clear the map because it already contains the first concept
			_seenConceptIDs = new Object();
			for (var i:int = 0; i < concepts.length; i++) {
				var concept:NCBOConcept = NCBOConcept(concepts[i]);
				if (concept && !_seenConceptIDs.hasOwnProperty(concept.id)) {
					// mark this concept as being seen, so it won't be added as a neighbor from another operation
					_seenConceptIDs[concept.id] = true;
					var op:IRestServiceOperation = new operationClass(service, ontologyID, concept, operationFinished);
					addOperation(op);
				}
			}
		}
		
		override protected function createDoneEvent():NCBOEvent {
			return new NCBOOperationsEvent(neighborConcepts, concepts);
		}
		
		/**
		 * Returns the matching concepts.
		 */
		public function get concepts():Array {
			return _concepts;
		}
				
	}
}