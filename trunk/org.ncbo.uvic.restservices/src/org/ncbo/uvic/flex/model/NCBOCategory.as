package org.ncbo.uvic.flex.model
{
	
	/**
	 * Simple class for storing ontology categories - holds the id and name of the category.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBOCategory extends NCBOItem
	{
		
		private var _id:String;
		private var _name:String;
		
		public function NCBOCategory(catID:String, catName:String) {
			super(catID, catName);
		}

	}
}