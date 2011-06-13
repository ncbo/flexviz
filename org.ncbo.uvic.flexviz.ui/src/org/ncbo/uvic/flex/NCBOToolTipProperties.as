package org.ncbo.uvic.flex
{
	import flex.utils.Map;
	
	
	/**
	 * This class contains common concept and relationship property constants such as 
	 * "ID", "Type", "Name", "Children", "Parents", "Source Node", and "Dest. Node".
	 *  
	 * It also contains a collection of all the node and arc properties that should 
	 * NOT show up in tooltips (e.g. arc id).
	 * 
	 * @author Chris Callendar
	 */
	public class NCBOToolTipProperties
	{
		
		// Nodes & Arcs
		public static const ID:String			= "ID";
		public static const TYPE:String			= "Type";
		
		// Nodes
		public static const NAME:String			= "Name";
		public static const CHILD_COUNT:String 	= "Children";
		public static const PARENT_COUNT:String	= "Parents";
		
		// Arcs
		public static const SOURCE:String		= "Source"; 
		public static const DESTINATION:String	= "Destination"; 
		
		// singleton
		private static var PROPS:NCBOToolTipProperties = null;
		
		
		// stores only the hidden node properties
		private var _hiddenNodeProps:Map;
		// stores only the hidden arc properties
		private var _hiddenArcProps:Map;
		
		public function NCBOToolTipProperties() {
			_hiddenNodeProps = new Map();
			_hiddenArcProps = new Map();
			
			setDefaultHiddenNodeProperties();
			setDefaultHiddenArcProperties();
		}
		
		public static function getInstance():NCBOToolTipProperties {
			if (PROPS == null) {
				PROPS = new NCBOToolTipProperties();
			}
			return PROPS;
		}
		
		///////////
		// NODES
		//////////
		
		/** Sets the default hidden node tooltip properties. */
		private function setDefaultHiddenNodeProperties():void {
			// add default hidden tooltip properties
			var defaultProps:Array = defaultHiddenNodeProperties;
			for (var i:int = 0; i < defaultProps.length; i++) {
				var prop:String = String(defaultProps[i]);
				_hiddenNodeProps[prop] = true;
			}
		}
		
		/**
		 * Returns whether the node tooltip property is hidden.
		 * Note that all properties are shown by default except
		 * this defined by defaultHiddenNodeProperties.
		 */
		public function isNodePropertyHidden(property:String):Boolean {
			return (_hiddenNodeProps.containsKey(property) ? true : false);
		}
		
		/**
		 * Sets whether the node property should not be shown in the tooltip.
		 * @param property the property name like "id", "type", etc
		 * @param hidden if true the property will not show up in the node tooltips
		 */
		public function setNodePropertyHidden(property:String, hidden:Boolean = true):void {
			if (hidden) {
				_hiddenNodeProps.setValue(property, true);
			} else {
				_hiddenNodeProps.removeValue(property);
			}
		}
				
		/** 
		 * Returns the default tooltip property names that are hidden for nodes: id and type. 
		 */
		public function get defaultHiddenNodeProperties():Array {
			var props:Array = new Array();
			props.push(ID);
			props.push(TYPE);
			// this property isn't set properly yet
			props.push(PARENT_COUNT);
			return props;
		}

		/** Returns the node tooltip properties that are hidden. */
		public function get hiddenNodeProperties():Array {
			return _hiddenNodeProps.keys;
		}

//		public static function sortNodeProperties(prop1:String, prop2:String):int {
//			if (prop1 == NAME) return -1; 
//			if (prop2 == NAME) return 1;
//			if (prop1 == ID) return -1;
//			if (prop2 == ID) return 1;
//			if (prop1 == TYPE) return -1;
//			if (prop2 == TYPE) return 1;
//			if (prop1 == CHILD_COUNT) return -1;
//			if (prop2 == CHILD_COUNT) return 1;
//			if (prop1 == PARENT_COUNT) return -1;
//			if (prop2 == PARENT_COUNT) return 1;
//			
//			return prop1.localeCompare(prop2);			
//		}


		//////////
		// ARCS
		//////////

		/** Sets the default hidden arc properties. */
		private function setDefaultHiddenArcProperties():void {
			// add default properties
			var defaultProps:Array = defaultHiddenArcProperties;
			for (var i:int = 0; i < defaultProps.length; i++) {
				var prop:String = String(defaultProps[i]);
				_hiddenArcProps[prop] = true;
			}
		}
		
		/**
		 * Checks if the given arc tooltip property is hidden. */
		public function isArcPropertyHidden(property:String):Boolean {
			return (_hiddenArcProps.containsKey(property) ? true : false);
		}
		
		/**
		 * Sets whether the given tooltip property should be hidden.
		 * By default any property that isn't specifically hidden
		 * will be visible.
		 * @param property the tooltip property like "type", "id", etc
		 * @param hidden if true the property won't show up in arc tooltips
		 */
		public function setArcPropertyHidden(property:String, hidden:Boolean = true):void {
			// only save the value if we are hiding the property
			if (hidden) {
				_hiddenArcProps.setValue(property, true);
			} else {
				_hiddenArcProps.removeValue(property);
			}
		}
		
		/**
		 * Returns all the defined arc tooltip properties.
		 * E.g. ID, type, source, and destination
		 */
		public function get allArcProperties():Array {
			var props:Array = new Array();
			props.push(ID);
			props.push(TYPE);
			props.push(SOURCE);
			props.push(DESTINATION);
			return props;
		}
		
		/** Returns the default tooltip properties that are hidden for arcs: id */
		public function get defaultHiddenArcProperties():Array {
			var props:Array = new Array();
			props.push(ID);
			return props;
		}

		/** Returns the arc tooltip properties that are hidden. */
		public function get hiddenArcProperties():Array {
			return _hiddenArcProps.keys;
		}
				
	}
	
}