package org.ncbo.uvic.flex.events
{
	import org.ncbo.uvic.flex.model.NCBOConcept;
	
	
	/**
	 * Contains an array of NCBOConcept objects that represent the path from the root concept
	 * down to the requested concept.  
	 * 
	 * @author Chris Callendar
	 * @date April 13th 2010
	 */
	public class NCBOPathToRootEvent extends NCBOEvent
	{
		
		public static const PATH_TO_ROOT:String = "pathToRoot";
		
		public var conceptID:String;
		public var ontologyVersionID:String;
		
		public function NCBOPathToRootEvent(conceptID:String, ontologyVersionID:String,  
					pathToRoot:Array, error:Error = null) {
			super(pathToRoot, PATH_TO_ROOT, error);
			this.conceptID = conceptID;
			this.ontologyVersionID = ontologyVersionID;
		}
		
		public function get pathToRoot():Array {
			return collection;
		}
		
	}
}