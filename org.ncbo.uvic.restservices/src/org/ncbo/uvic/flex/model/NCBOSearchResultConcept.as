package org.ncbo.uvic.flex.model
{
	
	/**
	 * Simplified version of NCBOConcept which only contains the concept ID,
	 * preferred name, and the contents that matched the query.
	 * It also references the NCBOSearchResultOntology that it belongs to.
	 * And also contains the search text.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBOSearchResultConcept extends NCBOItem implements IConcept
	{
		
		public static const RECORD_TYPE_PREF_NAME:String = "RECORD_TYPE_PREFERRED_NAME";
		public static const RECORD_TYPE_SYNONYM:String = "RECORD_TYPE_SYNONYM";
		public static const RECORD_TYPE_CONCEPT_ID:String = "RECORD_TYPE_CONCEPT_ID";
		
		private var _recordType:String;
		private var _foundIn:String;
		private var _contents:String;
		private var _ontology:NCBOSearchResultOntology;
		
		public var searchText:String;
		
		public function NCBOSearchResultConcept(id:String, name:String, recordType:String = "", 
						contents:String = null, ontology:NCBOSearchResultOntology = null, 
						searchText:String = null) {
			super(id, name);
			this.recordType = recordType;
			this._contents = ((contents != name) ? contents : null);
			this._ontology = ontology;
			this.searchText = searchText;
		}
		
		public function get recordType():String {
			return _recordType;
		}
		
		public function set recordType(type:String):void {
			_recordType = type;
			switch (type) {
				case RECORD_TYPE_PREF_NAME :
					_foundIn = "Preferred Name";
					break;
				case RECORD_TYPE_SYNONYM :
					_foundIn = "Synonym"; 
					break;
				case RECORD_TYPE_CONCEPT_ID :
					_foundIn = "Concept ID";
					break;
				default :
					_foundIn = "";
					break;
			}
		}
		
		public function get contents():String {
			return (_contents != null ? _contents : name);
		}
		
		public function get ontology():NCBOSearchResultOntology {
			return _ontology;
		}

		public function get ontologyName():String {
			return (_ontology ? _ontology.displayLabel : "");
		}
		
		public function get ontologyVersionID():String {
			return (_ontology ? _ontology.ontologyVersionID : "");
		}
		
		public function get ontologyID():String {
			return (_ontology ? _ontology.ontologyID : "");
		}
		
		public function get ontologyNameAndID():String {
			var id:String = ontologyVersionID;
			if (id.length > 0) {
				return ontologyName + " [" + id + "]";
			} 
			return ontologyName;
		}
		
		public function get foundIn():String {
			return _foundIn;
		}
		
		/**
		 * Converts a generic object into a type NCBOSearchResultConcept object.
		 */
		public static function parse(obj:Object, ontology:NCBOSearchResultOntology = null):NCBOSearchResultConcept {
			var concept:NCBOSearchResultConcept = null;
			if (obj && obj.hasOwnProperty("id") && obj.hasOwnProperty("name")) {
				var id:String = obj["id"];
				var name:String = obj["name"];
				var record:String = obj["recordType"];
				var contents:String = obj["contents"];
				var searchText:String = obj["searchText"];
				concept = new NCBOSearchResultConcept(id, name, record, contents, ontology, searchText);
			}
			return concept;
		}
		
	}
}