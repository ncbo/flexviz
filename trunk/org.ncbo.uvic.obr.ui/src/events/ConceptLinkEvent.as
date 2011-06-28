package events
{
	import flash.events.MouseEvent;
	
	import org.ncbo.uvic.flex.model.NCBOSearchResultConcept;

	/**
	 * Fired when a link item renderer is clicked.
	 * 
	 * @author Chris Callendar
	 * @date Feb 4th, 2009
	 */
	public class ConceptLinkEvent extends LinkEvent
	{
		
		public static const CONCEPT_LINK_CLICKED:String 	= "conceptLinkClicked";
		public static const ONTOLOGY_LINK_CLICKED:String 	= "ontologyLinkClicked";
		public static const REMOVE_LINK_CLICKED:String 		= "removeLinkClicked";
		
		public function ConceptLinkEvent(type:String, concept:NCBOSearchResultConcept, mouseEvent:MouseEvent = null) {
			super(type, concept, mouseEvent);
		}
		
		public function get concept():NCBOSearchResultConcept {
			return (linkObject as NCBOSearchResultConcept);
		}
		
		public function get conceptID():String {
			return concept.id;
		}
		
		public function get ontologyVersionID():String {
			return concept.ontologyVersionID;
		}

	}
}