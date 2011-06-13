package org.ncbo.uvic.flex.ui
{
	import ca.uvic.cs.chisel.flexviz.model.GroupedNode;
	import ca.uvic.cs.chisel.flexviz.renderers.DefaultNodeRenderer;
	import ca.uvic.cs.chisel.flexviz.renderers.FlexGraphToolTip;
	import ca.uvic.cs.chisel.flexviz.renderers.IColorProvider;
	
	import mx.controls.Image;
	
	import org.ncbo.uvic.flex.NCBOToolTipProperties;
	import org.ncbo.uvic.flex.model.NCBOConcept;

	/**
	 * NCBO specific implementation of the DefaultNodeRenderer.
	 * Adds the "+" icon and the custom tooltips.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBONodeRenderer extends DefaultNodeRenderer
	{
		
		[Embed(source='/assets/plus_round.gif')]
      	private static var plusIcon:Class;
      	
      	private static const PLUS_SIZE:int = 9;
      	private static const HALF_HEIGHT:int = 5;
      	
		// provides the NCBOConcept given the node id
		private var _conceptFunction:Function;
		// determines if the children of a concept are all showing
		private var _childrenVisibleFunction:Function;
		// if true then a plus icon will be rendererd to indicate that this node has hidden 
		// children that can be expanded
		private var _renderPlus:Boolean = true; 
		
		private var _plus:Image;
		
		//private var childLabel:Triangle;
		
		private var hasChildren:Boolean;
		
		public function NCBONodeRenderer(ncboColorProvider:IColorProvider = null, 
										getConceptFunction:Function = null,
										childrenVisibleFunction:Function = null,
										renderPlus:Boolean = true) {
			super();
			colorProvider = ncboColorProvider;
			_conceptFunction = getConceptFunction;
			_childrenVisibleFunction = childrenVisibleFunction;
			renderPlusIcon = renderPlus;
			hasChildren = false;
		}
		
		override protected function addChildren():void {
//			childLabel = new Triangle();
//			childLabel.size = 0;
//			childLabel.visible = false;
//			childLabel.setStyle("bottom", 0);
//			childLabel.setStyle("horizontalCenter", 0);
//		 	childLabel.setStyle("fillAlpha", 0.5);
//			addChild(childLabel);

			super.addChildren();
			
			// add the plus image by default
			addRemovePlusImage(true);
		}
		
		protected function get plusImage():Image {
			if (_plus == null) {
				_plus = new Image();
				_plus.source = plusIcon;
				_plus.width = PLUS_SIZE;
				_plus.height = PLUS_SIZE;
				//_plus.setStyle("bottom", 0);
			}
			return _plus;
		}
		
		private function addRemovePlusImage(add:Boolean = true):void {
			if (add) {
				if (plusImage.parent == null) {
					addChild(plusImage);
				}
				// don't need padding on the bottom, this way the plus image appears to "overlap" the node
				hbox.setStyle("paddingBottom", 0);
			} else {
				if (plusImage.parent != null) {
					removeChild(plusImage);
				}
				hbox.setStyle("paddingBottom", 4);
			}
		}
		
		override public function newInstance():* {
			var renderer:NCBONodeRenderer = new NCBONodeRenderer(colorProvider, 
					getConceptFunction, childrenVisibleFunction, renderPlusIcon);
			copyProperties(renderer);
			return renderer;
		}
		
		/** This function will return an NCBOConcept given an id. */
		public function get getConceptFunction():Function {
			return _conceptFunction;
		}
		
		/** Sets the function that will return an NCBOConcept given an id. */
		public function set getConceptFunction(func:Function):void {
			_conceptFunction = func;
		}
		
		/** This function will return an NCBOConcept given an id. */
		public function get childrenVisibleFunction():Function {
			return _childrenVisibleFunction;
		}
		
		/** Sets the function that will return an NCBOConcept given an id. */
		public function set childrenVisibleFunction(func:Function):void {
			_childrenVisibleFunction = func;
		}
		
		/** Gets whether the plus icon should be rendered. */
		public function get renderPlusIcon():Boolean {
			return _renderPlus;
		}
		
		/** 
		 * Sets whether the plus icon should be rendered. It will only show
		 * up on nodes that have hidden children.
		 */
		public function set renderPlusIcon(renderPlus:Boolean):void {
			if (_renderPlus != renderPlus) {
				_renderPlus = renderPlus;
				// toggle whether the plus image is shown
				addRemovePlusImage(_renderPlus);
			}
		}
		
		protected function getConcept():NCBOConcept {
			var concept:NCBOConcept = null;
			if (node && (getConceptFunction != null)) {
				concept = getConceptFunction(node.id);
			}
			return concept;
		}
		
		override public function set data(value:Object):void {
			super.data = value;
			var concept:NCBOConcept = getConcept();
			if (concept != null) {
				hasChildren = (concept.childCount > 0);
				if (hasChildren) {
				 	//childLabel.toolTip = concept.childCount + (concept.childCount == 1 ? " child" : " children");
					//var str:String = concept.childCount.toString();

					// use a log scale to determine the size of the triangle
					// method #1 - use discrete buckets: 0-9, 10-99, 100-999, ...
					// sizes will be: 12, 18, 24, 30, ...
//					var size:Number = 12 + ((str.length - 1) * 6);
//				 	childLabel.size = size;
				 	
				 	// method #2 - just use a continuum of the log value of the number of children
				 	// sizes will be between [12 - 30]
					//var size:Number = 12 + (Util.log10(concept.childCount) * 6);
				 	//childLabel.size = size;
				 	
				 	// method #3 - try base 6?
				 	// sizes will be between [12 - 50]
					//var size:Number = 12 + (Util.log(concept.childCount, 6) * 6);
					//trace(concept.name + " " + concept.childCount + " " + size);
				 	//childLabel.size = Math.min(50, size);
				 	
				 	// choose a gray color like: 0xcccccc, 0xbbbbbb, 0xaaaaaa, ...
				 	// darker for higher number of children
				 	//var color:uint = 0xcccccc - ((str.length - 1) * 0x111111);
					//childLabel.setStyle("fillColor", color);
					
			 		//this.height += size;
			 	} else {
			 		plusImage.visible = false;
				}
			}
		}
				
		override protected function addToolTipValues(tooltip:FlexGraphToolTip):void {
			var useDefault:Boolean = true;
			
			var concept:NCBOConcept = getConcept();
			if (concept) {
				var props:NCBOToolTipProperties = NCBOToolTipProperties.getInstance();
				
				// add the defined properties
				if (!props.isNodePropertyHidden(NCBOToolTipProperties.ID)) {
					tooltip.addValue(NCBOToolTipProperties.ID + ": ", concept.id);
				}
				if (!props.isNodePropertyHidden(NCBOToolTipProperties.NAME)) {
					tooltip.addValue(NCBOToolTipProperties.NAME + ": ", concept.name);
				}
				if (!props.isNodePropertyHidden(NCBOToolTipProperties.TYPE)) {
					tooltip.addValue(NCBOToolTipProperties.TYPE + ": ", concept.type);
				}
				if (!props.isNodePropertyHidden(NCBOToolTipProperties.CHILD_COUNT)) {
					tooltip.addValue(NCBOToolTipProperties.CHILD_COUNT + ": ", concept.childCount);
				}
				if (!props.isNodePropertyHidden(NCBOToolTipProperties.PARENT_COUNT)) {
					tooltip.addValue(NCBOToolTipProperties.PARENT_COUNT + ": ", concept.parentCount);
				}
				
				// add any additional properties
				var propNames:Array = concept.propertyNames; 
				// sort the properties to keep their order consistent each time - no point anymore
				//propNames.sort(NCBOToolTipProperties.sortNodeProperties);
				for (var i:int = 0; i < propNames.length; i++) {
					var propName:String = String(propNames[i]);
					if (!props.isNodePropertyHidden(propName)) {
						var propValue:Object = concept.getProperty(propName);
						if (propValue is Array) {
							var values:String = (propValue as Array).join(", ");
							if (values.length > 80) {
								values = values.substr(0, 80) + "...";
							}
							tooltip.addValue(propName + ": ", values);
						} else {
							tooltip.addValue(propName + ": ", propValue.toString());
						}
					}
				}
				useDefault = false;
			}
			
			if (useDefault) {
				// show the default properties (e.g. id, name, type)
				super.addToolTipValues(tooltip);
			}
			
		}
		
		override protected function renderContent(x:Number, y:Number, unscaledWidth:Number, unscaledHeight:Number):void {
			if (renderPlusIcon) {
				updatePlusIcon();
			}
		}
		
		protected function updatePlusIcon():void {
			var childCount:int = 0;
			var concept:NCBOConcept = getConcept();
			if (concept) {
				childCount = concept.childCount;					
			}
			
			var childrenVisible:Boolean = true;
			if ((childCount > 0) && (childrenVisibleFunction != null)) {
				childrenVisible = childrenVisibleFunction(concept.id);
			}
			plusImage.visible = (node is GroupedNode) || ((childCount > 0) && !childrenVisible);
			
			// Bug #728 - change the plus icon to a triangle indicating how many children the node has?

//			if (hasChildren && !childLabel.visible && !childrenVisible) {
//				var color:uint = 0xffffff;
//				var borderColor:uint = 0x0;
//				var textColor:uint = 0x0;
//				if (colorProvider != null) {
//					color = colorProvider.getColorForNodeType(node.type);
//					borderColor = colorProvider.borderColor;
//					textColor = ColorUtils.getTextColor(color);
//				}
//				childLabel.setStyle("fillAlpha", 0.7);
//				childLabel.setStyle("fillColor", color);
//				childLabel.setStyle("borderColor", borderColor);
//				childLabel.setStyle("color", textColor);
//				childLabel.visible = true;
//			} else if (hasChildren && childrenVisible && childLabel.visible) {
//				childLabel.visible = false;
//			} else if (!hasChildren && childLabel.visible) {
//				childLabel.visible = false;
//			}
			
//			if ((childCount > 0) && !rightBox.visible) {
//			 	childLabel.text = childCount.toString(10);
//			 	childLabel.toolTip = childCount + (childCount == 1 ? " child" : " children");
//				//_parentLabel.text = parentCount + (parentCount == 1 ? " parent" : " parents");;
//			 	childLabel.setStyle("color", textColor);
//			 	//_parentLabel.setStyle("color", textColor);
//			 	var metrics:TextLineMetrics = childLabel.measureText(childLabel.text);
//			 	childLabel.width = metrics.width + 5;
//			 	childLabel.height = metrics.height;
//			 	trace(metrics.width + " " + metrics.height);
//			 	rightBox.height = this.height;
//			 	rightBox.visible = true;
//			} else if (childCount == 0) {
//			 	rightBox.visible = false;
//				rightBox.width = 0;
//				rightBox.height = 0;
//			}
		}
		
		override protected function positionTextControl(x:Number, y:Number, w:Number, h:Number):void {
			super.positionTextControl(x, getAdjustedY(y), w, getAdjustedHeight(h));
		}
		
		override protected function fillBackground(x:Number, y:Number, w:Number, h:Number, radius:Number, colors:Array):void {
			super.fillBackground(x, getAdjustedY(y), w, getAdjustedHeight(h), radius, colors);
		}
		
		override protected function paintBorder(x:Number, y:Number, w:Number, h:Number, radius:Number,
						borderThickness:Number = 1, borderColor:uint = 0, borderAlpha:Number = 1):void {
			super.paintBorder(x, getAdjustedY(y), w, getAdjustedHeight(h), radius, borderThickness, 
							  borderColor, borderAlpha);
		}
		
		protected function getAdjustedY(y:Number):Number {
			return y;
		}
		
		protected function getAdjustedHeight(unscaledHeight:Number):Number {
			if (renderPlusIcon) {
				var adjustedHeight:Number = unscaledHeight - HALF_HEIGHT; //childLabel.height;
				return adjustedHeight;
			}
			return unscaledHeight;
		}
		
	}
	
}