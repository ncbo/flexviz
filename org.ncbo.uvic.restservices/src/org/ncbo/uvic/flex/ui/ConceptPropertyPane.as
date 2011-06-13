package org.ncbo.uvic.flex.ui
{
	import flash.events.Event;
	
	import mx.containers.Form;
	import mx.containers.FormItem;
	import mx.controls.Text;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	
	import org.ncbo.uvic.flex.model.NCBOConcept;

	public class ConceptPropertyPane extends Form
	{
		
		private var _concept:NCBOConcept;
		private var loaded:Boolean;
		private var childrenLoaded:Boolean;
		
		public function ConceptPropertyPane() {
			super();
			
			this.loaded = false;
			this.childrenLoaded = false;
			this.concept = concept;
			minWidth = 100;
			minHeight = 100;
			
			//addEventListener(ResizeEvent.RESIZE, resizeTextAreas);
			addEventListener(FlexEvent.CREATION_COMPLETE, created);
			
			setStyle("indicatorGap", 8);
			setStyle("color", 0x336699);
			setStyle("fontWeight", "bold");
			setStyle("paddingLeft", 0);
			setStyle("paddingTop", 0);
			setStyle("paddingRight", 0);
			setStyle("paddingBottom", 0);
			setStyle("verticalGap", 0);
			addEventListener(ResizeEvent.RESIZE, resizeTextAreas);
		}
		
		public function get concept():NCBOConcept {
			return _concept;
		}
		
		public function set concept(c:NCBOConcept):void {
			this._concept = c;
			if (childrenLoaded) {
				loadConceptProperties();
			}
		}
		
		override protected function createChildren():void {
			super.createChildren();
			childrenLoaded = true;
			loadConceptProperties();
		}
		
		
		private function loadConceptProperties():void {
			if (numChildren > 0) {
				removeAllChildren();
			}
			if (concept != null) {
				addProperty("ID", concept.id);
				addProperty("Name", concept.name);
				addProperty("Children", concept.childCount);
				for (var i:int = 0; i < concept.propertyNames.length; i++) {
					var propName:String = String(concept.propertyNames[i]);
					var prop:Object = concept.getProperty(propName);
					if (prop is Array) {
						for each (var value:Object in prop) {
							addProperty(propName, value);
						}
					} else {
						addProperty(propName, prop);
					}
				}
				loaded = true;	
			}
		}
		
		private function addProperty(name:String, value:Object):void {
			if ((name != null) && (value != null)) {
				var valString:String;
				if (value is String) {
					valString = String(value);
				} else if (value is Number) {
					valString = Number(value).toString(10);
				} else {
					valString = value.toString();
				}
				
				var formItem:FormItem = new FormItem();
				formItem.percentWidth = 100;
				formItem.label = name;
				formItem.setStyle("paddingLeft", 5);
				formItem.setStyle("paddingTop", 5);
				formItem.setStyle("paddingRight", 18);
				formItem.setStyle("paddingBottom", 5);
				if ((numChildren % 2) == 1) {
					formItem.setStyle("backgroundColor", 0xf5fafa);
				} 
				
				var txt:Text = new Text();
				//txt.editable = false;
				txt.percentWidth = 100;
				txt.text = valString;
				txt.setStyle("color", 0x0);
				txt.setStyle("fontWeight", "normal");
				formItem.addChild(txt);
				addChild(formItem);
			}
		}
		
		private function created(event:FlexEvent):void {
			if (!loaded) {
				loadConceptProperties();
			}
		}
		
		protected function resizeTextAreas(event:Event = null):void {
			for (var i:int = 0; i < numChildren; i++) {
				var item:FormItem = FormItem(getChildAt(i));
				var txt:Text = Text(item.getChildAt(0));
				txt.maxWidth = width - txt.x;
			}
		}
		
//		protected function resizeTextAreas2(event:Event = null):void {
//			for (var i:int = 0; i < form.numChildren; i++) {
//				var item:FormItem = FormItem(form.getChildAt(i));
//				var txt:Text = Text(item.getChildAt(0));
//				if (txt.width > 0) {
//					// measures the height of one line
//					var metrics:TextLineMetrics = txt.measureText(txt.text);
//					var lineHeight:Number = metrics.height;
//					var txtHeight:Number = lineHeight;
//					if (metrics.width > txt.width) {
//						var lines:int = int(Math.ceil(metrics.width / txt.width));
//						var vgaps:int = 2 * (lines - 1);
//						txtHeight = Math.min(256, (lineHeight * lines) + vgaps);
//					}
//					txt.height = txtHeight + 2;
//				}
//			}
//		}
		
	}
}