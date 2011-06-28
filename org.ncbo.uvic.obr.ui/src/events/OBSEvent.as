package events
{
	import flash.events.Event;
	
	import model.AnnotationStats;
	
	import mx.rpc.Fault;

	public class OBSEvent extends Event
	{
		
		public static const ONTOLOGIES:String 		= "ontologies";
		public static const SEMANTIC_TYPES:String 	= "semanticTypes";
		public static const MAPPING_TYPES:String 	= "mappingTypes";
		public static const RESOURCES:String		= "resources"; 
		public static const ANNOTATIONS_FOR_CONCEPT:String = "annotationsForConcept";
		public static const ANNOTATIONS_FOR_ELEMENT:String = "annotationsForResourceElement";
		public static const ANNOTATION_STATS_FOR_ELEMENT:String = "annotationStatsForResourceElement";
		public static const ANNOTATION_DETAILS:String = "annotationDetails";
		// Use case #2
		public static const ANNOTATIONS_FOR_CONCEPTS:String = "annotationsForConcepts";
		// for ontology recommendation service
		public static const ONTOLOGY_RECOMMENDATIONS:String = "ontologyRecommendations";

		public var items:Array;
		public var errorMessage:String;
		public var serverTime:int;
		public var parseTime:int;
		
		private var _fault:Fault;
		
		public var annotationStats:Array; 
		
		public function OBSEvent(type:String, items:Array = null, errorMsg:String = null) {
			super(type);
			this.items = (items == null ? [] : items);
			this.errorMessage = errorMsg;
			this.serverTime = 0;
			this.parseTime = 0;
		}
		
		override public function toString():String {
			return "OBSEvent[" + type + ": " + (isError ? errorMessage : items.join(", ")) + "]";
		}
		
		public function get totalTime():int {
			return serverTime + parseTime;
		}
		
		public function get time():String {
			if (totalTime > 1000) {
				return (totalTime / 1000).toFixed(1) + " s";
			}
			return totalTime + " ms";
		}
		
		public function get isError():Boolean {
			return (errorMessage != null);
		}
		
		public function get fault():Fault {
			return _fault;
		}
		
		public function set fault(f:Fault):void {
			_fault = f;
			if (f != null) {
				errorMessage = f.faultString;
			}
		}
		
	}
}