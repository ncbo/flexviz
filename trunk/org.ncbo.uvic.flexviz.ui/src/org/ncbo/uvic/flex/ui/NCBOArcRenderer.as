package org.ncbo.uvic.flex.ui
{
	import ca.uvic.cs.chisel.flexviz.renderers.DefaultArcRenderer;
	import ca.uvic.cs.chisel.flexviz.renderers.FlexGraphToolTip;
	import ca.uvic.cs.chisel.flexviz.renderers.IColorProvider;
	
	import mx.core.IFactory;
	
	import org.ncbo.uvic.flex.NCBOToolTipProperties;
	import org.ncbo.uvic.flex.model.NCBORelationship;

	/**
	 * Overrides the default arc renderer to instead populate the tooltip from pre-selected properties.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBOArcRenderer extends DefaultArcRenderer implements IFactory
	{
		
		private var _relationshipFunction:Function;
		private var _highlightOnMouseOver:Boolean;
		
		public function NCBOArcRenderer(ncboColorProvider:IColorProvider = null, 
										getRelationshipFunction:Function = null,
										highlighOnMouseOver:Boolean = true) {
			super();
			colorProvider = ncboColorProvider;
			_relationshipFunction = getRelationshipFunction;
			_highlightOnMouseOver = highlighOnMouseOver;
		}
				
		override public function newInstance():* {
			var renderer:NCBOArcRenderer = new NCBOArcRenderer();
			copyProperties(renderer);
			return renderer;
		}
		
		override protected function copyProperties(renderer:DefaultArcRenderer):void {
			super.copyProperties(renderer);
			NCBOArcRenderer(renderer).getRelationshipFunction = getRelationshipFunction;
			NCBOArcRenderer(renderer).highlightOnMouseOver = highlightOnMouseOver;
		}

		/** This function will return an NCBOConcept given an id. */
		public function get getRelationshipFunction():Function {
			return _relationshipFunction;
		}
		
		/** Sets the function that will return an NCBOConcept given an id. */
		public function set getRelationshipFunction(func:Function):void {
			_relationshipFunction = func;
		}
		
		public function get highlightOnMouseOver():Boolean {
			return _highlightOnMouseOver;
		}
		
		public function set highlightOnMouseOver(value:Boolean):void {
			_highlightOnMouseOver = value;
		}
		
		override protected function addToolTipValues(tooltip:FlexGraphToolTip):void {
			var useDefault:Boolean = true;
			
			if (arc && (getRelationshipFunction != null)) {
				var rel:NCBORelationship = getRelationshipFunction(arc.id);
				if (rel) {
					var props:NCBOToolTipProperties = NCBOToolTipProperties.getInstance(); 
					
					// add the defined properties
					if (!props.isArcPropertyHidden(NCBOToolTipProperties.ID)) {
						tooltip.addValue(NCBOToolTipProperties.ID + ": ", rel.id);
					}
					if (!props.isArcPropertyHidden(NCBOToolTipProperties.TYPE)) {
						tooltip.addValue(NCBOToolTipProperties.TYPE + ": ", rel.type);
					}
					if (!props.isArcPropertyHidden(NCBOToolTipProperties.SOURCE) && (rel.source != null)) {
						tooltip.addValue(NCBOToolTipProperties.SOURCE + ": ", rel.source.name);
					}
					if (!props.isArcPropertyHidden(NCBOToolTipProperties.DESTINATION) && (rel.destination != null)) {
						tooltip.addValue(NCBOToolTipProperties.DESTINATION + ": ", rel.destination.name);
					}
					
					// add any additional properties - currently there are no additional relationship properties
//					var propNames:Array = concept.propertyNames; 
//					for (var i:int = 0; i < propNames.length; i++) {
//						var propName:String = String(propNames[i]);
//						if (!props.isArcPropertyHidden(propName)) {
//							var propValue:Object = rel.getProperty(propName);
//							tooltip.addValue(propName + ": ", propValue);
//						}
//					}
					useDefault = false;
				}
			}
			if (useDefault) {
				// show the default properties (e.g. id, name, type)
				super.addToolTipValues(tooltip);
			}
		}

		override protected function getLineThickness():Number {
			if (!highlightOnMouseOver) {
				var thickness:Number = 1;
				thickness = getNumberStyle("LineThickness", thickness, 0, 50);
				return thickness;
			} 
			return super.getLineThickness();
		}
		
		override protected function getFontWeight():String {
			if (!highlightOnMouseOver) {
				var fontWeight:String = "normal";
				var style:Object = getStyle(getStyleName("FontWeight"));
				if (style is String) {
					fontWeight = (style as String);
				}
				return fontWeight;
			}
			return super.getFontWeight();
		}
		
	}
}