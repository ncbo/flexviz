package org.ncbo.uvic.flex.search
{
	import org.ncbo.uvic.flex.IRestService;
	import org.ncbo.uvic.flex.events.NCBOConceptsEvent;
	import org.ncbo.uvic.flex.model.NCBOConcept;
	
	/**
	 * Retrieves the parents for a concept.
	 * If the parents haven't been loaded yet then they are retrieved from the rest services and cached.
	 * 
	 * @author Chris Callendar
	 */
	public class LoadParentsOperation extends AbstractRestServiceOperation {
		
		private var superClassesOnly:Boolean;
		
		public function LoadParentsOperation(service:IRestService, ontologyID:String, child:NCBOConcept, 
											 callback:Function = null, superClassesOnly:Boolean = false) {
			super(service, ontologyID, child, callback);
			this.superClassesOnly = superClassesOnly;
		}
		
		override public function start():void {
			super.start();
			service.getParentConcepts(ontologyID, concept.id, handleParents, superClassesOnly);
		}
		
		protected function handleParents(event:NCBOConceptsEvent):void {
			addTime(event);
			
			// add these children to the collection of all artifacts
			for (var i:int = 0; i < event.concepts.length; i++) {
				var parent:NCBOConcept = NCBOConcept(event.concepts[i]);
				addNeighborConcept(parent);
			}
			
			// calls the callback function
			done();
		}
		
	}
}