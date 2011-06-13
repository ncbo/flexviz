package org.ncbo.uvic.flex.model
{
	
	/**
	 * Simplified version of the NCBOOntology class which just contains the 
	 * ontology id, ontology version id, and number of hits for the ontology,
	 * and and array of the matching concepts (with paging, so not all the concepts
	 * may appear in the array).
	 * 
	 * @author Chris Callendar
	 */
	public class NCBOSearchResultOntology extends NCBOItem implements IOntology
	{
		
		private var _ontologyID:String;
		private var _hits:int;
		
		public function NCBOSearchResultOntology(versionID:String, ontologyID:String, 
											displayLabel:String = "", hits:int = 0) {
			super(versionID, displayLabel);
			_ontologyID = ontologyID;
			_hits = hits;
		}
		
		public function get ontologyID():String {
			return _ontologyID;
		}
		
		public function get ontologyVersionID():String {
			return id;
		}
		
		public function get displayLabel():String {
			return name;
		}
		
		public function set displayLabel(lbl:String):void {
			name = lbl;
		}
		
		/** Returns the number of hits for this ontology, or the number of concepts, whichever is greater. */
		public function get hits():int {
			return _hits;
		}
		
		public function set hits(hitCount:int):void {
			_hits = hitCount;
		}
		
		public function get nameAndHits():String {
			return name + " (" + hits + ")";
		}
		
		/**
		 * Converts from a generic object to a type NCBOSearchResultOntology object.
		 */
		public static function parse(obj:Object):NCBOSearchResultOntology {
			var ontology:NCBOSearchResultOntology = null;
			if (obj && obj.hasOwnProperty("ontologyVersionID") && obj.hasOwnProperty("ontologyID") &&
				obj.hasOwnProperty("displayLabel") && obj.hasOwnProperty("hits")) {
				var versionID:String = obj["ontologyVersionID"];
				var ontologyID:String = obj["ontologyID"];
				var displayLabel:String = obj["displayLabel"];
				var hits:Number = obj["hits"];
				ontology = new NCBOSearchResultOntology(versionID, ontologyID, displayLabel, (isNaN(hits) ? 0 : hits));
			}
			return ontology;
		}
		
	}
}