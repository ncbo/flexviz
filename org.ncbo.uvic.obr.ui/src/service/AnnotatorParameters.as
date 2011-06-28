package service
{
	import flex.utils.ArrayUtils;
	
	/**
	 * Parameters for the Annotator.
	 * See:
	 * http://www.bioontology.org/wiki/index.php/Annotator_User_Guide
	 */
	public class AnnotatorParameters
	{
		
		public var longestOnly:Boolean = false;
		public var wholeWordOnly:Boolean = true;
		public var filterNumber:Boolean = true;				// filter numbers?
		public var stopWords:String = ""; 
		public var withDefaultStopWords:Boolean = false;	// true for Annotator
		public var isStopWordsCaseSenstive:Boolean = false;
		//public var minTermSize:int = 0;
		public var scored:Boolean = true;
		public var withSynonyms:Boolean = true;
		public var ontologiesToExpand:String = "";
		public var ontologiesToKeepInResult:String = "";
		public var isVirtualOntologyId:Boolean = false;
		public var semanticTypes:String = "";
		public var levelMax:int = 0;
		
		/**
		 * If mappings are disabled, or if no mappings are selected, then we use "null".
		 * If one or more, but not all mapping types are used, then comma separated.
		 * If all are selected, we use null value.
		 */
		public var mappingTypes:String = "null";
		
		public var textToAnnotate:String = "";
		
		public var format:String = OBSRestService.RESULT_FORMAT_XML;
		
		public var applicationid:String = OBSRestService.APP_ID;
		public var apikey:String = OBSRestService.DEFAULT_APIKEY;
		public var email:String = OBSRestService.EMAIL;
		
		public function AnnotatorParameters(txt:String = "") {
			this.textToAnnotate = txt;
		}
		
		//////////////////////////////////////////////////////////////////////
		// All the following functions are purposefully not getters/settters
		//////////////////////////////////////////////////////////////////////
		
		public function isValid():Boolean {
			return (textToAnnotate.length > 0);
		}
		
		/** 
		 * Use this function to set the array of Ontology objects.
		 * They will be converted into a CSV of ontology ids.
		 */
		public function setOntologies(ontologies:Array):void {
			ontologiesToKeepInResult = ArrayUtils.arrayToString(ontologies, ",", -1, "id");
		}
		
		public function getOntologyIDs():Array { 
			return ontologiesToKeepInResult.split(",");
		}

		/**
		 * Use this function to set the semantic type ids from an array of SemanticType objects.
		 */
		public function setSemanticTypes(types:Array):void {
			semanticTypes = ArrayUtils.arrayToString(types, ",", -1, "id");
		}
		
		public function getSemanticTypeIDs():Array {
			return semanticTypes.split(",");
		}

		/**
		 * Converts the mapping types into a CSV String.
		 * Special cases: if types is null, then the mappingTypes variable is set to null.
		 * If types is an empty array, then mappingTypes is set to "null".
		 * Otherwise the types array is joined using commas.
		 */
		public function setMappingTypes(types:Array):void {
			if (types == null) {
				mappingTypes = null;
			} else if (types.length > 0) {
				mappingTypes = types.join(",");
			} else {
				mappingTypes = "null";
			}
		}
		
		public function getMappingTypes():Array {
			// all selected
			if (mappingTypes == null) {
				return null;
			}
			// none selected
			if (mappingTypes == "null") {
				return [];
			}
			return mappingTypes.split(",");
		}
		
	}
}