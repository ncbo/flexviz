package org.ncbo.uvic.flex.events
{
	import flash.events.Event;
	
	import org.ncbo.uvic.flex.search.IRestServiceOperation;
	
	/**
	 * Fired when an operation is stopped.
	 * 
	 * @author Chris Callendar
	 * @date April 12th, 2010
	 */
	public class NCBOOperationStoppedEvent extends Event
	{
	
		public static const OPERATION_STOPPED:String = "operationStopped";
		
		private var op:IRestServiceOperation;
		
		public function NCBOOperationStoppedEvent(type:String, op:IRestServiceOperation) {
			super(type);
			this.op = op;
		}
		
		override public function clone():Event {
			return new NCBOOperationStoppedEvent(type, operation);
		}
		
		public function get operation():IRestServiceOperation {
			return op;
		}
		
	}
}