package org.ncbo.uvic.flex.ui
{
	import flash.events.MouseEvent;
	
	import flex.utils.ui.UIUtils;
	import flex.utils.ui.CheckBox;
	
	import mx.containers.ApplicationControlBar;
	import mx.containers.Panel;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.controls.Text;
	import mx.core.ScrollPolicy;

	/**
	 * Lets the user choose which properties to display in the node or arc tooltips.
	 * 
	 * @author Chris Callendar
	 */
	public class TooltipPropertyChooser extends Panel
	{
		private var unselectedProps:Array;
		private var allProps:Array;
		private var defaultProps:Array;
		private var closeHandler:Function;
		
		private var okButton:Button;
		private var checkboxes:Array;
		private var _messageLabel:Text;
		
		public function TooltipPropertyChooser(titleText:String, message:String, 
				allProperties:Array, unselectedProperties:Array, defaultProperties:Array) {
			super();
			this.allProps = allProperties;
			this.unselectedProps = unselectedProperties;
			this.defaultProps = defaultProperties;
			this.closeHandler = closeHandler;
			this.checkboxes = new Array();
			
			title = titleText;
			messageLabel.text = message;
			layout = "vertical"; 
			setStyle("verticalGap", 2);
		}
		
		public function get closeFunction():Function {
			return closeHandler;
		}
		
		public function set closeFunction(callback:Function):void {
			this.closeHandler = callback;
		}
		
		protected function get messageLabel():Text {
			if (_messageLabel == null) {
				_messageLabel = UIUtils.createText("", 200);
			}
			return _messageLabel;
		}
		
		override protected function createChildren():void {
			super.createChildren();
			addChild(messageLabel);

			var vbox:VBox = new VBox();
			vbox.setStyle("verticalGap", 2);
			vbox.setStyle("paddingLeft", 12);
			vbox.setStyle("paddingTop", 2);
			vbox.setStyle("paddingRight", 8);
			vbox.setStyle("paddingBottom", 2);
			vbox.percentWidth = 100;
			vbox.maxHeight = 450;			
			vbox.verticalScrollPolicy = ScrollPolicy.AUTO;
			vbox.horizontalScrollPolicy = ScrollPolicy.OFF;
			
			for (var i:int = 0; i < allProps.length; i++) {
				var prop:String = String(allProps[i]);
				var cb:CheckBox = new CheckBox();
				cb.selected = (unselectedProps.indexOf(prop) == -1);
				cb.label = prop;
				cb.toolTip = prop;
				checkboxes.push(cb);
				vbox.addChild(cb);
			}

			var bar:ApplicationControlBar = new ApplicationControlBar();
			bar.percentWidth = 100;
			bar.setStyle("cornerRadius", 0);
			
			bar.setStyle("horizontalGap", 2);
			bar.setStyle("horizontalAlign", "center");
			bar.addChild(okButton = UIUtils.createTextButton(" OK ", okClicked, "OK"));
			bar.addChild(UIUtils.createTextButton("Cancel", cancelClicked, "Cancel"));
			bar.addChild(UIUtils.createTextButton("Defaults", defaultsClicked, "Select the default properties"));
			
			addChild(vbox);
			addChild(bar);
		}
		
		public function get selectedPropertyNames():Array {
			// save the selected property names
			var properties:Array = new Array(); 
			for (var i:int = 0; i < checkboxes.length; i++) {
			 	var cb:CheckBox = CheckBox(checkboxes[i]);
			 	if (cb.selected) {
			 		properties.push(cb.label);
			 	}
			}
			return properties;
		}
		
		public function get unselectedPropertyNames():Array {
			// save the selected property names
			var properties:Array = new Array(); 
			for (var i:int = 0; i < checkboxes.length; i++) {
			 	var cb:CheckBox = CheckBox(checkboxes[i]);
			 	if (!cb.selected) {
			 		properties.push(cb.label);
			 	}
			}
			return properties;
		}
		
		protected function okClicked(event:MouseEvent):void {
			closeHandler(true); 
		}
		
		protected function cancelClicked(event:MouseEvent):void {
			closeHandler(false); 
		}
		
		protected function defaultsClicked(event:MouseEvent):void {
			for (var i:int = 0; i < checkboxes.length; i++) {
			 	var cb:CheckBox = CheckBox(checkboxes[i]);
			 	cb.selected = (defaultProps.indexOf(cb.label) != -1);
			}
		}
		
	}
}