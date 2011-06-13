package org.ncbo.uvic.flex.search {
	import flash.events.EventDispatcher;
	import flash.utils.getTimer;

	import org.ncbo.uvic.flex.IRestService;
	import org.ncbo.uvic.flex.events.NCBOEvent;
	import org.ncbo.uvic.flex.events.NCBOOperationEvent;
	import org.ncbo.uvic.flex.events.NCBOOperationStoppedEvent;
	import org.ncbo.uvic.flex.model.NCBOConcept;

	/**
	 *  Dispatched when the operation finishes.
	 *  @eventType org.ncbo.uvic.flex.events.NCBOOperationEvent
	 */
	[Event(name="operationFinished", type="org.ncbo.uvic.flex.events.NCBOOperationEvent")]
	[Event(name="operationStopped", type="org.ncbo.uvic.flex.events.NCBOOperationStoppedEvent")]

	/**
	 * Base class for search operations.
	 *
	 * @author Chris Callendar
	 */
	internal class AbstractRestServiceOperation extends EventDispatcher implements IRestServiceOperation {

		public static const OPERATION_FINISHED:String = NCBOOperationEvent.OPERATION_FINISHED;

		protected var _ontologyID:String;

		protected var _service:IRestService;

		protected var _concept:NCBOConcept;

		protected var _neighborConcepts:Array;

		protected var _finished:Boolean;

		protected var _callback:Function;

		protected var _seenConceptIDs:Object;

		private var _stopRequested:Boolean;

		private var _startTime:int;

		private var _totalTime:int;

		private var _serverTime:int;

		private var _parseTime:int;

		protected var error:Error;


		public function AbstractRestServiceOperation(service:IRestService, ontologyID:String, concept:NCBOConcept, callbackFunction:Function = null) {
			this._service = service;
			this._ontologyID = ontologyID;
			this._concept = concept;
			this._callback = callbackFunction;
			clear();

			// add this concept to our map
			if (concept != null) {
				_seenConceptIDs[concept.id] = true;
			}
		}

		protected function clear():void {
			this._neighborConcepts = new Array();
			this._seenConceptIDs = new Object();
			this._finished = false;
		}

		public function get service():IRestService {
			return _service;
		}

		public function get ontologyID():String {
			return _ontologyID;
		}

		public function get concept():NCBOConcept {
			return _concept;
		}

		public function get neighborConcepts():Array {
			return _neighborConcepts;
		}

		public function get callback():Function {
			return _callback;
		}

		public function get finished():Boolean {
			return _finished;
		}

		public function get serverTime():int {
			return _serverTime;
		}

		public function get parseTime():int {
			return _parseTime;
		}

		public function get totalTime():int {
			return _totalTime;
		}

		public function start():void {
			// subclasses will override this function
			_startTime = getTimer();
			_stopRequested = false;
			error = null;
		}

		public function stop():void {
			if (!_stopRequested) {
				_stopRequested = true;
				dispatchEvent(new NCBOOperationStoppedEvent(NCBOOperationStoppedEvent.OPERATION_STOPPED, this));
				done();
			}
		}

		public function get stopRequested():Boolean {
			return _stopRequested;
		}

		public function get canBeStopped():Boolean {
			return false;
		}

		protected function addTime(event:NCBOEvent):void {
			_serverTime += event.serverTime;
			_parseTime += event.parseTime;
			error = event.error;
		}

		protected function done():void {
			_totalTime = getTimer() - _startTime;
			this._finished = true;
			if (_callback != null) {
				var event:NCBOEvent = createDoneEvent();
				event.error = createError();
				event.serverTime = serverTime;
				event.parseTime = parseTime;
				event.totalTime = totalTime;

				dispatchEvent(event);
				_callback(event);
			}
		}

		protected function createError():Error {
			return error;
		}

		protected function createDoneEvent():NCBOEvent {
			return new NCBOOperationEvent(neighborConcepts, concept, null, this);
		}

		protected function addNeighborConcept(concept:NCBOConcept):Boolean {
			var added:Boolean = false;
			if (concept && !_seenConceptIDs.hasOwnProperty(concept.id)) {
				_seenConceptIDs[concept.id] = true;
				_neighborConcepts.push(concept);
				added = true;
			}
			return added;
		}


	}
}