package org.ncbo.uvic.flex.events
{
	import flash.events.Event;
	
	import org.ncbo.uvic.flex.search.IRestServiceOperation;
	import org.ncbo.uvic.flex.search.SequenceOperation;
	
	/**
	 * Fired when a child operation is about to start. This event can be cancelled.
	 * 
	 * @author Chris Callendar
	 * @date April 12th, 2010
	 */
	public class NCBOOperationStartingEvent extends Event
	{
	
		public static const OPERATION_STARTING:String = "operationStarting";
		
		private var parent:SequenceOperation;
		private var child:IRestServiceOperation;
		
		public function NCBOOperationStartingEvent(type:String, parent:SequenceOperation, child:IRestServiceOperation) {
			super(type, false, true);
			this.parent = parent;
			this.child = child;
		}
		
		override public function clone():Event {
			return new NCBOOperationStartingEvent(type, parent, child);
		}
		
		public function get parentOperation():SequenceOperation {
			return parent;
		}
		
		public function get childOperation():IRestServiceOperation {
			return child;
		}
		
		public function pauseOperation():void {
			preventDefault();
		}
		
		public function stopOperation():void {
			parent.stop();
		}
		
		public function continueOperation():void {
			parent.restartCurrentOperation();
		}
		
	}
}