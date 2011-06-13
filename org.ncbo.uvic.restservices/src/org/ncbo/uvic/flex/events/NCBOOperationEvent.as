package org.ncbo.uvic.flex.events {
	import org.ncbo.uvic.flex.model.NCBOConcept;
	import org.ncbo.uvic.flex.search.IRestServiceOperation;

	/**
	 * Holds a single concept which was used in an operation and the resulting neighbor concepts.
	 *
	 * @author Chris Callendar
	 */
	public class NCBOOperationEvent extends NCBOEvent {
		public static const OPERATION_FINISHED:String = "operationFinished";

		private var _concept:NCBOConcept;

		private var _op:IRestServiceOperation;

		public function NCBOOperationEvent(neighborConcepts:Array = null, concept:NCBOConcept = null, error:Error = null, op:IRestServiceOperation = null) {
			super(neighborConcepts, OPERATION_FINISHED, error);
			this._concept = concept;
			this._op = op;
		}

		public function get concept():NCBOConcept {
			return _concept;
		}

		public function get neighborConcepts():Array {
			return collection;
		}

		public function get operation():IRestServiceOperation {
			return _op;
		}

	}
}