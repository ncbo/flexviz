package org.ncbo.uvic.flex.search
{
	import org.ncbo.uvic.flex.IRestService;
	import org.ncbo.uvic.flex.events.NCBOEvent;
	import org.ncbo.uvic.flex.events.NCBOOntologiesOperationsEvent;
	import org.ncbo.uvic.flex.events.NCBOOntologyOperationEvent;
	import org.ncbo.uvic.flex.events.NCBOOperationEvent;
	import org.ncbo.uvic.flex.model.NCBOOntology;

	/**
	 * Loads the details about multiple ontologies.
	 * The ontology IDs are passed into the constructor in Arrays.
	 * 
	 * @author Chris Callendar
	 * @date March 2nd, 2009
	 */
	public class LoadOntologiesOperation extends SequenceOperation 
	{
		
		private var _ontologyIDs:Array;
		private var _ontologies:Array;
		
		public function LoadOntologiesOperation(service:IRestService, ontologyIDs:Array, callbackFunction:Function = null) {
			super(service, (ontologyIDs.length > 0 ? ontologyIDs[0] : null), null, callbackFunction);
			_ontologyIDs = ontologyIDs;
			_ontologies = [];

			var ontologyID:String;
			var seenOntologyIDs:Object = new Object();
			for (var i:int = 0; i < ontologyIDs.length; i++) {
				var id:String = ontologyIDs[i];
				if ((id != null) && !seenOntologyIDs.hasOwnProperty(id)) {
					seenOntologyIDs[id] = true;
					addOperation(new LoadOntologyOperation(service, id, operationFinished));
				}
			} 
		}
				
		override protected function operationFinished(event:NCBOOperationEvent):void {
			addTime(event);
			
			// add the returned ontoloy to the collection
			var ontology:NCBOOntology = (event as NCBOOntologyOperationEvent).ontology;
			if (ontology) {
				_ontologies.push(ontology);
			}
			if (event.isError) {
				errors.push(event.error);
			}

			// start the next operation
			next();
		}
		
		override protected function createDoneEvent():NCBOEvent {
			return new NCBOOntologiesOperationsEvent(ontologies);
		}
		
		/**
		 * Returns the concepts that were loaded from this operation.
		 */
		public function get ontologies():Array {
			return _ontologies;
		}
		
		/**
		 * Returns the intial ontology ids.
		 */
		public function get ontologyIDs():Array {
			return _ontologyIDs;
		}	
		
	}
}