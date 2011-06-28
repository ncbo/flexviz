package events
{
	import flash.events.MouseEvent;
	
	import model.Annotation;

	/**
	 * Fired when an annotation link is clicked.
	 * 
	 * @author Chris Callendar
	 * @date March 19th, 2009
	 */
	public class AnnotationLinkEvent extends ConceptLinkEvent
	{
		
		public static const ELEMENT_LINK_CLICKED:String 	= "annotationElementLinkClicked";
		public static const CONCEPT_LINK_CLICKED:String 	= ConceptLinkEvent.CONCEPT_LINK_CLICKED;
		public static const ONTOLOGY_LINK_CLICKED:String 	= ConceptLinkEvent.ONTOLOGY_LINK_CLICKED;
		
		public var annotation:Annotation;
		
		public function AnnotationLinkEvent(type:String, annotation:Annotation, mouseEvent:MouseEvent = null) {
			super(type, null, mouseEvent);
			this.annotation = annotation;
		}
		
		override public function get conceptID():String {
			return annotation.conceptID;
		}
		
		override public function get ontologyVersionID():String {
			return annotation.ontologyVersionID;
		}
		
	}
}