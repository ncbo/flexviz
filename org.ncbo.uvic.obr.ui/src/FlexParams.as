package
{
	import flex.utils.Utils;
	
	import mx.utils.StringUtil;
	
	import org.ncbo.uvic.flex.NCBOAppParams;

	/**
	 * Holds the Flex application parameters for the OBR UI.
	 * 
	 * @author Chris Callendar
	 * @date March 16th, 2009
	 */	
	public class FlexParams extends NCBOAppParams
	{
		
		/**
		 * Defines an optional concept id, or a comma-separated list of concept ids.
		 * These concepts are used to run an initial search.
		 */ 
		public static const CONCEPT:String	= "concept";
		
		public static const SEMANTIC_TYPES:String = "semanticTypes";

		private var _debug:Boolean;
		private var _banner:Boolean;
		private var _server:String;
		private var _redirectURL:String;
		private var _ontology:String;
		private var _virtual:Boolean;
		private var _concept:String;
		private var _search:String;
		private var _semanticTypes:String;
		private var _apikey:String;
		
		public function FlexParams() {
			var params:Object = Utils.getCombinedParameters(true);
			
			_debug = Utils.getBooleanParam(DEBUG, false, params);
			_server = Utils.getParam(SERVER, null, params);
			_redirectURL = Utils.getParam(REDIRECT_URL, null, params);
			_ontology = StringUtil.trim(Utils.getParam(ONTOLOGY, DEFAULT_ONTOLOGY, params));
			_virtual = Utils.getBooleanParam(ONTOLOGY_VIRTUAL, false, params);
			_concept = Utils.getParam(CONCEPT, "", params);
			_search = Utils.getParam(SEARCH, DEFAULT_SEARCH, params);
			_semanticTypes = Utils.getParam(SEMANTIC_TYPES, "", params);
			_apikey = Utils.getParam(APIKEY, null, params);
		}
		
		public function get apikey():String {
			return _apikey;
		}

		public function get debug():Boolean {
			return _debug;
		}
		
		public function get server():String {
			return _server;
		}
		
		public function get redirectURL():String {
			return _redirectURL;
		}

		public function get search():String {
			return _search;
		}
		
		public function get ontology():String {
			return _ontology;
		}
		
		public function get isVirtual():Boolean {
			return _virtual;
		}
		
		public function get concept():String {
			return _concept;
		}
		
		public function get semanticTypes():String {
			return _semanticTypes;
		}

	}
}