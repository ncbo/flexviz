package org.ncbo.uvic.flex.search
{
	import org.ncbo.uvic.flex.IRestService;
	import org.ncbo.uvic.flex.events.NCBOConceptEvent;

	/**
	 * Loads the details about a single concept.  No neighbors (children/parents) are loaded.
	 * 
	 * @author Chris Callendar
	 * @date January 5th, 2009
	 */
	public class LoadConceptOperation extends AbstractRestServiceOperation
	{
		
		private var _conceptID:String;
		
		public function LoadConceptOperation(service:IRestService, ontologyID:String, conceptID:String, 
											 callbackFunction:Function = null) {
			super(service, ontologyID, null, callbackFunction);
			_conceptID = conceptID;
		}
		
		public function get conceptID():String {
			return _conceptID;
		}
		
		override public function start():void {
			super.start();
			
			service.getConceptByID(ontologyID, _conceptID, conceptLoaded); 			
		}
		
		private function conceptLoaded(event:NCBOConceptEvent):void {
			addTime(event);
			
			_concept = event.concept;
			done();
		}
		
	}
	
}