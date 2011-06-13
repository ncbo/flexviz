package org.ncbo.uvic.flex.search
{
	import org.ncbo.uvic.flex.NCBORestService;
	import org.ncbo.uvic.flex.events.NCBOOperationEvent;
	import org.ncbo.uvic.flex.model.NCBOConcept;
	
	/**
	 * Base class for parallel operations.
	 * 
	 * @author Chris Callendar
	 */
	public class ParallelOperation extends AbstractRestServiceOperation {
		
		private var operations:Array;
		private var finishedOperations:int; 
		protected var errors:Array;
		
		public function ParallelOperation(service:NCBORestService, ontologyID:String, concept:NCBOConcept, callback:Function = null) {
			super(service, ontologyID, concept, callback);
			
			operations = new Array();
			finishedOperations = 0;
			errors = [];
		}
		
		protected function addOperation(op:IRestServiceOperation):void {
			addOperationAt(op, -1);	
		}
			
		protected function addOperationAt(op:IRestServiceOperation, index:int):void {
			if ((index >= 0) && (index < operations.length)) {
				operations.splice(index, 0, op);
			} else {
				operations.push(op);
			}
		}
			
		override public function start():void {
			super.start();
			
			finishedOperations = 0;
			for (var i:int = 0; i < operations.length; i++) {
				var op:IRestServiceOperation = IRestServiceOperation(operations[i]);
				op.start();
			}
		}
				
		protected function operationFinished(event:NCBOOperationEvent):void {
			addTime(event);
			if (event.isError) {
				errors.push(event.error);
			}
			
			// add the resulting artifacts to our collection of neighbors
			for (var i:int = 0; i < event.neighborConcepts.length; i++) {
				var concept:NCBOConcept = NCBOConcept(event.neighborConcepts[i]);
				addNeighborConcept(concept);
			}
			// start the next operation
			finishedOperations++;
			if (finishedOperations >= operations.length) {
				done();
			}
		}
		
		override protected function createError():Error {
			if (errors.length > 0) {
				var msg:String = "";
				for each (var err:Error in errors) {
					if (msg.length > 0) {
						msg += "\n";
					}
					msg += err.message;
				}
				return new Error(msg); 
			}
			return null;
		}
		
	}
}