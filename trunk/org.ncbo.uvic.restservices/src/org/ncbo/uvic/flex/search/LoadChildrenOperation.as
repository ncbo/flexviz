package org.ncbo.uvic.flex.search
{
	import org.ncbo.uvic.flex.IRestService;
	import org.ncbo.uvic.flex.events.NCBOConceptsEvent;
	import org.ncbo.uvic.flex.model.NCBOConcept;
	
	/**
	 * Retrieves the children for a concept.
	 * If the children haven't been loaded yet then they are retrieved from the rest services and cached.
	 * 
	 * @author Chris Callendar
	 */
	public class LoadChildrenOperation extends AbstractRestServiceOperation {
		
		private var subClassesOnly:Boolean;
		
		public function LoadChildrenOperation(service:IRestService, ontologyID:String, concept:NCBOConcept, 
											  callback:Function = null, subClassesOnly:Boolean = false) {
			super(service, ontologyID, concept, callback);
			this.subClassesOnly = subClassesOnly;
		}
		
		override public function start():void {
			super.start();
			
			service.getChildConcepts(ontologyID, concept.id, handleChildren, subClassesOnly); 			
		}
		
		protected function handleChildren(event:NCBOConceptsEvent):void {
			addTime(event);
			
			// add these children to the collection of all concepts
			for (var i:int = 0; i < event.concepts.length; i++) {
				var child:NCBOConcept = NCBOConcept(event.concepts[i]);
				addNeighborConcept(child);
			}
			
			// calls the callback function
			done();
		}
		
	}
}