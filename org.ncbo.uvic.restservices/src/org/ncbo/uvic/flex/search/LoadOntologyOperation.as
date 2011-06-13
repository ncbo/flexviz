package org.ncbo.uvic.flex.search
{
	import org.ncbo.uvic.flex.IRestService;
	import org.ncbo.uvic.flex.events.NCBOEvent;
	import org.ncbo.uvic.flex.events.NCBOOntologyEvent;
	import org.ncbo.uvic.flex.events.NCBOOntologyOperationEvent;
	import org.ncbo.uvic.flex.model.NCBOOntology;

	/**
	 * Loads the details about a single ontology.
	 * 
	 * @author Chris Callendar
	 * @date March 2nd, 2009
	 */
	public class LoadOntologyOperation extends AbstractRestServiceOperation
	{
		
		protected var _ontology:NCBOOntology;
		
		public function LoadOntologyOperation(service:IRestService, ontologyID:String, 
											  callbackFunction:Function = null) {
			super(service, ontologyID, null, callbackFunction);
		}
		
		public function get ontology():NCBOOntology {
			return _ontology;
		}
		
		override public function start():void {
			super.start();
			
			service.getNCBOOntology(ontologyID, ontologyLoaded); 			
		}
		
		override protected function createDoneEvent():NCBOEvent {
			return new NCBOOntologyOperationEvent(ontology);
		}
		
		private function ontologyLoaded(event:NCBOOntologyEvent):void {
			addTime(event);
			
			_ontology = event.ontology;
			
			done();
		}
		
	}
	
}