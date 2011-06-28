package service
{
	public class RecommenderParameters
	{

		public static const REPOSITORY_UMLS:String = "umls";
		public static const REPOSITORY_NCBO:String = "ncbo";
		public static const REPOSITORY_ALL:String  = "all";
				
		public static const METHOD_CORPUS:String = "1";
		public static const METHOD_KEYWORDS:String = "3";
		
		public static const OUTPUT_SCORE:String = "score";
		public static const OUTPUT_SCORE_NORM:String = "normalized-score";
		
		public var longestOnly:Boolean = false;
		public var wholeWordOnly:Boolean = true;
		public var scored:Boolean = true;
		public var withDefaultStopWords:Boolean = false;	// true for Use Case #4
		public var localOntologyIDs:String = "";
		public var localSemanticTypeIDs:String = "";
		
		/** If false then mapping types are ignored. */
		public var activateMappings:Boolean = false;
		/**
		 * If mappings are disabled, or if no mappings are selected, then we use "null".
		 * If one or more, but not all mapping types are used, then comma separated.
		 * If all are selected, we use null value.
		 */
		public var mappingTypes:String = "null";
		public var levelMin:int = 0;
		public var levelMax:int = 0;
		public var text:String = "";
		public var format:String = OBSRestService.RESULT_FORMAT_XML;
		
		public var applicationid:String = OBSRestService.APP_ID;
		public var apikey:String = OBSRestService.DEFAULT_APIKEY;
		public var email:String = OBSRestService.EMAIL;
		
		public var repository:String = REPOSITORY_ALL;
		public var method:String = METHOD_CORPUS;
		public var output:String = OUTPUT_SCORE;

		public function RecommenderParameters(txt:String = "") {
			this.text = txt;
		}
		
	}
}