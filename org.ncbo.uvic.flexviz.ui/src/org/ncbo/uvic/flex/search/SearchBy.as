package org.ncbo.uvic.flex.search
{
	
	/**
	 * Holds the search by values:  search by Name or ID.
	 * 
	 * @author Chris Callendar
	 */
	public class SearchBy {
		
		public static const NAME:SearchBy = new SearchBy("Name");
		public static const ID:SearchBy = new SearchBy("ID");
		
		private var _by:String;
		
		public function SearchBy(value:String) {
			this._by = value;
		}
		
		public function toString():String {
			return value;
		}
		
		public function get value():String {
			return _by;
		}
		
		public static function parse(value:String):SearchBy {
			if (value != null) {
				value = value.toLowerCase();
				if (value === NAME.value.toLowerCase()) {
					return NAME;
				} else if (value === ID.value.toLowerCase()) {
					return ID;
				}
				return NAME;
			}
			return null;
		}

	}
}