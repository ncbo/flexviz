package service
{
	import flex.utils.ArrayUtils;
	
	
	/**
	 * Resource Index parameters.
	 * See:
	 * http://www.bioontology.org/wiki/index.php/Resource_Index_REST_Web_Service_User_Guide
	 * 
	 * @author Chris Callendar
	 * @date March 11th, 2009
	 */
	public class ResourceIndexParameters
	{
		
		public static const MODE_UNION:String = "union";
		public static const MODE_INTERSECTION:String = "intersection";
		
		public var email:String = OBSRestService.EMAIL;
		public var applicationid:String = OBSRestService.APP_ID;
		public var apikey:String = OBSRestService.DEFAULT_APIKEY;

		public var ontologiesToKeepInResult:String = "";
		public var semanticTypes:String = "";
		public var levelMax:int = 0;
		/**
		 * If mappings are disabled, or if no mappings are selected, then we use "null".
		 * If one or more, but not all mapping types are used, then comma separated.
		 * If all are selected, we use null value.
		 */
		public var mappingTypes:String = "null";
		public var filterNumber:Boolean = true;
		//public var minTermSize:int = 0;
		public var withSynonyms:Boolean = true;

		public var additionalStopWords:String = "";
		public var isStopWordsCaseSenstive:Boolean = false;
		
		// commas separated list of concept ids WITH ontology ids (not ontology version ids)!
		// e.g. "13578/Melanoma,4525/Melanoma"
		public var conceptids:String = "";
		public var isVirtualOntologyId:Boolean = false;
		public var mode:String = MODE_UNION;
		public var elementid:String;
		public var resourceids:String;
		
		public var elementDetails:Boolean = false;
		public var withContext:Boolean = true;
		public var counts:Boolean = false;
		public var offset:Number = 0;
		public var limit:Number = 10; 
		public var format:String = OBSRestService.RESULT_FORMAT_XML;
		
		
		// not sent to server
		private var activateMappings:Boolean;
		
		public function ResourceIndexParameters() {
		}
		
		//////////////////////////////////////////////////////////////////////
		// All the following functions are purposefully not getters/settters
		//////////////////////////////////////////////////////////////////////
		
		public function isActivateMappings():Boolean {
			return activateMappings;
		}
		
		public function setActivateMappings(value:Boolean):void {
			activateMappings = value;
		}
		
		public function isValid():Boolean {
			return conceptids.length > 0;
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