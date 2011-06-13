package org.ncbo.uvic.flex.ui
{
	import flash.events.MouseEvent;
	
	import flex.utils.ui.UIUtils;
	
	import mx.containers.ApplicationControlBar;
	import mx.containers.Panel;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.controls.RadioButton;
	import mx.core.ScrollPolicy;

	/**
	 * Lets the user choose which property to use for the node labels.
	 * 
	 * @author Chris Callendar
	 * @date September 24th, 2008
	 */
	public class NodeLabelChooser extends Panel
	{
		
		private var allProps:Array;
		private var selectedProp:String;
		private var defaultProp:String;
		private var closeHandler:Function;
		
		private var okButton:Button;
		private var buttons:Array;
		
		public function NodeLabelChooser(titleText:String, allProperties:Array, 
								selectedProperty:String, defaultProperty:String) {
			super();
			this.allProps = allProperties;
			this.selectedProp = selectedProperty;
			this.defaultProp = defaultProperty;
			this.closeHandler = closeHandler;
			this.buttons = new Array();
			
			title = titleText;
			layout = "vertical"; 
			setStyle("verticalGap", 2);
		}
		
		public function get closeFunction():Function {
			return closeHandler;
		}
		
		public function set closeFunction(callback:Function):void {
			this.closeHandler = callback;
		}
		
		override protected function createChildren():void {
			super.createChildren();
			addChild(UIUtils.createText("Choose the property you want to use for node labels:", 200));

			var vbox:VBox = new VBox();
			vbox.setStyle("verticalGap", 2);
			vbox.setStyle("paddingLeft", 12);
			vbox.setStyle("paddingTop", 2);
			vbox.setStyle("paddingRight", 8);
			vbox.setStyle("paddingBottom", 2);
			vbox.verticalScrollPolicy = ScrollPolicy.AUTO;
			vbox.horizontalScrollPolicy = ScrollPolicy.OFF;
			vbox.percentWidth = 100; 
			vbox.maxHeight = 450;
			
			for (var i:int = 0; i < allProps.length; i++) {
				var prop:String = String(allProps[i]);
				var rb:RadioButton = new RadioButton();
				rb.selected = (selectedProp == prop);
				rb.label = prop;
				rb.toolTip = prop;
				vbox.addChild(rb);
				buttons.push(rb);
			}

			var bar:ApplicationControlBar = new ApplicationControlBar();
			bar.percentWidth = 100;
			bar.setStyle("cornerRadius", 0);
			
			bar.setStyle("horizontalGap", 2);
			bar.setStyle("horizontalAlign", "center");
			bar.addChild(okButton = UIUtils.createTextButton(" OK ", okClicked, "OK"));
			bar.addChild(UIUtils.createTextButton("Cancel", cancelClicked, "Cancel"));
			bar.addChild(UIUtils.createTextButton("Default", defaultClicked, "Reset to the default property"));
			
			addChild(vbox);
			addChild(bar);
		}
		
		public function get selectedProperty():String {
			for (var i:int = 0; i < buttons.length; i++) {
			 	var rb:RadioButton = RadioButton(buttons[i]);
			 	if (rb.selected) {
			 		return rb.label;
			 	}
			}
			return null;
		}
		
		protected function okClicked(event:MouseEvent):void {
			closeHandler(true); 
		}
		
		protected function cancelClicked(event:MouseEvent):void {
			closeHandler(false); 
		}
		
		protected function defaultClicked(event:MouseEvent):void {
			for (var i:int = 0; i < buttons.length; i++) {
			 	var rb:RadioButton = RadioButton(buttons[i]);
			 	if (rb.label == defaultProp) {
			 		rb.selected = true;
			 	}
			}
		}
		
	}
}