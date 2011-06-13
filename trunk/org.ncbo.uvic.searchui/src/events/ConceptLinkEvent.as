package events
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import org.ncbo.uvic.flex.model.NCBOSearchResultConcept;

	/**
	 * Fired when a search result concept or ontology link is clicked.
	 * 
	 * @author Chris Callendar
	 * @date Feb 4th, 2009
	 */
	public class ConceptLinkEvent extends Event
	{
		
		public static const CONCEPT_LINK_CLICKED:String 		= "conceptLinkClicked";
		public static const ONTOLOGY_LINK_CLICKED:String 		= "ontologyLinkClicked";
		public static const VISUALIZATION_LINK_CLICKED:String 	= "visualizationLinkClicked";
		public static const DETAILS_LINK_CLICKED:String 		= "detailsLinkClicked";
		
		public var concept:NCBOSearchResultConcept;
		// the mouse event that triggered this event
		public var mouseEvent:MouseEvent;
		
		public function ConceptLinkEvent(type:String, concept:NCBOSearchResultConcept, mouseEvent:MouseEvent = null) {
			super(type);
			this.concept = concept;
			this.mouseEvent = mouseEvent;
		}
		
		public function get conceptID():String {
			return concept.id;
		}
		
		public function get ontologyID():String {
			return concept.ontologyVersionID;
		}

		public function get ctrlKey():Boolean {
			return (mouseEvent != null) && mouseEvent.ctrlKey;
		}
		
	}
}