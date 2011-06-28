package events
{
	import flash.events.MouseEvent;
	
	import model.AnnotationContext;

	/**
	 * Fired when an annotation context link is clicked.
	 * 
	 * @author Chris Callendar
	 * @date August 13th, 2009
	 */
	public class AnnotationContextLinkEvent extends LinkEvent
	{
		
		public static const CONTEXT_LINK_CLICKED:String = "annotationContextLinkClicked";
		
		public function AnnotationContextLinkEvent(type:String, context:AnnotationContext, mouseEvent:MouseEvent = null) {
			super(type, context, mouseEvent);
		}

		public function get context():AnnotationContext {
			return (linkObject as AnnotationContext);
		}
		
		public function get conceptID():String {
			return context.conceptID;
		}
		
		public function get conceptName():String {
			return context.conceptName;
		}
		
		public function get ontologyVersionID():String {
			return context.ontologyVersionID;
		}
		
	}
}