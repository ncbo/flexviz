package org.ncbo.uvic.flex.search
{
	import flash.events.IEventDispatcher;
	
	import org.ncbo.uvic.flex.IRestService;
	import org.ncbo.uvic.flex.model.NCBOConcept;
	
	/**
	 *  Dispatched when the operation finishes.
	 *  @eventType org.ncbo.uvic.flex.events.NCBOOperationEvent
	 */
	[Event(name="operationFinished", type="org.ncbo.uvic.flex.events.NCBOOperationEvent")]

	/**
	 *  Dispatched when the operation is stopped.
	 *  @eventType org.ncbo.uvic.flex.events.NCBOOperationStoppedEvent
	 */
	[Event(name="operationStopped", type="org.ncbo.uvic.flex.events.NCBOOperationStoppedEvent")]


	/**
	 * Performs a search operation on the rest service.
	 * This might include getting the children of a concept,
	 * getting the parents of a concept, or a combination of the two.
	 * These operations can also be combined to form multiple operations
	 * performed in sequence or in parallel.
	 * 
	 * @author Chris Callendar
	 */
	public interface IRestServiceOperation extends IEventDispatcher
	{
		
		/** 
		 * Returns the rest service object. 
		 */
		function get service():IRestService;
		
		/**
		 * Returns true if the operation is finished.
		 */
		function get finished():Boolean;
		
		/**
		 * Returns just the original concept.
		 */
		function get concept():NCBOConcept;
		
		/**
		 * Returns the neighbor concepts from the search operation.
		 * In sequential operations this value is only updated when a child operation finishes.
		 */ 
		function get neighborConcepts():Array;
		
		/** Starts the operation. */
		function start():void;
		
		/**  
		 * Stops the operation. Only applies to sequential operations that can be stopped.
		 * Fires a operationStopped event.
		 * Also calls the any callbacks that were specified in the constructor.
		 */
		function stop():void;
		
		/** Returns true if the operation can be stopped (sequential operations only). */
		function get canBeStopped():Boolean;
		
		/** Returns true if the operation has be stopped. */
		function get stopRequested():Boolean;
		
		/** Time spent on the server. */
		function get serverTime():int;
		
		/** Time spent parsing the xml returned from the server. */
		function get parseTime():int;
		
		/** Total time spent on the operation. */
		function get totalTime():int;
		
	}
}