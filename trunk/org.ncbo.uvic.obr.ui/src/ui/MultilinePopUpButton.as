package ui
{
	import flash.text.TextFieldAutoSize;
	
	import mx.controls.PopUpButton;

	public class MultilinePopUpButton extends PopUpButton
	{
		
		public function MultilinePopUpButton() {
			super();
		}
		
		override protected function createChildren():void {
			super.createChildren();
			
			if (textField) {
				updateTextField();
			}
		}
		
		override protected function commitProperties():void {
			var notf:Boolean = (hasFontContextChanged() && textField != null);
			super.commitProperties();

			if (notf) {
				updateTextField();
			}
		}
		
		private function updateTextField():void {
			if (textField) {
				textField.multiline = true;
				textField.wordWrap = true;
				textField.autoSize = TextFieldAutoSize.CENTER;
				//textField.background = true;
				//textField.backgroundColor = 0xdddddd;
			}
		}
		
		override protected function updateDisplayList(w:Number, h:Number):void {
			super.updateDisplayList(w, h);
		
			if (textField && (w > 0) && (h > 0)) { 
				var arrowW:Number = uint(getStyle("arrowButtonWidth"));
				if (textField.width < (w - arrowW - 2)) {
					textField.x = 2;
					textField.width = w - arrowW - 2;
				}
				var th:Number = textField.textHeight + 6;
				var changed:Boolean = false;
				if (textField.height < th) {
					textField.height = Math.min(h - 4, th);
					changed = true;
				}
				if (changed) {
					// center vertically
					textField.y = Math.max(0, (h - textField.height) / 2);
				}
			}	
			
		}
		
	}
}