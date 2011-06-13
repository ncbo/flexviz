package org.ncbo.uvic.flex.model
{
	/**
	 * Base class for NCBO items like concepts, ontologies, categories, and groups.
	 * Can also contains generic properties too.
	 * 
	 * @author Chris Callendar
	 * @date February 15th, 2010
	 */
	public interface INCBOItem
	{
		
		/** Returns the unique id for the item */
		function get id():String;
		/** The name of the item. */
		function get name():String;		
		
		function toString():String;
		
		function hasProperty(propName:String):Boolean;
		function setProperty(propName:String, propValue:Object):void;
		function removeProperty(propName:String):Object;
		
		function getProperty(propName:String):Object;
		function getStringProperty(propName:String):String;
		function getIntProperty(propName:String, defaultValue:int = 0):int;
		function getNumberProperty(propName:String, defaultValue:Number = NaN):Number;
		
		function get propertyNames():Array;
		function get propertyValues():Array;
		function get propertyCount():int;

		
	}
}