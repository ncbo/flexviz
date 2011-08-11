package model
{
	public class Annotation
	{
		
		public var elementID:String;
		public var resourceID:String;
		public var score:Number = 0;
		public var concept:Concept;
		
		private var _context:AnnotationContext;
		public const allContexts:Array = [];

		// loaded separately
		public var ontology:Ontology;
		public var resource:Resource;
		
		public function Annotation(elementID:String, resourceID:String, score:Number, 
									concept:Concept, context:AnnotationContext = null) {
			this.elementID = elementID;
			this.resourceID = resourceID;
			this.score = (isNaN(score) ? 0 : score);
			this.concept = concept;
			this.context = context;
		}
		
		public function toString():String {
			return conceptName;
		}

		public function get conceptName():String {
			return (concept != null ? concept.name : "null");
		}
		
		public function get conceptID():String {
			return (concept != null ? concept.id : "");
		}
		
		public function get conceptNameAndOntology():String {
			if (concept && ontology) {
				return conceptName + " (" + ontologyName + ")";
			}
			return "";
		}
		
		public function get ontologyName():String {
			return (ontology != null ? ontology.name : "null");
		}

		public function get ontologyNameAndID():String {
			return (ontology != null ? ontology.nameAndID : "null");
		}

		public function get ontologyVersionID():String {
			return (ontology != null ? ontology.id : 
				(concept != null ? concept.ontologyID : ""));
		}
		
		public function get ontologyAndConceptID():String {
			return ontologyVersionID + "/" + conceptID;
		}
		
		public function get resourceName():String {
			return (resource != null ? resource.name : resourceID);
		}

		public function get resourceNameAndID():String {
			return (resource != null ? resource.nameAndID : resourceID);
		}
		
		public function get context():AnnotationContext {
			return _context;
		}
		
		public function set context(value:AnnotationContext):void {
			_context = value;
			if (value != null) {
				allContexts.push(value);
			}
		}

		public function get firstMgrepContext():AnnotationContext {
			for each (var context:AnnotationContext in allContexts) {
				if (context.isMgrep) {
					return context;
				}
			}
			return null;
		}
		
		public function get hasMgrepContext():Boolean {
			for each (var context:AnnotationContext in allContexts) {
				if (context.isMgrep) {
					return true;
				}
			}
			return false;
		}
		
		public function get mgrepContextCount():int {
			var count:int = 0;
			for each (var context:AnnotationContext in allContexts) {
				if (context.isMgrep) {
					count++;
				}
			}
			return count;
		}
		
		public function get hasMappingContext():Boolean {
			for each (var context:AnnotationContext in allContexts) {
				if (context.isMapping) {
					return true;
				}
			}
			return false;
		}
		
		public function get mappingContextCount():int {
			var count:int = 0;
			for each (var context:AnnotationContext in allContexts) {
				if (context.isMapping) {
					count++;
				}
			}
			return count;
		}
		
		public function get hasIsaContext():Boolean {
			for each (var context:AnnotationContext in allContexts) {
				if (context.isIsaClosure) {
					return true;
				}
			}
			return false;
		}
		
		public function get isaContextCount():int {
			var count:int = 0;
			for each (var context:AnnotationContext in allContexts) {
				if (context.isIsaClosure) {
					count++;
				}
			}
			return count;
		}
		
		public function get hasDirectContext():Boolean {
			for each (var context:AnnotationContext in allContexts) {
				if (context.isDirect) {
					return true;
				}
			}
			return false;
		}
		
		public function get directContextCount():int {
			var count:int = 0;
			for each (var context:AnnotationContext in allContexts) {
				if (context.isDirect) {
					count++;
				}
			}
			return count;
		}
		
	}
}