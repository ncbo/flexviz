package org.ncbo.uvic.flex.search
{
	
	/**
	 * Represents the different searching options - what to show:<br>
	 * <ol>
	 * <li>Neighborhood: shows the matching nodes and their direct parents and children</li>
	 * <li>Children: shows the matching nodes and their children</li>
	 * <li>Parents: shows the matching nodes and their parents<li>
	 * <li>Hierarchy To Root: shows the matching nodes and their ancestors up to the root</li>
	 * </ol>
	 * 
	 * @author Chris Callendar
	 */
	public class SearchShowOption {
		
		public static const NEIGHBORHOOD:SearchShowOption = new SearchShowOption("Neighborhood");
		public static const CHILDREN:SearchShowOption = new SearchShowOption("Children");
		public static const PARENTS:SearchShowOption = new SearchShowOption("Parents");
		public static const HIERARCHY_TO_ROOT:SearchShowOption = new SearchShowOption("Hierarchy To Root");
		
		private var _name:String;
		
		public function SearchShowOption(nameStr:String) {
			this._name = nameStr;
		}
		
		public function toString():String {
			return name;
		}
		
		public function get name():String {
			return _name;
		}
		
		public static function parse(str:String):SearchShowOption {
			if (str != null) {
				str = str.toLowerCase();
				if (str === NEIGHBORHOOD.name.toLowerCase()) {
					return NEIGHBORHOOD;
				} else if (str === CHILDREN.name.toLowerCase()) {
					return CHILDREN;
				} else if (str === PARENTS.name.toLowerCase()) {
					return PARENTS;
				} else if ((str == HIERARCHY_TO_ROOT.name.toLowerCase()) || (str == "hierarchy")) {
					return HIERARCHY_TO_ROOT;
				}
				return NEIGHBORHOOD;
			}
			return null;
		}

	}
}