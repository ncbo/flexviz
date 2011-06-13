package org.ncbo.uvic.flex.model
{
	import flex.utils.Map;
	
	
	/** 
	 * Base class for concepts and relationships, defines the id and a map of other properties.
	 * 
	 * @author Chris Callendar
	 * @date September 24th, 2008
	 */
	public class NCBOItem implements INCBOItem
	{
		
		private var _id:String;
		private var _name:String;
		private var properties:Map;
		
		public function NCBOItem(id:String, name:String = "") {
			this._id = id;
			this._name = (name ? name : "");
		}
		
		public function get id():String {
			return _id;
		}
		
		public function get name():String {
			return _name;
		}
		
		public function set name(value:String):void {
			_name = value;
		}
		
		public function get nameAndID():String {
			var str:String = name;
			if (id) {
				str += " [" + id + "]";
			}
			return str;
		}
		
		public function toString():String {
			return (name ? name : id);
		}
		
		public function hasProperty(propName:String):Boolean {
			return properties && properties.containsKey(propName);
		}
		
		public function setProperty(propName:String, propValue:Object):void {
			// lazy creation
			if (!properties) {
				properties = new Map();
			}
			properties.setValue(propName, propValue);
		}
		
		public function getProperty(propName:String):Object {
			if (properties) {
				return properties.getValue(propName);
			}
			return null;
		}
		
		public function getStringProperty(propName:String):String {
			return String(getProperty(propName));
		}
		
		public function getIntProperty(propName:String, defaultValue:int = 0):int {
			var prop:Object = getProperty(propName);
			return (prop != null ? int(prop) : defaultValue);
		}
		
		public function getNumberProperty(propName:String, defaultValue:Number = NaN):Number {
			var prop:Object = getProperty(propName);
			return (prop != null ? Number(prop) : defaultValue);
		}
		
		public function removeProperty(propName:String):Object {
			if (properties) {
				return properties.removeValue(propName);
			}
			return null;
		}
		
		public function get propertyNames():Array {
			return (properties ? properties.keys : []);
		}
		
		public function get propertyValues():Array {
			return (properties ? properties.values : []);
		}
		
		public function get propertyCount():int {
			return (properties ? properties.size : 0);
		}

	}
}