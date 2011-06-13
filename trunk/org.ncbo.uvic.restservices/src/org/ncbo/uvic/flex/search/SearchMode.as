package org.ncbo.uvic.flex.search
{
	import flex.utils.StringUtils;
	
	
	/**
	 * Defines the different search modes: contains, exact match, starts with, ends with, and sounds like.
	 * 
	 * @author Chris Callendar
	 */
	public class SearchMode
	{
		
		public static const CONTAINS:SearchMode = new SearchMode("Contains");
		public static const EXACT_MATCH:SearchMode = new SearchMode("Exact Match");
		public static const STARTS_WITH:SearchMode = new SearchMode("Starts With");
		public static const ENDS_WITH:SearchMode = new SearchMode("Ends With");
		public static const SOUNDS_LIKE:SearchMode = new SearchMode("Sounds Like");
		
		private var _name:String;
		
		public function SearchMode(smName:String) {
			this._name = smName;
		}
		
		public function toString():String {
			return name;
		}
		
		public function get name():String {
			return _name;	
		}
		
		public function set name(smName:String):void {
			this._name = smName;
		}
		
		/**
		 * Parses a search mode.  
		 * If smName is null, then null is returned.
		 * Otherwise one of: contains, exact match, starts with, ends with, or sounds like is returned.
		 * If smName doesn't match one of the above, then contains is returned.
		 */
		public static function parse(smName:String):SearchMode {
			if (smName != null) {
				if (StringUtils.equals(smName, CONTAINS.name, true)) {
					return CONTAINS;
				} else if (StringUtils.equals(smName, EXACT_MATCH.name, true)) {
					return EXACT_MATCH;
				} else if (StringUtils.equals(smName, STARTS_WITH.name, true)) {
					return STARTS_WITH;
				} else if (StringUtils.equals(smName, ENDS_WITH.name, true)) {
					return ENDS_WITH;
				} else if (StringUtils.equals(smName, SOUNDS_LIKE.name, true)) {
					return SOUNDS_LIKE;
				}
				return CONTAINS;
			} 
			return null;
		}
		
	}
}