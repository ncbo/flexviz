package org.ncbo.uvic.flex.ui
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import flex.utils.ui.ContentWindow;
	
	import mx.containers.Form;
	import mx.containers.FormItem;
	import mx.controls.Text;
	import mx.core.Application;
	import mx.core.ScrollPolicy;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	import mx.managers.PopUpManager;
	
	import org.ncbo.uvic.flex.model.NCBOOntology;
	import org.ncbo.uvic.flex.model.NCBOOntologyMetrics;

	/**
	 * Displays ontology metrics.
	 * 
	 * @author Chris Callendar
	 * @date December 23rd, 2009
	 */
	public class OntologyMetricsWindow extends ContentWindow
	{
		
		private var _metrics:NCBOOntologyMetrics;
		private var loaded:Boolean;
		private var childrenLoaded:Boolean;
		private var form:Form;
		
		public function OntologyMetricsWindow(metrics:NCBOOntologyMetrics = null, canResize:Boolean = true, canMove:Boolean = true) {
			super(ContentWindow.OK, ContentWindow.OK);
			this.metrics = metrics;
			this.loaded = false;
			this.childrenLoaded = false;
			resizable = canResize;
			movable = canMove;
			minWidth = 100;
			minHeight = 100;
			if (metrics && metrics.ontologyName) {
				title = "Ontology Metrics for " + metrics.ontologyName;
			} else {
				title = "Ontology Metrics";
			}

			layout = "absolute"; 
			verticalScrollPolicy = ScrollPolicy.AUTO;
			horizontalScrollPolicy = ScrollPolicy.OFF;
			var app:Application = (Application.application as Application);
			maxHeight = app.height - 20;
			width = Math.min(350, app.width - 20);
			setStyle("verticalGap", 2);
			
			//addEventListener(ResizeEvent.RESIZE, resizeTextAreas);
			addEventListener(FlexEvent.CREATION_COMPLETE, created);
		}
		
		public static function show(parent:DisplayObject, metrics:NCBOOntologyMetrics, styleName:String = null, 
					modal:Boolean = false, canResize:Boolean = true):OntologyMetricsWindow {
			var window:OntologyMetricsWindow = new OntologyMetricsWindow(metrics, canResize);
			if (styleName) {
				window.styleName = styleName;
			}
			PopUpManager.addPopUp(window, parent, modal);
			PopUpManager.centerPopUp(window);
			var closeHandler:Function = function(event:CloseEvent):void {
				window.removeEventListener(CloseEvent.CLOSE, closeHandler);
				PopUpManager.removePopUp(window);
			};
			window.addEventListener(CloseEvent.CLOSE, closeHandler);
			return window;
		}
		
		public function get metrics():NCBOOntologyMetrics {
			return _metrics;
		}
		
		public function set metrics(m:NCBOOntologyMetrics):void {
			this._metrics = m;
			if (childrenLoaded) {
				loadMetrics();
			}
		}
		
		override protected function createChildren():void {
			super.createChildren();
			
			form = new Form();
			form.x = 0;
			form.y = 0;
			form.percentWidth = 100;
			//form.percentHeight = 100;
			form.setStyle("indicatorGap", 8);
			form.setStyle("color", 0x336699);
			form.setStyle("fontWeight", "bold");
			form.setStyle("paddingLeft", 0);
			form.setStyle("paddingTop", 0);
			form.setStyle("paddingRight", 0);
			form.setStyle("paddingBottom", 0);
			form.setStyle("verticalGap", 0);
			form.addEventListener(ResizeEvent.RESIZE, resizeTextAreas);
			
			loadMetrics();
			
			container.addChild(form);
			
			childrenLoaded = true;
		}
		
		private function loadMetrics():void {
			if (form.numChildren > 0) {
				form.removeAllChildren();
			}
			if (metrics) {
				addProperty("Name", metrics.ontologyName);
				addProperty("ID", metrics.ontologyVersionID);
				if (metrics.ontology is NCBOOntology) {
					addProperty("Version", NCBOOntology(metrics.ontology).version);
				}
				addProperty("Number Of Classes", metrics.numClasses);
				addProperty("Number Of Individuals", metrics.numIndividuals, metrics.numIndividuals > 0);
				addProperty("Number Of Properties", metrics.numProperties, metrics.numProperties > 0);
				addProperty("Number Of Axioms", metrics.numAxioms, metrics.numAxioms > 0);
				addProperty("Maximum Depth", metrics.maxDepth);
				addProperty("Maximum Number Of Siblings", metrics.maxNumSiblings);
				addProperty("Average Number Of Siblings", metrics.avgNumSiblings);
				loaded = true;	
			}
		}
		
		private function addProperty(name:String, value:Object, add:Boolean = true):void {
			if (add && (name != null) && (value != null)) {
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
				if ((form.numChildren % 2) == 1) {
					formItem.setStyle("backgroundColor", 0xf5fafa);
				} 
				
				var txt:Text = new Text();
				//txt.editable = false;
				txt.percentWidth = 100;
				txt.text = valString;
				txt.setStyle("color", 0x0);
				txt.setStyle("fontWeight", "normal");
				formItem.addChild(txt);
				form.addChild(formItem);
			}
		}
		
		private function created(event:FlexEvent):void {
			if (!loaded) {
				loadMetrics();
			}
		}
		
		protected function resizeTextAreas(event:Event = null):void {
			for (var i:int = 0; i < form.numChildren; i++) {
				var item:FormItem = FormItem(form.getChildAt(i));
				var txt:Text = Text(item.getChildAt(0));
				txt.maxWidth = form.width - txt.x;
			}
		}
		
	}
}