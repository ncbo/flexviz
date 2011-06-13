package org.ncbo.uvic.flex.ui
{
	import components.dockLists.XPBlueDockList;
	import components.dockPanes.XPBlueDockPane;
	
	import mx.containers.Form;
	import mx.containers.FormItem;
	import mx.containers.VBox;
	import mx.controls.Text;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	
	import org.ncbo.uvic.flex.model.NCBOConcept;

	/**
	 * Displays all the properties of a single concept in a Form.
	 * 
	 * @author Chris Callendar
	 * @date May 1st, 2009
	 */
	public class PropertiesPane extends XPBlueDockPane
	{
		
		private var _xplist:XPBlueDockList;
		private var _form:Form;
		
		private var _concept:NCBOConcept;
		private var childrenLoaded:Boolean;
		
		override public function PropertiesPane() {
			super();
			childrenLoaded = false;
		}
		
		override protected function createChildren():void {
			super.createChildren();
			addChild(xplist);
			childrenLoaded = true;
			loadConceptProperties();
		}

		protected function get xplist():XPBlueDockList {
			if (_xplist == null) {
				_xplist = new XPBlueDockList();
				_xplist.percentWidth = 100;
				_xplist.percentHeight = 100;
				_xplist.headerTitle = "Properties";
				_xplist.addChild(form);
			}
			return _xplist; 
		}
		
		private function get form():Form {
			if (_form == null) {
				_form = new Form();
				_form.x = 0;
				_form.y = 0;
				_form.percentWidth = 100;
				//_form.percentHeight = 100;
				_form.styleName = "propertiesForm";
				_form.addEventListener(ResizeEvent.RESIZE, resizeProperties);
			}
			return _form;				
		}
		
		public function get concept():NCBOConcept {
			return _concept;
		}
		
		public function set concept(c:NCBOConcept):void {
			_concept = c;
			loadConceptProperties();
		}
		
		private function loadConceptProperties():void {
			if (childrenLoaded) {
				if (form.numChildren > 0) {
					form.removeAllChildren();
				}
				if (concept != null) {
					addProperty("ID", concept.id, 0);
					//addProperty("Name", concept.name);
					xplist.headerTitle = concept.name;// + " Properties";
					addProperty("Children", concept.childCount, 1);
					for (var i:int = 0; i < concept.propertyNames.length; i++) {
						var propName:String = String(concept.propertyNames[i]);
						var prop:Object = concept.getProperty(propName).toString();
						addProperty(propName, prop, i+2);
					}
				}
			}
		}
		
		private function addProperty(name:String, value:Object, index:int):void {
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
				formItem.verticalScrollPolicy = ScrollPolicy.AUTO;
				formItem.horizontalScrollPolicy = ScrollPolicy.OFF;
				formItem.percentWidth = 100;
				formItem.maxHeight = 120;
				formItem.label = name;
				formItem.setStyle("labelStyleName", "propertiesLabel");
				if ((index % 2) == 1) {
					formItem.styleName = "propertiesRowAlt";
				} else {
					formItem.styleName = "propertiesRow";
				}
				
				var txt:Text = new Text();
				//txt.editable = false;
				txt.percentWidth = 100;
				txt.text = valString;
				txt.styleName = "propertiesValue";
				formItem.addChild(txt);
				form.addChild(formItem);
			}
		}
		
		protected function resizeProperties(event:ResizeEvent):void {
			for (var i:int = 0; i < form.numChildren; i++) {
				var item:FormItem = FormItem(form.getChildAt(i));
				var txt:Text = Text(item.getChildAt(0));
				txt.maxWidth = form.width - txt.x;
			}
		}
		
	}
}