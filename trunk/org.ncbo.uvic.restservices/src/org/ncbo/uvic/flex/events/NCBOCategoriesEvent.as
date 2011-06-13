package org.ncbo.uvic.flex.events
{

	/**
 	 * Contains the sorted array of NCBOCategory objects.
 	 * 
 	 * @author Chris Callendar
 	 * @date January 5th, 2009
 	 */
	public class NCBOCategoriesEvent extends NCBOEvent
	{
		
		public function NCBOCategoriesEvent(categories:Array = null, error:Error = null) {
			super(categories, "NCBOCategoriesEvent", error);
		}

		public function get categories():Array {
			return collection;
		}
		
	}
}