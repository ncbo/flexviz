package model
{
	
	/**
	 * Groups multiple annotations together.  It is assumed that the annotations
	 * are for different concepts, but all for the same resource and have the same element ID.
	 */
	public class GroupedAnnotation extends Annotation
	{
		
		private var _annotations:Array;
		private var _filteredAnnotations:Array;
		
		public function GroupedAnnotation(annotations:Array) {
			super("", "", 0, null);
			this._annotations = annotations;
			this._filteredAnnotations = null;
			if (_annotations.length > 0) {
				var annotation:Annotation = _annotations[0];
				elementID = annotation.elementID;
				resourceID = annotation.resourceID;
				resource = annotation.resource;
				ontology = annotation.ontology;
				score = totalScore;
				concept = annotation.concept;
				context = annotation.context;
			}
		}
		
		public function addAnnotation(annotation:Annotation):void {
			annotations.push(annotation);
			score = totalScore;
		}
		
		public function get annotations():Array {
			return _annotations;
		}
		
		public function get filteredAnnotations():Array {
			return (_filteredAnnotations ? _filteredAnnotations : annotations);
		}
		
		public function get concepts():Array {
			var concepts:Array = [];
			for each (var annotation:Annotation in annotations) {
				concepts.push(annotation.concept);
			}
			return concepts;
		}
		
		public function get filteredConcepts():Array {
			var concepts:Array = [];
			for each (var annotation:Annotation in filteredAnnotations) {
				concepts.push(annotation.concept);
			}
			return concepts;
		}
		
		public function get totalScore():Number {
			var total:Number = 0;
			for each (var annotation:Annotation in annotations) {
				total += annotation.score;
			}
			return (isNaN(total) ? 0 : total);
		}
		
		public function get filteredScore():Number {
			var filtered:Number = 0;
			for each (var annotation:Annotation in filteredAnnotations) {
				filtered += annotation.score;
			}
			return (isNaN(filtered) ? 0 : filtered);
		}
		
		/**
		 * Filters the annotations based on which of the concepts are allowed.
		 * Also updates the score.
		 */
		public function filterAnnotationsByConcept(allowedConcepts:Array, allSelected:Boolean = false):Boolean {
			var pass:Boolean = true;
			if (!allSelected && allowedConcepts && (allowedConcepts.length > 0)) {
				_filteredAnnotations = [];
				var filteredScore:Number = 0;
				for each (var annotation:Annotation in annotations) {
					if (allowedConcepts.indexOf(annotation.concept) != -1) {
						filteredScore += annotation.score;
						_filteredAnnotations.push(annotation);
					}
				}
				if (isNaN(filteredScore)) {
					filteredScore = 0;
				}
				score = filteredScore;
				pass = (_filteredAnnotations.length > 0);
			} else {
				_filteredAnnotations = null;
				score = totalScore;
				pass = allSelected;
			}
			return pass;
		}
		
		
	}
}