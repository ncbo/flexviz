package org.ncbo.uvic.flex.search {
	import mx.utils.StringUtil;

	import org.ncbo.uvic.flex.IRestService;
	import org.ncbo.uvic.flex.events.NCBOOperationEvent;
	import org.ncbo.uvic.flex.events.NCBOOperationStartingEvent;
	import org.ncbo.uvic.flex.events.NCBOOperationStoppedEvent;
	import org.ncbo.uvic.flex.model.NCBOConcept;

	/**
	 * Fired when the operation is about to start. This event can be cancelled.
	 * @eventType org.ncbo.uvic.flex.events.NCBOOperationStartingEvent
	 */
	[Event(name="operationStarting", type="org.ncbo.uvic.flex.events.NCBOOperationStartingEvent")]

	/**
	 * Base class for sequential operations. This operation can be stopped.
	 * This operation fires an "operationStarting" event before each child operation is run.
	 * If any of the listeners cancels this event (preventDefault), then the operation isn't run
	 * which essentially pauses this operation until either stop() or restartCurrentOperation() are called.
	 *
	 * @author Chris Callendar
	 */
	public class SequenceOperation extends AbstractRestServiceOperation {

		protected var operations:Array;

		protected var index:int;

		protected var errors:Array;


		public function SequenceOperation(service:IRestService, ontologyID:String, concept:NCBOConcept, callback:Function = null) {
			super(service, ontologyID, concept, callback);

			operations = new Array();
			index = 0;
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
			if (op is SequenceOperation) {
				(op as SequenceOperation).addEventListener(
					NCBOOperationStartingEvent.OPERATION_STARTING, operationStarting);
			}
			op.addEventListener(NCBOOperationStoppedEvent.OPERATION_STOPPED, childOperationStopped);
		}

		protected function operationStarting(event:NCBOOperationStartingEvent):void {
			// clone the event - keep the operation the same! 
			var ok:Boolean = dispatchEvent(event.clone());
			// need to stop this event as well
			if (!ok) {
				event.preventDefault();
			}
		}

		protected function childOperationStopped(event:NCBOOperationStoppedEvent):void {
			stop();
		}

		override public function start():void {
			super.start();

			index = 0;
			if (!stopRequested && (operations.length > 0)) {
				var op:IRestServiceOperation = IRestServiceOperation(operations[index]);
				op.start();
			} else {
				done();
			}
		}

		/**
		 * Starts the next operation.
		 * Fires an operationStarting event.
		 */
		protected function next():void {
			index++;
			if (!stopRequested && (index < operations.length)) {
				var op:IRestServiceOperation = IRestServiceOperation(operations[index]);
				var ok:Boolean = dispatchEvent(new NCBOOperationStartingEvent(
											   NCBOOperationStartingEvent.OPERATION_STARTING, this, op));
				if (ok) {
					op.start();
				} else {
					// this operation is paused
				}
			} else {
				done();
			}
		}


		/**
		 * Restarts the current operation.
		 * Doesn't fire an operationStarting event.
		 */
		public function restartCurrentOperation():void {
			if (!stopRequested && (index < operations.length)) {
				var op:IRestServiceOperation = IRestServiceOperation(operations[index]);
				op.start();
			} else {
				done();
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
			if (stopRequested) {
				done();
			} else {
				//var id:uint = setTimeout(function():void {
				//	clearTimeout(id);
				next();
					//}, 2000);
			}
		}

		override protected function createError():Error {
			if (errors.length >= 1) {
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

		override public function get canBeStopped():Boolean {
			var canStop:Boolean = true;
			if (operations.length == 0) {
				canStop = false;
			} else if (operations.length == 1) {
				canStop = (operations[0] as IRestServiceOperation).canBeStopped;
			}
			return canStop;
		}

	}
}