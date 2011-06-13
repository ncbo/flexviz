package org.ncbo.uvic.flex.search
{
	import org.ncbo.uvic.flex.IRestService;
	import org.ncbo.uvic.flex.model.NCBOConcept;

	/**
	 * Loads the parents of a concept, then after that has finished it loads the children.
	 * 
	 * @author Chris Callendar
	 */
	public class LoadNeighborhoodOperation extends /*ParallelOperation*/SequenceOperation {
		
		
		public function LoadNeighborhoodOperation(service:IRestService, ontologyID:String, concept:NCBOConcept, 
				callback:Function = null, subClassesOnly:Boolean = false, superClassesOnly:Boolean = false) {
			super(service, ontologyID, concept, callback);
			
			addOperation(new LoadParentsOperation(service, ontologyID, concept, operationFinished, superClassesOnly));
			addOperation(new LoadChildrenOperation(service, ontologyID, concept, operationFinished, subClassesOnly));
		}
		
	}
}