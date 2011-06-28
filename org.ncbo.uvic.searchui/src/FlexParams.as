package
{
	import flex.utils.Utils;
	
	import org.ncbo.uvic.flex.NCBOAppParams;
	
	
	/**
	 * Holds the Flex application parameters for the Search UI.
	 * 
	 * @author Chris Callendar
	 * @date March 12th, 2009
	 */
	public class FlexParams extends NCBOAppParams
	{
		
		/**
		 * Defines whether the NCBO banner is showing (true/false).
		 * Defaults to false.
		 */
		public static const BANNER:String 	= "banner";
		
		public static const SHOW_RECENT_SEARCHES:String = "showrecentsearches";
		public static const SHOW_POPULAR_SEARCHES:String = "showpopularsearches";
		public static const DOI:String = "doi";

		private var _banner:Boolean;
		private var _debug:Boolean;
		private var _server:String;
		private var _redirectURL:String;
		private var _search:String;
		private var _ontology:String;
		private var _log:Boolean;
		private var _recent:Boolean;
		private var _popular:Boolean;
		private var _doi:Boolean;
		private var _apikey:String;

		public function FlexParams() {
			load();
		}
		
		private function load():void {
			_debug = Utils.getBooleanParam(DEBUG, DEFAULT_DEBUG, null, true);
			_banner = Utils.getBooleanParam(BANNER, false, null, true);
			_log = Utils.getBooleanParam(LOG, DEFAULT_LOG, null, true) || Utils.getBooleanParam(LOGGING, DEFAULT_LOG, null, true);

			_server = Utils.getParam(SERVER, null, null, true);
			_redirectURL = Utils.getParam(REDIRECT_URL, null, null, true);
			
			_ontology = Utils.getParam(ONTOLOGY, DEFAULT_ONTOLOGY, null, true);
			_search = Utils.getParam(SEARCH, DEFAULT_SEARCH, null, true);
			
			// only show these two options if logging is turned on
			var show:Boolean = _log;
			_recent = Utils.getBooleanParam(SHOW_RECENT_SEARCHES, show, null, true);
			_popular = Utils.getBooleanParam(SHOW_POPULAR_SEARCHES, show, null, true);
			
			_doi = Utils.getBooleanParam(DOI, false, null, true);
			
			_apikey = Utils.getParam(APIKEY, null);

			// hack - check for a special string
			if (_search == "Enter term, e.g. Melanoma") {
				_search = "";
			}	
		}
		
		public function get apikey():String {
			return _apikey;
		}
		
		public function get banner():Boolean {
			return _banner;
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
	
		public function get log():Boolean {
			return _log;
		}
		
		public function get showPopularSearches():Boolean {
			return _popular;
		}
		
		public function get showRecentSearches():Boolean {
			return _recent;
		}
		
		public function get doi():Boolean {
			return _doi;
		}
		
	}
}