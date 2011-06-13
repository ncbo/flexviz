package util
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.geom.Rectangle;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import flex.utils.ui.MoveResize;
	
	import mx.containers.HBox;
	import mx.controls.DataGrid;
	import mx.controls.Image;
	import mx.controls.Text;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.core.Application;
	import mx.core.Container;
	import mx.core.UIComponent;
	import mx.effects.AnimateProperty;
	import mx.effects.Parallel;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;

	/**
	 * This class is a horizontal box that contains an image and some help text that 
	 * provides information about another component or DataGrid column. 
	 * When the mouse is hovered over this component a highlight box (a gree box)
	 * is positioned over top of the other component or DataGrid column.
	 * The highlight box is animated, and is also hidden after a delay. 
	 * 
	 * It also supports highlighting two DataGrid columns as well (must be side by side).
	 * 
	 * @author Chris Callendar
	 */
	public class HelpText extends HBox 
	{
		
		private static var classConstructed:Boolean = classConstruct(); 
		private static function classConstruct():Boolean {
			var style:CSSStyleDeclaration = StyleManager.getStyleDeclaration("HelpText");
            if (!style) {
                style = new CSSStyleDeclaration();
            }
            style.defaultFactory = function():void {
        	    this.horizontalGap = 2;
           	    this.percentWidth = 100;
        	};
			StyleManager.setStyleDeclaration("HelpText", style, true);      	
            return true;
        };
        
		private var _highlightBox:UIComponent;
		private var _highlightComponent:UIComponent;
		private var _highlightColumn:DataGridColumn;
		private var _highlightColumn2:DataGridColumn;	// optional
		private var _animate:Boolean;
		private var _delay:uint;
		private var _animateDuration:uint;
		
		private var _image:Image;
		private var _text:Text;
		
		private var timeoutID:uint = 0;

		public function HelpText() {
			super();
			_animate = false;
			_delay = 300;
			_animateDuration = 400;
			addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
			addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
			percentWidth = 100;
		}
		
		override public function set icon(value:Class):void {
			super.icon = value;
			image.source = value;
			image.width = (value == null ? 0 : NaN); 
		}
		
		[Bindable("textChanged")]
    	[CollapseWhiteSpace]
		[Inspectable(category="Help", defaultValue="")]
		public function get text():String { 
			return textComponent.text;
		}
		
		public function set text(t:String):void {
			if (t != text) {
				textComponent.text = t;
				//textComponent.toolTip = t;
				dispatchEvent(new TextEvent("textChanged", false, false, t));
			}
		}
		
		[Bindable("htmlTextChanged")]
	    [CollapseWhiteSpace]
		[Inspectable(category="Help", defaultValue="")]
		public function get htmlText():String {
			return textComponent.htmlText;
		}
		
		public function set htmlText(html:String):void {
			if (html != textComponent.htmlText) {
				textComponent.htmlText = html;
				dispatchEvent(new Event("htmlTextChanged"));
			}
		}
		
		[Bindable("highlightBoxChanged")]
		[Inspectable(category="Help")]
		public function get highlightBox():UIComponent {
			return _highlightBox;
		}
		
		public function set highlightBox(box:UIComponent):void {
			if (box != _highlightBox) {
				_highlightBox = box;
				if (box && box.visible) {
					box.visible = false;
				}
				dispatchEvent(new Event("highlightBoxChanged"));
			}
		}
		
		[Bindable("highlightComponentChanged")]
		[Inspectable(category="Help")]
		public function get highlightComponent():UIComponent {
			return _highlightComponent;
		}
		
		public function set highlightComponent(hc:UIComponent):void {
			if (hc != _highlightComponent) {
				_highlightComponent = hc;
				dispatchEvent(new Event("highlightComponentChanged"));
			}
		}
		
		[Bindable("highlightColumnChanged")]
		[Inspectable(category="Help")]
		public function get highlightColumn():DataGridColumn {
			return _highlightColumn;
		}
		
		public function set highlightColumn(column:DataGridColumn):void {
			if (column != _highlightColumn) {
				_highlightColumn = column;
				dispatchEvent(new Event("highlightColumnChanged"));
			}
		}
		
		[Bindable("highlightColumnChanged")]
		[Inspectable(category="Help")]
		public function get secondHighlightColumn():DataGridColumn {
			return _highlightColumn2;
		}
		
		public function set secondHighlightColumn(column:DataGridColumn):void {
			if (column != _highlightColumn2) {
				_highlightColumn2 = column;
				dispatchEvent(new Event("highlightColumnChanged"));
			}
		}
		
		[Bindable("animateHighlightBoxChanged")]
		[Inspectable(category="Help", defaultValue="false")]
		public function get animateHighlightBox():Boolean {
			return _animate;
		}
		
		public function set animateHighlightBox(animate:Boolean):void {
			if (animate != _animate) {
				_animate = animate;
				dispatchEvent(new Event("animateHighlightBoxChanged"));
			}
		}
			
		[Bindable("animateDurationChanged", defaultValue="400")]
		[Inspectable(category="Help")]
		public function get animateDuration():uint {
			return _animateDuration;
		}
		
		public function set animateDuration(duration:uint):void {
			if (duration != _animateDuration) {
				_animateDuration = duration;
				dispatchEvent(new Event("animateDurationChanged"));
			}
		}
		
		[Bindable("delayChanged")]
		[Inspectable(category="Help", defaultValue="300")]
		public function get delay():uint {
			return _delay;
		}
		
		public function set delay(value:uint):void {
			if (value != _delay) {
				_delay = value;
				dispatchEvent(new Event("delayChanged"));
			}
		}
		
		override protected function createChildren():void {
			super.createChildren();
			addChild(image);
			addChild(textComponent);
		}
		
		public function get image():Image {
			if (_image == null) {
				_image = new Image();
				_image.width = 0;	// don't show the image
			}
			return _image;
		}
		
		public function get textComponent():Text {
			if (_text == null) {
				_text = new Text();
				_text.percentWidth = 100;
			}
			return _text;
		}
		
		private function mouseOver(event:MouseEvent):void {
			if (highlightComponent && highlightBox) {
				if (highlightColumn) {
					highlightDataGridColumn(highlightColumn, highlightComponent as DataGrid, secondHighlightColumn);
				} else {
					highlight(highlightComponent);
				}
			}
		}
		
		private function mouseOut(event:MouseEvent):void {
			if (highlightBox && highlightBox.visible) {
				unhighlight();
			}
		}
		
		private function highlight(control:UIComponent):void {
			if (isVisible(control)) {
				var helpBounds:Rectangle = getBounds(Application.application as DisplayObject);
				timeoutID = setTimeout(function():void {
					clearTimeout(timeoutID);
					timeoutID = 0;
					var app:Container = (Application.application as Container);
					helpBounds.y += app.verticalScrollPosition;
					if (helpBounds.contains(app.mouseX, app.mouseY)) {
						var bounds:Rectangle = control.getBounds(app);
						bounds.y += app.verticalScrollPosition;
						var cornerRadius:uint = uint(control.getStyle("cornerRadius"));
						moveHighlight(bounds, cornerRadius);
					}
				}, delay);
			}
		}

		private function highlightDataGridColumn(column:DataGridColumn, grid:DataGrid, secondColumn:DataGridColumn = null):void {
			if (isVisible(grid)) {
				var helpBounds:Rectangle = getBounds(Application.application as DisplayObject);
				timeoutID = setTimeout(function():void {
					clearTimeout(timeoutID);
					timeoutID = 0;
					var app:Container = (Application.application as Container);
					helpBounds.y += app.verticalScrollPosition;
					if (helpBounds.contains(app.mouseX, app.mouseY)) {
						var gridBounds:Rectangle = grid.getBounds(app);
						gridBounds.y += app.verticalScrollPosition;
						var bounds:Rectangle = new Rectangle(gridBounds.x, gridBounds.y + grid.headerHeight + 2, 
														column.width + 1, gridBounds.height - grid.headerHeight - 20);
						var xOffset:Number = 0;
						for (var i:int = 0; i < grid.columnCount; i++) {
							var dgc:DataGridColumn = (grid.columns[i] as DataGridColumn);
							if (dgc == column) {
								bounds.x += xOffset + (i > 0 ? 1 : 0);
								if ((secondColumn != null) && (grid.columns[i+1] == secondColumn)) {
									bounds.width += secondColumn.width;
								}
								break;
							}
							xOffset += dgc.width;
						}
						moveHighlight(bounds);
					}
				}, delay);
			}
		}
		
		private function unhighlight():void {
			highlightBox.visible = false;
			if (timeoutID > 0) {
				clearTimeout(timeoutID);
				timeoutID = 0;		
			}
		}
		
		private function moveHighlight(bounds:Rectangle, cornerRadius:uint = 0):void {
			highlightBox.visible = true;
			if (highlightBox.getStyle("cornerRadius") != cornerRadius) {
				highlightBox.setStyle("cornerRadius", cornerRadius);
			}

			// animate the movement of the box to the new position
			var parallel:Parallel = new Parallel();
			if (animateHighlightBox && (animateDuration > 0)) {
				var move:MoveResize = new MoveResize(highlightBox);
				move.xTo = bounds.x - 2;
				move.yTo = bounds.y - 2;
				move.duration = animateDuration;
				move.widthTo = bounds.width + 4;
				move.heightTo = bounds.height + 4;
				parallel.addChild(move);
			} else {
				// no animation
				highlightBox.x = bounds.x - 2;
				highlightBox.y = bounds.y - 2;
				highlightBox.width = bounds.width + 4;
				highlightBox.height = bounds.height + 4;
			}

			// animate the alpha value from 0 to 1
			if (animateDuration > 0) {
				var ap:AnimateProperty = new AnimateProperty(highlightBox);
				ap.property = "alpha";
				ap.fromValue = 0;
				ap.toValue = 1;
				ap.duration = animateDuration;
				parallel.addChild(ap);
			}
			if (parallel.children.length > 0) {
				parallel.play();
			}
		}
		
		public static function isVisible(disp:DisplayObject):Boolean {
			var vis:Boolean = (disp != null) && disp.visible;
			if (vis && (disp.parent != null)) {
				vis = isVisible(disp.parent);
			}
			return vis;
		}
		
		
	}
}