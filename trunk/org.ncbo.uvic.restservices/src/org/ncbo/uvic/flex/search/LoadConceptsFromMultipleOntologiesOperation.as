package org.ncbo.uvic.flex.search {
	import org.ncbo.uvic.flex.IRestService;
	import org.ncbo.uvic.flex.events.NCBOEvent;
	import org.ncbo.uvic.flex.events.NCBOOperationEvent;
	import org.ncbo.uvic.flex.events.NCBOOperationsEvent;

	/**
	 * Loads the details about multiple concepts from <b>multiple</b> ontologies.
	 * The concept IDs and the ontology IDs are passed into the constructor in Arrays.
	 * The ontologyIDs array can either contain a single id which will be used for all concepts, or
	 * it can contain one ontology id for every concept.
	 *
	 * @author Chris Callendar
	 * @date January 6th, 2009
	 */
	public class LoadConceptsFromMultipleOntologiesOperation extends SequenceOperation {

		private var _ontologyIDs:Array;

		private var _conceptIDs:Array;

		private var _concepts:Array;

		public function LoadConceptsFromMultipleOntologiesOperation(service:IRestService, ontologyIDs:Array,
																	conceptIDs:Array, callbackFunction:Function = null) {
			super(service, (ontologyIDs.length > 0 ? ontologyIDs[0] : null), null, callbackFunction);
			_ontologyIDs = ontologyIDs;
			_conceptIDs = conceptIDs;
			_concepts = new Array();

			var ontologyID:String;
			var ok:Boolean = true;
			// allow the ontologyIDs array to only contain a single ontologyID which will be used for all concepts
			if (ontologyIDs.length == 1) {
				ontologyID = ontologyIDs[0];
			} else if (ontologyIDs.length != conceptIDs.length) {
				trace("The ontologyIDs array must be the same length as the conceptIDs array, this operation will not continue.");
				ok = false;
			}
			if (ok) {
				var seenConcepts:Object = new Object();
				for (var i:int = 0; i < conceptIDs.length; i++) {
					var id:String = conceptIDs[i];
					if (i < ontologyIDs.length) {
						ontologyID = ontologyIDs[i];
					}
					if ((id != null) && !seenConcepts.hasOwnProperty(id) && (ontologyID != null)) {
						seenConcepts[id] = true;
						addOperation(new LoadConceptOperation(service, ontologyID, id, operationFinished));
					}
				}
			}
		}

		override protected function operationFinished(event:NCBOOperationEvent):void {
			if (event.isError && (event.error.message.toLowerCase() == "concept(s) not found") && (event.operation is LoadConceptOperation)) {
				var op:LoadConceptOperation = (event.operation as LoadConceptOperation);
				event.error.message = "Unable to load term " + op.conceptID + " (" + op.ontologyID + ")";
			}
			addTime(event);

			// if the concept couldn't be loaded then it will be null			
			if (event.concept) {
				// add the returned concept to our collection of matching concepts
				_concepts.push(event.concept);

				// set the concept property to be the first returned concept
				if (_concept == null) {
					_concept = event.concept;
				}
			}

			if (event.isError) {
				errors.push(event.error);
			}

			// start the next operation
			next();
		}

		override protected function createDoneEvent():NCBOEvent {
			return new NCBOOperationsEvent(new Array(), concepts);
		}

		/**
		 * Returns the concepts that were loaded from this operation.
		 */
		public function get concepts():Array {
			return _concepts;
		}

		/**
		 * Returns the intial concept ids.
		 */
		public function get conceptIDs():Array {
			return _conceptIDs;
		}

		/**
		 * Returns the intial ontology ids.
		 */
		public function get ontologyIDs():Array {
			return _ontologyIDs;
		}

	}
}