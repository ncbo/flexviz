package org.ncbo.uvic.flex.model
{
	
	/**
	 * Holds the id, name, and acronym properties for an ontology group.
	 * 
	 * @author Chris Callendar
	 * @date September 10th, 2009
	 */
	public class NCBOOntologyGroup extends NCBOItem
	{
		
		public var acronym:String;
		
		public function NCBOOntologyGroup(id:String, name:String = "", acronym:String = "") {
			super(id, name);
			this.acronym = acronym;
		}
		
		override public function toString():String {
			return nameAndAcronym;
		}
		
		public function get nameAndAcronym():String {
			var str:String = name;
			if (acronym && (acronym.length > 0)) {
				str += " (" + acronym + ")";
			}
			return str;
		}

		public function get hasAcronym():Boolean {
			return ((acronym != null) && (acronym.length > 0));
		}

	}
}