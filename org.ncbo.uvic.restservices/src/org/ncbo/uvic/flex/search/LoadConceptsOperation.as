package org.ncbo.uvic.flex.search
{
	import org.ncbo.uvic.flex.IRestService;
	import org.ncbo.uvic.flex.events.NCBOEvent;
	import org.ncbo.uvic.flex.events.NCBOOperationEvent;

	/**
	 * Loads the details about multiple concepts from a <b>single</b> ontology.
	 * The String concept IDs are passed into the constructor in an Array.
	 * 
	 * @author Chris Callendar
	 * @date January 6th, 2009
	 */
	public class LoadConceptsOperation extends LoadConceptsFromMultipleOntologiesOperation 
	{
		
		public function LoadConceptsOperation(service:IRestService, ontologyID:String, 
					conceptIDs:Array, callbackFunction:Function = null) {
			super(service, [ ontologyID ], conceptIDs, callbackFunction);
		}
		
	}
}