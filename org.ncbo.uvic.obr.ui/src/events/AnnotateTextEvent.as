package events
{
	import service.AnnotatorParameters;
	
	public class AnnotateTextEvent extends OBSEvent
	{

		public static const ANNOTATE_TEXT:String 	= "annotateText";

		public var annotatorParams:AnnotatorParameters;
		public var ontologies:Array;
		
		public function AnnotateTextEvent(items:Array = null, params:AnnotatorParameters = null, errorMsg:String = null) {
			super(ANNOTATE_TEXT, items, errorMsg);
			this.annotatorParams = params;
			this.annotationStats = []; 
			this.ontologies = [];
		}
		
		public function get annotations():Array {
			return items;
		}
		
		public function set annotations(annots:Array):void {
			super.items = annots;
		} 
		
	}
}