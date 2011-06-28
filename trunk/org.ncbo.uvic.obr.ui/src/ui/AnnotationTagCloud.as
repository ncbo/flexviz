package ui
{
	
	import events.TagClickedEvent;
	
	import model.Annotation;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	
	[Event(name="tagClicked", type="events.TagClickedEvent")]		

	/**
	 * Tag cloud extension which shows concept annotations.
	 * 
	 * @author Chris Callendar
	 * @date March 16th, 2009
	 */
	public class AnnotationTagCloud extends Canvas
	{
				
		protected static const MIN_FONT_SIZE:int = 8;
		protected static const MAX_FONT_SIZE:int = 32;
		protected static const DEFAULT_FONT_SIZE:int = 12;

		protected var minScore:Number = Number.MAX_VALUE;
		protected var maxScore:Number = Number.MIN_VALUE;

		private var _tagCloud:TagCloud;

		public function AnnotationTagCloud() {
			super();
			addEventListener(ResizeEvent.RESIZE, handleTagCloudResize);
		}
		
		override protected function createChildren():void {
			super.createChildren();
			addChild(tagCloud);
		}
		
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, 
												  priority:int = 0, useWeakReference:Boolean = false):void {
			if (type == TagClickedEvent.TAG_CLICKED) {
				tagCloud.addEventListener(type, listener, useCapture, priority, useWeakReference);
			} else {
				super.addEventListener(type, listener, useCapture, priority, useWeakReference);
			}
		}
		
		override public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			if (type == TagClickedEvent.TAG_CLICKED) {
				tagCloud.removeEventListener(type, listener, useCapture);
			} else {
				super.removeEventListener(type, listener, useCapture);
			}
		}
		
		override public function hasEventListener(type:String):Boolean {
			if (type == TagClickedEvent.TAG_CLICKED) {
				return tagCloud.hasEventListener(type);
			}
			return super.hasEventListener(type);
		}
		
		override public function willTrigger(type:String):Boolean {
			if (type == TagClickedEvent.TAG_CLICKED) {
				return tagCloud.willTrigger(type);
			}
			return super.willTrigger(type);
		}
		
		public function get tagCloud():TagCloud {
			if (_tagCloud == null) {
				_tagCloud = new TagCloud();
				_tagCloud.styleName = "tagCloud";
				_tagCloud.dataField = "conceptName"; 
				_tagCloud.tagSizeFunction = tagSize;
			}
			return _tagCloud;
		}

		private function handleTagCloudResize(event:ResizeEvent):void {
			tagCloud.width = width;
			tagCloud.height = height;
		}
				
		public function load(annotations:ArrayCollection):void {
			minScore = Number.MAX_VALUE;
			maxScore = Number.MIN_VALUE;
			for each (var annot:Annotation in annotations) {
				minScore = Math.min(minScore, annot.score);
				maxScore = Math.max(maxScore, annot.score);
			}
			tagCloud.dataProvider = annotations;
		} 

		protected function tagSize(item:Object, tag:UIComponent):Number {
			var fontSize:Number = DEFAULT_FONT_SIZE;
			var tooltip:String = "";
			if (item is Annotation) {
				var annotation:Annotation = (item as Annotation);
				if (minScore < maxScore) {
					var relativeScore:Number = (annotation.score - minScore) / (maxScore - minScore);
					fontSize = MIN_FONT_SIZE + (relativeScore * (MAX_FONT_SIZE - MIN_FONT_SIZE));
				}
				tooltip = annotation.conceptName + " [" + annotation.ontologyVersionID + "]\nScore: " + annotation.score;
			} else {
				trace("random font size");
				// random font size between 8 and 32
				fontSize = 8 + Math.floor(Math.random() * 25);
			}
			tag.toolTip = tooltip;
			return fontSize;
		}
		
	}
}