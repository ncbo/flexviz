package ui
{
	
	import events.TagClickedEvent;
	
	import model.Ontology;
	
	import mx.collections.ArrayCollection;
	import mx.core.UIComponent;
	
	[Event(name="tagClicked", type="events.TagClickedEvent")]		

	/**
	 * Tag cloud extension which shows ontologies.
	 * 
	 * @author Chris Callendar
	 * @date March 26th, 2009
	 */
	public class OntologyTagCloud extends AnnotationTagCloud
	{
		
		private var _normalized:Boolean;
		
		public function OntologyTagCloud() {
			super();
			_normalized = false;
		}
		
		override protected function createChildren():void {
			super.createChildren();
			// use the ontology name
			tagCloud.dataField = "name";
		}
		
		public function get normalized():Boolean {
			return _normalized;
		}
		
		public function set normalized(value:Boolean):void {
			_normalized = value;
		}
		
		override public function load(ontologies:ArrayCollection):void {
			minScore = Number.MAX_VALUE;
			maxScore = Number.MIN_VALUE;
			for each (var ontology:Ontology in ontologies) {
				var score:Number = (normalized ? ontology.normalizedScore : ontology.score);
				minScore = Math.min(minScore, score);
				maxScore = Math.max(maxScore, score);
			}
			tagCloud.dataProvider = ontologies;
		} 

		override protected function tagSize(item:Object, tag:UIComponent):Number {
			var fontSize:Number = DEFAULT_FONT_SIZE;
			var tooltip:String = "";
			if (item is Ontology) {
				var ontology:Ontology = (item as Ontology);
				if (minScore < maxScore) {
					var score:Number = (normalized ? ontology.normalizedScore : ontology.score);
					var relativeScore:Number = (score - minScore) / (maxScore - minScore);
					fontSize = MIN_FONT_SIZE + (relativeScore * (MAX_FONT_SIZE - MIN_FONT_SIZE));
				}
				tooltip = ontology.name + " [" + ontology.id + "]\n" + 
							"Score: " + ontology.score + "\n" +
							"Normalized Score: " + ontology.normalizedScore + "\n" +  
							"Annotations: " + ontology.numAnnotations;
			} else {
				fontSize = super.tagSize(item, tag);
			}
			tag.toolTip = tooltip;
			return fontSize;
		}
		
	}
}