package org.ncbo.uvic.flex
{
	
	import flash.events.EventDispatcher;
	import flash.utils.getTimer;
	
	import flex.utils.DateUtils;
	import flex.utils.Map;
	import flex.utils.StringUtils;
	import flex.utils.Utils;
	
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	import mx.messaging.messages.HTTPRequestMessage;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.utils.StringUtil;
	
	import org.ncbo.uvic.flex.events.NCBOCategoriesEvent;
	import org.ncbo.uvic.flex.events.NCBOConceptEvent;
	import org.ncbo.uvic.flex.events.NCBOConceptLoadedEvent;
	import org.ncbo.uvic.flex.events.NCBOConceptsEvent;
	import org.ncbo.uvic.flex.events.NCBOEvent;
	import org.ncbo.uvic.flex.events.NCBOGroupsEvent;
	import org.ncbo.uvic.flex.events.NCBOOntologiesEvent;
	import org.ncbo.uvic.flex.events.NCBOOntologyEvent;
	import org.ncbo.uvic.flex.events.NCBOOntologyMetricsEvent;
	import org.ncbo.uvic.flex.events.NCBOPathToRootEvent;
	import org.ncbo.uvic.flex.events.NCBOSearchEvent;
	import org.ncbo.uvic.flex.logging.LogService;
	import org.ncbo.uvic.flex.model.IConcept;
	import org.ncbo.uvic.flex.model.IOntology;
	import org.ncbo.uvic.flex.model.NCBOCategory;
	import org.ncbo.uvic.flex.model.NCBOConcept;
	import org.ncbo.uvic.flex.model.NCBOOntology;
	import org.ncbo.uvic.flex.model.NCBOOntologyGroup;
	import org.ncbo.uvic.flex.model.NCBOOntologyMetrics;
	import org.ncbo.uvic.flex.model.NCBORelationship;
	import org.ncbo.uvic.flex.model.NCBOSearchResultConcept;
	import org.ncbo.uvic.flex.model.NCBOSearchResultOntology;
	import org.ncbo.uvic.flex.search.SearchMode;
	import org.ncbo.uvic.flex.search.SearchParams;
	
	[Event(name="conceptLoadedEvent", type="org.ncbo.uvic.flex.events.NCBOConceptLoadedEvent")]
	
	/**
	 * Main class for working with the NCBO Rest services.
	 * Handles caching of ontologies and their concepts.
	 * It also caches calls to the rest service to prevent identical calls from happening, instead
	 * the callbacks functions are saved and will get called when the response comes back.
	 * It can also retry a rest service call if it fails.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBORestService extends EventDispatcher implements IRestService
	{
		
		public static const DEFAULT_BASE_URL:String = "http://rest.bioontology.org/bioportal/";
		public static const STAGE_BASE_URL:String 	= "http://stagerest.bioontology.org/bioportal/";
		
		// PHP Proxy which forwards the contents from the given url parameter
		// used to get the nice error message XML which Flex doesn't provide 
		//private static const PROXY_URL:String = "http://keg.cs.uvic.ca/proxy.php?url=";
		
		// alternates, they all re-direct to port 8080
		//private static const DEFAULT_BASE_URL:String = "http://ncbo-core-prod1.stanford.edu/bioportal/";
		//private static const DEFAULT_BASE_URL:String = "http://ncbo-core-dev1.stanford.edu/bioportal/";
		//private static const DEFAULT_BASE_URL:String = "http://ncbo-core-dev2.stanford.edu/bioportal/";
		//private static const DEFAULT_BASE_URL:String = "http://ncbo-core-load1.stanford.edu/bioportal/";
		//private static const DEFAULT_BASE_URL:String = "http://ncbo-core-stage1.stanford.edu/bioportal/";
		
		private static const SUFFIX_ONTOLOGIES:String = "ontologies/";
		private static const SUFFIX_ONTOLOGY_VIRTUAL:String = "virtual/ontology/"
		private static const SUFFIX_ONTOLOGY_VERSIONS:String = "ontologies/versions/";
		private static const SUFFIX_ONTOLOGY_METRICS:String = "ontologies/metrics/";
		private static const SUFFIX_CONCEPTS:String = "concepts/";
		private static const SUFFIX_PATHS_TO_ROOT:String = "path/";
		private static const SUFFIX_SEARCH:String = "search/";
		private static const SUFFIX_CATEGORIES:String = "categories/";
		private static const SUFFIX_GROUPS:String = "groups/";
		
		/** 
		 * The REST server url for retrieving all the ontologies.
		 * If the url has an ontology id on the end then only the details of that
		 * one ontology is shown.
		 * List all ontologies: 
		 * http://rest.bioontology.org/bioportal/ontologies/
		 * List the details for one ontology (40656 is the version id)
		 * http://rest.bioontology.org/bioportal/ontologies/40656
		 */
		private var ONTOLOGIES_URL:String;
		
		/** 
		 * The REST server url for getting an ontology from a virtual id (or ontology id).
		 * E.g. http://rest.bioontology.org/bioportal/virtual/ontology/1104
		 */		
		private var ONTOLOGY_VIRTUAL_URL:String;
		
		/** 
		 * The REST server url for getting all versions of an ontology from a virtual id (or ontology id).
		 * E.g. http://rest.bioontology.org/bioportal/ontologies/versions/1104
		 */		
		private var ONTOLOGY_VERSIONS_URL:String;
		
		/**
		 * The REST server url for getting the metrics for a given ontology version id.
		 * http://rest.bioontology.org/bioportal/ontologies/metrics/40962
		 */
		private var ONTOLOGY_METRICS_URL:String;

		/** 
		 * The REST server url for retreiving infomation about a single concept.
		 * For the roots of an ontology: 
		 * http://rest.bioontology.org/bioportal/concepts/3905/root
		 * For the details about a concept: 
		 * http://rest.bioontology.org/bioportal/concepts/3906/ProteinOntology
		 */
		private var CONCEPTS_URL:String;
		
		/**
		 * The REST server url for retrieving the paths to root for a concept by ontology version id.
		 * E.g.
		 * http://rest.bioontology.org/bioportal/concepts/path/42331/?source=Melanoma&target=root
		 */
		private var PATHS_TO_ROOT_URL:String;
		
		
		/**
		 * The search url - takes a concept name and a csv of ontology ids like
		 * http://rest.bioontology.org/bioportal/search/searchterm?ontologyids=3905,13312
		 * Returns one list of matching concepts for each ontology.
		 */
		private var SEARCH_URL:String; 
		
		/**
		 * The rest url for getting all the categories.
		 * http://rest.bioontology.org/bioportal/categories
		 */
		private var CATEGORIES_URL:String;

		/** 
		 * The rest url for getting all the ontology groups.
		 * http://rest.bioontology.org/bioportal/groups
		 */
		private var GROUPS_URL:String;
		
		
		public static const ERROR_STATUS_BEAN:String = "org.ncbo.stanford.bean.response.ErrorStatusBean";
		public static const ERROR_STATUS:String = "errorStatus";
		public static const SUCCESS:String = "success";
		public static const CHILD_COUNT:String 	= "ChildCount";
		public static const PARENT_COUNT:String = "ParentCount";
		public static const SUPER_CLASS:String 	= "SuperClass";
		public static const SUB_CLASS:String 	= "SubClass";
		public static const RDF_TYPE:String 	= "rdf:type";		// Owl only

		private static const ERROR_XML:XML 		= <error/>;
		
		public static const APP_ID_KEY:String 		= "applicationid";
		public static const APP_ID_FLEXVIZ:String 	= "7jf77k32-3386-8122-293f-uk5rmnb322nn"; 
		public static const APP_ID_SEARCH:String 	= "3kl54a87-2275-6435-211d-fe3bkib899df";
		public static const APP_ID_OBS:String 		= "5dd32t44-7923-1768-877a-fm8pdeb208ug";

		public static const APIKEY_FLEXVIZ:String 	= "46829a05-8c1c-422b-950d-186763ae0f7c"; 
		public static const APIKEY_SEARCH:String 	= "9bd76c58-220d-4c7f-8ad0-0a5671164199";
		public static const APIKEY_OBS:String 		= "2be5eb55-86eb-41d6-8b81-e28e525acc0c";
		
		public static const APIKEY:String 		= "apikey";
		public static const UESRAPIKEY:String	= "userapikey";
		
		// The default application ID - this should be set by each application (FlexViz, Search, ...)
		private var appID:String = "";	
		public var apikey:String = "";	
		// used for website tracking
		public var email:String = "default@uvic.ca";
		
		// controls whether logging is performed, both for BioPortal and for our logging
		private var _log:Boolean = true;
		
		// the ontology cache, maps ontology version id to NCBOOntology objects
		private var _ontologies:Object;
		private var _ontologiesList:Array;
		
		// the categories cache, maps category id to NCBOCategory object
		private var _categories:Object;
		private var _categoriesList:Array;
		
		// maps the group id to NCBOOntologyGroup object
		private var _groups:Object;
		private var _groupsList:Array;
		
		private var _baseURL:String;
		private var _errorFunction:Function;
		
		// debugging purposes
		private var _restCalls:Array;
		
		private var showingError:Boolean;
		
		// prevent multiple calls happening at the same time
		// maps ontology ID and concept ID to an array of callback functions
		private var callbacksMap:Object; 
		
		private var timeout:int;	// in seconds
		
		/** 
		 * If you want to override the default Alert error box, then set this property
		 * to your own function like this: function(msg:String, title:String, closeCallback:Function);
		 */
		public var alertErrorFunction:Function = null;
		
		public function NCBORestService(apikey:String, applicationID:String = null, baseServerURL:String = null, 
				errorFunction:Function = null, email:String = "default@uvic.ca", timeout:int = 20) {
			if (apikey != null) {
				this.apikey = apikey;		
			}
			if (applicationID != null) {
				this.appID = applicationID;
			}
			this.baseURL = baseServerURL;
			this._errorFunction = errorFunction;
			this.email = email;
			this.timeout = timeout;
			_ontologiesList = null;
			_ontologies = new Object();
			_categoriesList = null;
			_categories = new Object();
			_groups = new Object();
			_groupsList = null;
			_restCalls = new Array();
			showingError = false;
			callbacksMap = new Object();
			
			LogService.restService = this;
		}
			
		/**
		 * Initializes the REST urls for getting ontologies, concepts, and searching.
		 * @param baseURL the base url, can be null in which case the default server is used.
		 */
		public function set baseURL(url:String):void {
			if (url) {
				_baseURL = url;
				if (!StringUtils.endsWith(_baseURL, "/")) {
					_baseURL = _baseURL + "/";
				}
				if (!StringUtils.startsWith(_baseURL, "http://", true)) {
					_baseURL = "http://" + _baseURL;
				}
				if (!StringUtils.endsWith(_baseURL, "bioportal/")) {
					_baseURL = _baseURL + "bioportal/";
				}
			} else {
				_baseURL = DEFAULT_BASE_URL;
			}
						
			ONTOLOGIES_URL = _baseURL + SUFFIX_ONTOLOGIES;
			ONTOLOGY_VIRTUAL_URL = _baseURL + SUFFIX_ONTOLOGY_VIRTUAL;
			ONTOLOGY_VERSIONS_URL = _baseURL + SUFFIX_ONTOLOGY_VERSIONS;
			ONTOLOGY_METRICS_URL = _baseURL + SUFFIX_ONTOLOGY_METRICS;
			CONCEPTS_URL = _baseURL + SUFFIX_CONCEPTS;
			PATHS_TO_ROOT_URL = _baseURL + SUFFIX_PATHS_TO_ROOT;
			SEARCH_URL = _baseURL + SUFFIX_SEARCH;
			CATEGORIES_URL = baseURL + SUFFIX_CATEGORIES;
			GROUPS_URL = baseURL + SUFFIX_GROUPS;
		}
		
		public function get baseURL():String {
			return _baseURL;
		}
		
		/** Returns the REST ontologies url. */
		public function get ontologiesURL():String {
			return ONTOLOGIES_URL;
		}
		
		/** Returns the REST ontology virtual url. */
		public function get ontologyVirtualURL():String {
			return ONTOLOGIES_URL;
		}
		
		public function get ontologyVersionsURL():String {
			return ONTOLOGY_VERSIONS_URL;
		}
		
		public function get ontologyMetricsURL():String {
			return ONTOLOGY_METRICS_URL;
		}
		
		/** Returns the REST concepts url. */
		public function get conceptsURL():String {
			return CONCEPTS_URL;
		}
		
		/** Returns the REST search url. */
		public function get searchURL():String {
			return SEARCH_URL;
		}
		
		/** Returns the REST categories URL. */
		public function get categoriesURL():String {
			return CATEGORIES_URL;
		}
		
		public function get groupsURL():String {
			return GROUPS_URL;
		}
		
		public function get restCalls():Array {
			return _restCalls;
		}
	
		public function dispose():void {
			_ontologies = new Object();
			_ontologiesList = null;
			_categories = new Object();
			_categoriesList = null;
			_groups = new Object();
			_groupsList = null;
			callbacksMap = new Object();
		}
		
		public function get hasLoadedOntologies():Boolean {
			return (_ontologiesList != null);
		}
		
		public function hasLoadedCategories():Boolean {
			return (_categoriesList != null);
		}
		
		public function hasLoadedGroups():Boolean {
			return (_groupsList != null);
		}
		
		public function get log():Boolean {
			return _log;
		}
		
		public function set log(value:Boolean):void {
			_log = value;
		}
		
		// public for testing purposes only
		public function getService(url:String, resultHandler:Function = null, faultHandler:Function = null):HTTPService {
			var service:HTTPService = new HTTPService();
			service.method = HTTPRequestMessage.GET_METHOD;
			service.resultFormat = HTTPService.RESULT_FORMAT_E4X;	// formatted XML
			if (resultHandler != null) {
				var wrapper:Function = function(event:ResultEvent):void {
					service.removeEventListener(ResultEvent.RESULT, wrapper);
					resultHandler(event);
					// disconnect here, we're done with this service
					service.disconnect();
					service = null;
				};
				service.addEventListener(ResultEvent.RESULT, wrapper);
			}
			if (faultHandler != null) {
				service.addEventListener(FaultEvent.FAULT, faultHandler);
			}
			service.url = url;
			// no caching
			service.headers["Pragma"] = "no-cache";
			service.headers["Cache-Control"] = "no-cache";
			service.requestTimeout = timeout;	// in seconds
			// for website stat tracking purposes - passed into the url now
			//service.headers[APP_ID_KEY] = appID;
			return service;	
		}
		
		private function sendLogOnly(url:String):void {
			if (log) {
				url = StringUtils.addURLParameter(url, "logonly", "true");
				url = StringUtils.addURLParameter(url, APP_ID_KEY, appID);
				url = StringUtils.addURLParameter(url, APIKEY, apikey);
				url = StringUtils.addURLParameter(url, "email", email);
				//trace("[REST_log] " + url);
				var service:HTTPService = getService(url);
				service.send();
			}
		}
		
		/** Wraps the parameters in a NCBORestParams object and calls sendWithParams(). */
		private function send(url:String, xmlHandler:Function, callback:Function, 
				allowMultipleCalls:Boolean = false, alertErrors:Boolean = true, logEvent:Boolean = true):void {
			url = StringUtils.addURLParameter(url, APP_ID_KEY, appID);
			url = StringUtils.addURLParameter(url, APIKEY, apikey);
			url = StringUtils.addURLParameter(url, "email", email);
			var params:NCBORestParams = new NCBORestParams(url, xmlHandler, callback, 
												allowMultipleCalls, alertErrors, logEvent);
			sendWithParams(params, false, false);
		}
		
		private function sendWithParams(params:NCBORestParams, resending:Boolean = false, useProxy:Boolean = false):void {
			try {
				var startTime:int = getTimer();

				var resultHandler:Function = function(event:ResultEvent):void {
					var startParse:int = getTimer();
					var xml:XML = XML(event.result);
					// check for error here and alert?
					var error:NCBORestError = checkIfError(xml);
					if (error) {
						if (params.alertErrors) {
							alertErrorMessage(error.longMessage, error.shortMessage);
						}
						errorHandler(error);
					}
					
					var xmlHandler:Function = params.xmlHandler;
					var callbackEvent:NCBOEvent = xmlHandler(xml, error);
					params.parseTime = getTimer() - startParse;
					params.serverTime = startParse - startTime;
					callbackEvent.parseTime = params.parseTime;
					callbackEvent.serverTime = params.serverTime;
					
					// @tag Logging - do it here to have the server/parse times
					if (log && params.log) {
		    			LogService.logRestServiceEvent(callbackEvent);
		   			}
					
					//var callback:Function = params.callback;
					//callback(callbackEvent);
					callCallbacks(params.url, callbackEvent);
				};
				
				// If resending the url - DON'T cache the url
				// Otherwise - cache the URL to prevent multiple calls while waiting for a response
				var proceed:Boolean = resending || saveCallback(params.url, params.callback);
				if (proceed || params.allowMultipleCalls) {
					var url:String = params.url;
					// use the proxy for the retries so that we can get the error message xml
					if (useProxy) {
						// don't use the proxy url anymore since it depends on a php file on the uvic servers
						//url = PROXY_URL + escape(url);
					}					
					// save the call for debugging purposes
					trace("[REST] " + url);
					if (_restCalls.length > 30) {
						_restCalls.shift();		// remove the first element
					}
					_restCalls.push(params);	// add to the end of the array

					// perform the REST call
					var service:HTTPService = getService(url, resultHandler, defaultFaultHandler);
					var result:AsyncToken = service.send();
					result.restParameters = params;
				} else {
					//trace("[REST_cached] " + params.url);
				}
			} catch (error:Error) {
				errorHandler(error);
			}
		}
		
		protected function defaultFaultHandler(event:FaultEvent):void {
	  		var lastParams:NCBORestParams = (event.token.restParameters as NCBORestParams);
  			var alertErrors:Boolean = lastParams.alertErrors;
			var msg:String = null;
  			var useProxy:Boolean = (event.fault.faultCode == "Server.Error.Request");	// Stream #2032 error
	  		trace("Fault (" + lastParams.retryCount + "): " + event.fault.faultString + " - " + event.fault.faultDetail);
	  		if (lastParams.retryCount == 0) {
	  			// first simply try again, no warning
	  			lastParams.retryCount = 1;
	  			sendWithParams(lastParams, true, useProxy);
	  		} else if (lastParams.retryCount == 1) {
				msg = getErrorMessage(event.fault, lastParams.url);
	  			// second time - prompt user 
	  			var alertMsg:String = msg + "\nDo you want to try again?";
	  			var closeHandler:Function = function(ce:CloseEvent):void {
	  				showingError = false;
	  				if (ce.detail == Alert.YES) {
	  					trace("Re-sending the last request: " + lastParams.url);
	  					// set this flag so that we don't try to resend again if it fails immediately
	  					lastParams.retryCount = 2;
	  					// now resend the last request
	  					sendWithParams(lastParams, true, useProxy);
	  				} else {
						errorHandler(event.fault);
						// call xml handler and callback
						handleFaultCallback(lastParams, event.fault, msg);
	  				}
	  			};
				// don't show this error dialog if we are already showing a previous error
	  			if (!showingError && alertErrors) {
	  				showingError = true;
		  			Alert.show(alertMsg, "Connection Error", Alert.YES | Alert.NO, null, closeHandler, null, Alert.YES);
		  		} else if (!showingError) {
					errorHandler(event.fault);
					// call xml handler and callback
					handleFaultCallback(lastParams, event.fault, msg);
		  		}		  			
	  		} else {
				errorHandler(event.fault);
				// don't show this error dialog if we are already showing a previous error
				if (!showingError && lastParams.alertErrors) {
					msg = getErrorMessage(event.fault, lastParams.url);
					alertErrorMessage(msg);
		  		}
				// call the params callback
				handleFaultCallback(lastParams, event.fault, msg);
	  		}	  			
	    }
	    
	    private function alertErrorMessage(msg:String, title:String = "Error"):void {
	    	if (!showingError) {
	    		showingError = true;
	    		if (!title) {
  					title = "Error";
  				}
  				var closeHandler:Function = function(ce:CloseEvent):void {
  					showingError = false;
  				};
	    		if (alertErrorFunction == null) {
  					Alert.show(msg, title, Alert.OK, null, closeHandler); 
  				} else {
  					alertErrorFunction(msg, title, closeHandler);
  				}
  			}
	    }
	    	    
	    /**
	     * Get a nice error message instead of the default fault string.
	     */ 
	    private function getErrorMessage(fault:Fault, lastURL:String):String {
			var msg:String = "There was an error connecting to the server.  ";
			var timeout:Boolean = ("Client.Error.RequestTimeout" == fault.faultCode);
			if (!timeout) {
	  			// check for which url was used
	  			var ending:String;
	  			var split:Array;
	  			var params:Object = Utils.getURLParams(lastURL);
	  			var qm:int = lastURL.indexOf("?");
	  			if (qm != -1) {
		  			lastURL = lastURL.substring(0, qm);
	  			}
	  			if (StringUtils.startsWith(lastURL, CONCEPTS_URL)) {
	  				// split off the ontology ID and concept ID from the url
	  				ending = lastURL.substring(CONCEPTS_URL.length);
	  				split = ending.split("/");
	  				if (split.length == 2) {
	  					if (split[1] == "root") {
	  						msg = "Couldn't find the root concept(s) in the ontology '" + split[0] + "'.";
	  					} else {
	  						var cid:String = split[1];
	  						if ((cid.length == 0) && params.hasOwnProperty("conceptid")) {
	  							cid = params.conceptid;
	  						}
	  						cid = decodeURIComponent(cid);
	  						msg = "Couldn't find a concept with id '" + cid + "' in the ontology '" + 
	  								getOntologyNameOrID(split[0]) + "'.";
	  					} 
	  				} else {
	  					msg = "Couldn't find the given concept";
	  				}
	  			} else if (StringUtils.startsWith(lastURL, SEARCH_URL)) {
	  				// split off the ontology ID and concept ID from the url
	  				ending = lastURL.substring(SEARCH_URL.length);
	  				if (params.hasOwnProperty("ontologies")) {
	  					msg = "No search results were found for '" + ending + "' in these ontologies '" + 
	  							params.ontologies + "'."; 
	  				} else {
	  					msg = "No search results were found for '" + ending + "'."; 
	  				}
	  			} else if (StringUtils.startsWith(lastURL, ONTOLOGIES_URL)) {
	  				// split off the ontology ID and concept ID from the url
	  				ending = lastURL.substring(ONTOLOGIES_URL.length);
	  				if (ending.length > 0) {
	  					msg = "Couldn't find an ontology with id '" + 
	  								getOntologyNameOrID(ending) + "'.";  
	  				} else {
	  					msg = "Couldn't retrieve the list of ontologies from the server.";
	  				}
	  			} else if (StringUtils.startsWith(lastURL, CATEGORIES_URL)) {
	  				msg = "Error retrieving the list of ontology categories";
	  			}
	  		} else {
	  			msg = "The server is not responding, try again later.";
	  		}
	  		return msg;	
	    }
	    
	    /**
	     * This function gets called after a FaultEvent.  It sends error XML
	     * to the xml handler and then calls the callback defined in the params.
	     */ 
	    private function handleFaultCallback(params:NCBORestParams, fault:Fault, msg:String = null):void {
	    	var xmlHandler:Function = params.xmlHandler;
			var xml:XML = ERROR_XML.copy();
//			xml.@niceMessage = (msg ? msg : fault.faultString);
//			xml.@faultString = fault.faultString;
//			xml.@faultCode = fault.faultCode;
//			xml.@faultDetail = fault.faultDetail;
//			xml.@message = fault.message;
			var error:NCBORestError = new NCBORestError((msg ? msg : fault.faultString), "Error", fault.faultCode);
			var callbackEvent:NCBOEvent = xmlHandler(xml, error);
			//var callback:Function = params.callback;
			//callback(callbackEvent);
			callCallbacks(params.url, callbackEvent);
	    }
	    
		/** Passes the error on to an error function. */
		private function errorHandler(error:Error):void {
			if (error != null) {
				trace("NCBORestService error: " + error);
				if (_errorFunction != null) {
					_errorFunction(error);
				} else {
					// @tag Logging already handled in the above error function for FlexViz
					if (log) {
						LogService.logError(error);
					}
				}
			}
		}
		
		/**
		 * Saves a callback function for the given url.
		 * @return true if this is the first callback for the url
		 */
		private function saveCallback(url:String, callback:Function):Boolean {
			var first:Boolean = false;
			if (!callbacksMap.hasOwnProperty(url)) {
				callbacksMap[url] = new Array();
				first = true;
			}
			var callbacks:Array = (callbacksMap[url] as Array);
			callbacks.push(callback);
			//trace("Saved callback for " + url + "  (first=" + first + ")");
			return first;
		}
		
		/**
		 * Calls all the callback functions for a rest service call with the given event.
		 * Also clears the callback map for the url.
		 */ 
		private function callCallbacks(url:String, event:NCBOEvent):void {
			var callbacks:Array = (callbacksMap[url] as Array);
			if ((callbacks != null) && (callbacks.length > 0)) {
				//trace("Calling " + callbacks.length + " callbacks for " + url);
				for (var i:int = 0; i < callbacks.length; i++) {
					var callback:Function = (callbacks[i] as Function);
					callback(event);
				}
			} else {
				trace("** Warning - no callbacks for " + url + ", this should not happen!");
			}
			delete callbacksMap[url];
		}
		
	    /**
		 * Warning - this method doesn't retrieve the ontology information from the rest services.
		 * @param id the ontolog id
		 * @param addIfDoesntExist if true (default) then the ontology stub will be created if it doesn't exist
		 */
	    public function getOntology(id:String, addIfDoesntExist:Boolean = true):NCBOOntology {
	    	if ((id == null) || (id.length == 0)) {
	    		trace("Warning - invalid ontology id!");
	    		return null;
	    	}
	    	if (!_ontologies.hasOwnProperty(id) && addIfDoesntExist) {
	    		// placeholder - won't have all the properties!
	    		_ontologies[id] = new NCBOOntology(id, "");
	    		//trace("Added ontology stub: " + id);
	    	}
	    	return NCBOOntology(_ontologies[id]);
	    }
	    
	    private function getOntologyNameOrID(id:String):String {
	    	var name:String = "";
	    	var ont:NCBOOntology = getOntology(id);
	    	if (ont) {
	    		name = ont.name;
	    	}
	    	return (name.length == 0 ? id : name);
	    }
	    
	    public function getConceptFromCache(ontologyID:String, conceptID:String):NCBOConcept {
	    	return getOntology(ontologyID).getConcept(conceptID);	
	    }
	    
	    public function getRelationshipFromCache(ontologyID:String, relID:String):NCBORelationship {
	    	return getOntology(ontologyID).getRelationship(relID);
	    }
	    
	    /** Clears the concepts from the cache. */ 
	    public function clearConcepts(ontologyID:String = null):void {
	    	if (ontologyID == null) {
	    		// clear all concepts from all ontologies
		    	for each (var ontology:NCBOOntology in _ontologies) {
		    		ontology.clear();
		    	}
		    } else if (_ontologies.hasOwnProperty(ontologyID)) {
		    	// clear only this ontology
		    	NCBOOntology(_ontologies[ontologyID]).clear();
		    }
	    }
	    
	    public function clearOntologies():void {
	    	_ontologies = new Object();
	    	_ontologiesList = new Array();
	    }
	    
	    /** Clears the loaded categories. */ 
	    public function clearCategories():void {
	    	_categoriesList = null;
	    	_categories = new Object();
	    }
	    
	    ///////////////////////////
	    // REST Service Methods
	    ///////////////////////////
	    
	    /**
		 * Loads all the ontology groups and returns them to the callback function.
		 * The callback will take one NCBOGroupsEvent parameter.
		 */
	    public function getOntologyGroups(callback:Function):void {
	    	if (_groupsList == null) {
	        	send(GROUPS_URL, parseOntologyGroupsXML, callback);
    	 	} else {
    	 		callback(new NCBOGroupsEvent(_groupsList));
    	 	}
	    }
	    
	    /**
	     * Loads the ontology categories.
	     * The categories are returned to the callback function wrapped in a NCBOCategoriesEvent parameter.
	     */
	     public function getOntologyCategories(callback:Function):void {
	     	if (_categoriesList == null) {
	        	send(CATEGORIES_URL, parseOntologyCategoriesXML, callback);
    	 	} else {
    	 		callback(new NCBOCategoriesEvent(_categoriesList));
    	 	}
	     } 
 	    
 	    /**
 	     * Loads the all the NCBO ontologies.
 	     * @param callback the callback function, should have one parameter - an NCBOOntologiesEvent
 	     */
	    public function getNCBOOntologies(callback:Function):void {
	    	if (_ontologiesList == null) {
	        	send(ONTOLOGIES_URL, parseAllOntologiesXML, callback);
    	 	} else {
    	 		callback(new NCBOOntologiesEvent(_ontologiesList));
    	 	}
	    }
	    
	    /**
	    * Makes a call to the REST services for the NCBOOntology if it doesn't exist in our cache.
	    * @param getExtraInfo if true then we ensure that all the ontology properties have been loaded.
	    */
	    public function getNCBOOntology(id:String, callback:Function, getExtraInfo:Boolean = false, alertErrors:Boolean = true):void {
	    	var reload:Boolean = true;
	    	var ontology:NCBOOntology = getOntology(id);
	    	if (ontology != null) {
	    		reload = false;
	    		if (getExtraInfo) {
		    		if (ontology.displayLabel.length == 0) {
		    			// need to reload this infomation
		    			reload = true;
		    		}
		    	}
	    	}
	    	var url:String = ONTOLOGIES_URL + id; 
	    	if (reload) {
	        	send(url, parseOntologyXML, callback, false, alertErrors);
	    	} else {
	    		sendLogOnly(url);	// @tag logging
	    		callback(new NCBOOntologyEvent(ontology));
	    	}
	    }
	    
	   	/**
	     * Makes a call to the REST services for the NCBOOntology with the given ontology ID.
	     * This ontology ID is also referred to as the "virtual" ID since it never changes.
	     */ 
	    public function getOntologyByVirtualID(virtualID:String, callback:Function, alertErrors:Boolean = true):void {
	    	var url:String = ONTOLOGY_VIRTUAL_URL + virtualID;
	    	send(url, parseOntologyXML, callback, false, alertErrors);
	    }
	    
	    public function getOntologyVersions(virtualID:String, callback:Function):void {
	    	var url:String = ONTOLOGY_VERSIONS_URL + virtualID;
	    	var wrapper:Function = function(event:NCBOOntologiesEvent):void {
	    		if (event.ontologies && (event.ontologies.length > 0)) {
	    			// newest first
	    			event.ontologies.sortOn("id", Array.NUMERIC | Array.DESCENDING);
	    		}
	    		callback(event);
	    	};
	    	send(url, parseOntologiesXML, wrapper);
	    }
	    
  		/**
		 * Returns the ontology metrics for the given ontology (either the version id or virtual id).
		 */
		public function getOntologyMetrics(ontologyID:String, callback:Function, isVirtual:Boolean = false):void {
			// currently there is no service which supports giving the virtual id
			if (isVirtual) {
				getOntologyByVirtualID(ontologyID, function(event:NCBOOntologyEvent):void {
					getOntologyMetrics2(event.ontology, callback, event.error);
				}, false);
			} else if (ontologyID) {
				getNCBOOntology(ontologyID, function(event:NCBOOntologyEvent):void {
					getOntologyMetrics2(event.ontology, callback, event.error);
				}, true, false);
			} else if (callback != null) {
				callback(new NCBOOntologyMetricsEvent(null, new Error("Invalid ontology version id")));
			}
		} 
		
		private function getOntologyMetrics2(ontology:IOntology, callback:Function, error:Error = null):void {
			if (ontology) {
				var url:String = ONTOLOGY_METRICS_URL + ontology.ontologyVersionID;
				// need to set the ontology property
				var wrapper:Function = function(event:NCBOOntologyMetricsEvent):void {
					if (event.metrics) {
						event.metrics.ontology = ontology;
					}
					if (callback != null) {
						callback(event);
					}
				};
				send(url, parseOntologyMetricsXML, wrapper);
			} else if (callback != null) {
				callback(new NCBOOntologyMetricsEvent(null, (error ? error : new Error("Invalid ontology id"))));
			}
		}

	    
	    /**
	     * Loads the root nodes for the given ontology.
	     * If the ontology has already loaded the roots, then the callback function is called immediately.
	     * Otherwise the rest service will go get the roots and then call the callback.
	     * @param callback the function which gets called with the NCBOConceptsEvent object
	     */
	    public function getTopLevelNodes(ontologyID:String, callback:Function):void {
	    	var ontology:NCBOOntology = getOntology(ontologyID);
	    	if (ontology == null) {
	    		var errorMsg:String = "Cannot load root nodes - invalid ontology ID: " + ontologyID;
	    		trace(errorMsg);
	    		callback(new NCBOConceptsEvent([], "NCBOConceptsEvent", new Error(errorMsg), ontologyID));
	    		return;
	    	}
	    	
	    	var url:String = CONCEPTS_URL + ontologyID + "/root";
	    	if (!ontology.hasLoadedRoots) {
	    		var xmlWrapper:Function = function(xml:XML, error:Error = null):NCBOEvent {
	    			// April 21st 2010 - changing to parse and return the children of THING
	    			// They won't have loaded neighborhoods
	    			return parseTopLevelNodes(xml, ontology, error);
	    			// Old way - just pick out the subclass concept ids
	    			//var items:Array = getSubClassConceptIDs(xml);
					//return new NCBOEvent(items, "NCBOTopLevelNodes", error);
	    		};
	    		// This is not done anymore - the parseTopLevelNodes sets the ontology.topLevelNodes
//	    		var service:NCBORestService = this;
//				var callbackWrapper:Function = function(event:NCBOEvent):void {
//		    		var innerCallback:Function = function(innerEvent:NCBOOperationsEvent):void {
//						ontology.topLevelNodes = innerEvent.matchingConcepts;
//						callback(new NCBOConceptsEvent(innerEvent.matchingConcepts));
//		    		};
//		    		var op:LoadConceptsOperation = new LoadConceptsOperation(service, ontologyID, 
//		    													event.collection, innerCallback);
//		    		op.start();
//				};
	        	send(url, xmlWrapper, callback/*callbackWrapper*/);
	    	} else {
	    		sendLogOnly(url);	// @tag logging
	    		callback(new NCBOConceptsEvent(ontology.topLevelNodes));
	    	}
	    }
	    
	    /**
	     * Gets a concept from an ontology by ID.  
	     * The callback function should accept one parameter - an NCBONodeEvent object.
	     * This function will first try to find the node from the cache, if it can't be found
	     * then it will make a call to the web service to find the node.
	     * @param ontologyID the id of the ontology
	     * @param conceptID the id of the concept to find
	     * @param callback the function to call when the concept has been found (takes one param - NCBOConceptEvent)
	     * @param loadNeighbors if true and if the concept doesn't have its neighbors loaded yet we make a 
	     * 	call to the rest services to load concept and therefore the neighbors too.
  	     * @param alertErrors if true and and error happens, an Alert box will show up displaying the error
  	     * @param light if true then the light version of the rest service XML is returned (basic concept info)
  	     * @param noRelations if true then the returned XML doesn't contain any relation information
  	     */
	    public function getConceptByID(ontologyID:String, conceptID:String, callback:Function, 
	    					loadNeighbors:Boolean = false, alertErrors:Boolean = true, 
	    					light:Boolean = false, noRelations:Boolean = false):void {
	    	var ontology:NCBOOntology = getOntology(ontologyID);
	    	if (ontology == null) {
	    		var errorMsg:String = "Invalid ontology ID: " + ontologyID;
	    		callback(new NCBOConceptEvent(null, new Error(errorMsg), ontologyID));
	    		return;
	    	}
	    	
    		var encodedID:String = encodeURIComponent(conceptID);
    		// need to encode the id in case it has any slashes or invalid url characters
    		// special case - if the concept id has slashes, then we pass it in as a parameter instead
    		if (conceptID.indexOf("/") != -1) {
    			encodedID = "?conceptid=" + encodedID;
    		}
	    	var url:String = CONCEPTS_URL + ontologyID + "/" + encodedID;
	    	
	    	// ** TODO - haven't tested what happens with caching when parsing the light or norelations XML
	    	
	    	// Return light version of XML? 
	    	if (light) {
	    		url = StringUtils.addURLParameter(url, "light", "1");
	    	}
	    	// Return XML without relations?
	    	if (noRelations) {
	    		url = StringUtils.addURLParameter(url, "norelations", "1");
	    	}
	    	
	    	var concept:NCBOConcept = ontology.getConcept(conceptID);
	    	if ((concept == null) || (loadNeighbors && !concept.hasLoadedNeighbors)) {
	    		var xmlWrapper:Function = function(xml:XML, error:Error = null):NCBOConceptsEvent {
	    			return parseConceptXML(xml, ontologyID, true, error);
	    		};
	        	send(url, xmlWrapper, callback, false, alertErrors);
	    	} else {
	    		sendLogOnly(url);	// @tag logging
	    		callback(new NCBOConceptEvent(concept));
	    	}
	    }
	    
	    /**
	     * Searches for concepts by name in a single ontology.  
	     * Currently the mode only supports contains (default) or exact match.
	     * The callback will take an NCBOSearchEvent parameter containing the matching ontologies
	     * (which there should only be one) and the matching concepts for that ontology.
	     * Note that the search results will contain NCBOSearchResultConcept objects,
	     * not the full NCBOConcept objects.
	     */
	    public function getConceptsByName(ontology:NCBOOntology, conceptName:String, mode:SearchMode, callback:Function):void {
	    	var params:SearchParams = new SearchParams(conceptName);
	    	if (mode.name == SearchMode.EXACT_MATCH.name) {
	    		params.exactMatch = true;
	    	}
	    	params.addOntology(ontology);
	    	
	    	search(params, callback, false /* hit counts not needed? */);
	    }
	    
	    /**
	     * Searchs for the given text using the search parameters over multiple ontologies.
	     * The callback will take one parameter of type NCBOSearchEvent containing the ontologies
	     * with matching concepts. 
	     * Note that the search results will contain NCBOSearchResultOntology and NCBOSearchResultConcept objects,
	     * not the full NCBOOntology or NCBOConcept objects.
	     */
	    public function search(params:SearchParams, callback:Function, parseHits:Boolean = true, logEvent:Boolean = true):void {
	    	if (params.isValid) {
	    		var xmlWrapper:Function = function(xml:XML, error:Error = null):NCBOSearchEvent {
	    			return parseSearchResultsXML(xml, params, parseHits, error);
	    		};
		    	var url:String = SEARCH_URL + params.queryString;
		    	send(url, xmlWrapper, callback, false, true, logEvent);
		    } else {
		    	var msg:String = "The search text must be valid";
		    	callback(new NCBOSearchEvent(null, null, params, new Error(msg)));
		    }
	    }
	    
	    /**
	     * Loads the children concepts from the Rest services if they haven't already been loaded,
	     * and returns them to the callback function wrapped in a NCBOConceptsEvent.
	     * @param subClassesOnly if true then only the children that are specified as subclasses in the
	     *  					 rest services XML are returned. Otherwise all children are returned.
	     */
	    public function getChildConcepts(ontologyID:String, conceptID:String, callback:Function,
	    								 subClassesOnly:Boolean = false):void {
	    	if (conceptID == null) {
	    		getTopLevelNodes(ontologyID, callback);
	    		return;
	    	}
	    	
	    	var ourCallback:Function = function(event:NCBOConceptEvent):void {
	    		var parent:NCBOConcept = event.concept;
	    		if (parent == null) {
	    			var errorMsg:String = "Warning - couldn't find parent concept with id: " + conceptID;
	    			trace(errorMsg);
	    			callback(new NCBOConceptEvent(null, new Error(errorMsg), ontologyID));
	    			return;
	    		}
	    		
		    	if (!parent.hasLoadedNeighbors) {
		    		// we need to wrap the callback because it won't return the correct children,
		    		// it will return the parent instead.  So we manually return the children
		    		var callbackWrapper:Function = function(event:NCBOConceptsEvent):void {
		    			var children:Array = (subClassesOnly ? parent.subClasses : parent.children);
		    			var realEvent:NCBOConceptsEvent = new NCBOConceptsEvent(children, "NCBOConceptsEvent", event.error);
		    			realEvent.parseTime = event.parseTime;
		    			realEvent.serverTime = event.serverTime;
		    			callback(realEvent);
		    		};
		    		getConceptByID(ontologyID, parent.id, callbackWrapper, true);
		    	} else {
		    		callback(new NCBOConceptsEvent((subClassesOnly ? parent.subClasses : parent.children)));
		    	}
	    	};
	    	getConceptByID(ontologyID, conceptID, ourCallback);
	    }
	    
	    /**
	     * Loads the parents concepts from the Rest services if they haven't already been loaded,
	     * and returns them to the callback function wrapped in a NCBOConceptsEvent.
	     * @param superClassesOnly if true then only the parents that are specified as superclasses in the
	     *  					 rest services XML are returned. Otherwise all parents are returned.
	     */
	    public function getParentConcepts(ontologyID:String, conceptID:String, callback:Function,
	    								  superClassesOnly:Boolean = false):void {
	    	var ourCallback:Function = function(event:NCBOConceptEvent):void {
	    		var child:NCBOConcept = event.concept;
	    		if (child == null) {
	    			var errorMsg:String = "Warning - couldn't find child concept with id: " + conceptID;
	    			trace(errorMsg);
	    			callback(new NCBOConceptEvent(null, new Error(errorMsg), ontologyID));
	    			return;
	    		}
	    		
		    	if (!child.hasLoadedNeighbors) {
		    		// we need to wrap the callback because it won't return the correct parents,
		    		// it will return the child instead.  So we manually return the parents.
		    		var callbackWrapper:Function = function(event:NCBOConceptsEvent):void {
		    			var parents:Array = (superClassesOnly ? child.superClasses : child.parents);
		    			var realEvent:NCBOConceptsEvent = new NCBOConceptsEvent(parents, "NCBOConceptsEvent", event.error);
		    			realEvent.parseTime = event.parseTime;
		    			realEvent.serverTime = event.serverTime;
		    			callback(realEvent);
		    		};
		    		getConceptByID(ontologyID, child.id, callbackWrapper, true);
		    	} else {
		    		callback(new NCBOConceptsEvent((superClassesOnly ? child.superClasses : child.parents)));
		    	}
	    	};
	    	getConceptByID(ontologyID, conceptID, ourCallback);
	    }
	    
	    /**
	     * Retrieves the path to root for the given concept and ontology.
	     * The returned event is an NCBOPathToRootEvent which contains the path to root.
	     * The path is an array of NCBOConcept objects (including the given concept)
	     * starting from the root and ending in the given concept.
	     * The root is not THING or owl:Thing, instead it is the visible root underneath Thing.
	     * @param ontologyID the id of the ontology
	     * @param conceptID the id of the concept to find the path to root
	     * @param callback the function which gets called with the NCBOPathToRootEvent object
	     */
	    public function getPathToRoot(ontologyID:String, conceptID:String, callback:Function):void {
			if (ontologyID && conceptID) {			
	    		var url:String = PATHS_TO_ROOT_URL + ontologyID + "/?source=" + 
	    							StringUtils.encodeURLString(conceptID) + "&target=root";
	    		var wrapper:Function = function(xml:XML, error:Error = null):NCBOPathToRootEvent {
	    			return parsePathToRootXML(xml, conceptID, ontologyID, error);
	    		};
	    		send(url, wrapper, callback);
	  		} else if (callback != null) {
  				var error:Error = new Error("Invalid ontology or term ID");
  				callback(new NCBOPathToRootEvent(conceptID, ontologyID, null, error));
	  		}
	    }
	    
	    
	    ///////////////////////////
	    // Parse Methods
	    ///////////////////////////
 	    
	    /**
		 * Checks if the XML is the error status bean xml.
		 * If so it throws a NCBORestError.
		 */
		private function checkIfError(xml:XML):NCBORestError {
			var restError:NCBORestError = null;
			if (xml != null) {
				var name:String = xml.name();
				if ((name == ERROR_STATUS_BEAN) || (name == ERROR_STATUS)) {
					var longMsg:String = xml.longMessage;
					var shortMsg:String = xml.shortMessage;
					var errorCode:String = xml.errorCode;
					var accessedResource:String = xml.accessedResource;
					var accessDate:String = xml.accessDate;
					restError = new NCBORestError(longMsg, shortMsg, errorCode, accessedResource, accessDate);
				} else if (name == ERROR_XML.name()) {
					var msg:String = xml.@niceMessage;
					restError = new NCBORestError(msg, msg);
				} else if (name != SUCCESS) {
					msg = "The rest services did not return successfully";
					//var str:String = xml.toXMLString(); 
					restError = new NCBORestError(msg, msg);
				}
			}
			return restError;
		}
		
		/**
		 * Parses the ontology categories xml like:
		 * <success><data><list>
		 *   <groupBean>
		 *     <id>6001</id>
		 *     <name>OBO Foundry</name>
		 *     <acronym>OBO Foundry</acronym>
		 *   </groupBean>
		 * </list></data></success>
		 */
		private function parseOntologyGroupsXML(xml:XML, error:Error = null):NCBOGroupsEvent {
			if (!error) {
				this._groups = new Object();
				_groupsList = new Array();
				var list:XMLList = xml.data.list.groupBean;
				for each (var group:XML in list) {
					var id:String = group.id;
					if ((id != null) && (id.length > 0)) {
						var name:String = group.name;
						var acro:String = group.acronym;
						var ontGroup:NCBOOntologyGroup = new NCBOOntologyGroup(id, name, acro);
						_groups[id] = ontGroup;
						_groupsList.push(ontGroup);
					}
				}
				// sort alphabetically
				_groupsList.sortOn("name");
			}
			return new NCBOGroupsEvent(_groupsList, error);
		}
	
		/**
		 * Parses the ontology categories xml like:
		 * <success><data><list>
		 * 	<categoryBean>
		 * 		<id>2801</id>
		 * 		<name>Other</name>
		 * 	</categoryBean>
		 * 	<categoryBean>
		 * 		<id>2802</id>
		 * 		<name>Chemical</name>
		 * 		<oboFoundryName>chemical</oboFoundryName>
		 * 	</categoryBean>
		 * </list></data></success>
		 */
		private function parseOntologyCategoriesXML(xml:XML, error:Error = null):NCBOCategoriesEvent {
			if (!error) {
				this._categories = new Object();
				_categoriesList = new Array();
				var list:XMLList = xml.data.list.categoryBean;
				for each (var cat:XML in list) {
					var id:String = cat.id;
					if ((id != null) && (id.length > 0)) {
						var name:String = cat.name;
						// var oboFoundryName:String = cat.oboFoundryName;
						var category:NCBOCategory = new NCBOCategory(id, name);
						_categories[id] = category;
						_categoriesList.push(category);
					}
				}
				// sort alphabetically
				_categoriesList.sortOn("name");
			}
			return new NCBOCategoriesEvent(_categoriesList, error);
		}
		
		/**
		 * Parses the ontologies XML, returning an Array 
		 * of ontologies objects (id, ontologyId etc).
		 * E.g.
		 * <success><data><list>
		 * 		  <ontologyBean>
		 * 			<id>32145</id>
		 * 			<ontologyId>1001</ontologyId>
		 * 			<internalVersionNumber>2</internalVersionNumber>
		 * 			<versionNumber>1.0.1</versionNumber>
		 * 			<versionStatus>production</versionStatus>
		 * 			<contactName>Ghislain Atemezing</contactName>
		 * 			<contactEmail>atemezing&amp;yahoo.com</contactEmail>
		 * 			<statusId>3</statusId><!-- will be 4 or 5 is remote ontology -->
		 * 			<categoryIds><int>5058</int><int>2801</int></categoryIds>
		 * 		  </ontology>
		 * 		  <ontology>
		 * 		  ...
		 * 		  </ontology>
		 * <list></data></success>
		 */
		private function parseOntologiesXML(xml:XML, error:Error = null):NCBOOntologiesEvent {
			var ontologies:Array = [];
			if (!error) {
				var list:XMLList = xml.data.list.ontologyBean;
				for each (var ont:XML in list) {
					var ontology:NCBOOntology = parseSingleOntology(ont);
					if (ontology != null) {
						// For now only save the local ontologies since we can't visualize the external ones
						if (ontology.isLocal) {
							ontologies.push(ontology);
						}
					} else {
						trace("** Error parsing ontology: " + ont.toXMLString());
					}
				}
			}
			
			//trace("Found " + ontologies.length + " ontologies!");
			return new NCBOOntologiesEvent(ontologies, error);
		}
		
		private function parseAllOntologiesXML(xml:XML, error:Error = null):NCBOOntologiesEvent {
			var event:NCBOOntologiesEvent = parseOntologiesXML(xml, error);
			if (event.ontologies.length > 0) {
				// cache and sort these ontologies
				_ontologiesList = event.ontologies;
				_ontologiesList.sortOn("name", Array.CASEINSENSITIVE);
			}
			return event;
		}
		
		/**
		 * Parses single ontology XML.
		 * E.g.
		 * 	<success><data>
		 * 		<ontologyBean>
		 * 			<id>32145</id>
		 * 			<ontologyId>1001</ontologyId>
		 * 			<displayLabel>African Traditional Medicine</displayLabel>
		 * 			<description>African Traditional Medicine Ontology (ATMO) describes ...</description>
		 * 			<abbreviation>ATMO</abbreviation>
		 * 			<format>OBO</format>
		 * 			<internalVersionNumber>1</internalVersionNumber>
		 * 			<versionNumber>1.0.1</versionNumber>
		 * 			<versionStatus>production</versionStatus>
		 * 			<contactName>Ghislain Atemezing</contactName>
		 * 			<contactEmail>atemezing&amp;yahoo.com</contactEmail>
		 * 			<statusId>4</statusId>
		 * 			<categoryIds><int>5058</int></categoryIds>
		 * 			<dateCreated class="sql-timestamp">2008-04-15 08:40:46.0</dateCreated>
		 * 			<dateReleased class="sql-timestamp">2008-04-16 00:00:00.0</dateReleased>
		 * 		</ontology>
		 * 	</data></success>
		 */
		private function parseOntologyXML(xml:XML, error:Error = null):NCBOOntologyEvent {
			if (!error) {
				var list:XMLList = xml.data.ontologyBean;
				var ontology:NCBOOntology = null;
				if (list.length() > 0) {
					var ontXML:XML = list[0]; 
					ontology = parseSingleOntology(ontXML);
				}
			}
			return new NCBOOntologyEvent(ontology, error);
		}
		
		/**
		 * Parses a single ontology XML and returns the NCBOOntology object.
		 */
		private function parseSingleOntology(ontXML:XML):NCBOOntology {
			var ontology:NCBOOntology = null;
			var id:String = ontXML.id;
			if ((id != null) && (id.length > 0)) {
				// get the placeholder ontology, won't have all the values
				ontology = getOntology(id);
				// ensure that the fields have been populated
				ontology.ontologyID = ontXML.ontologyId;
				ontology.displayLabel = ontXML.displayLabel;
				ontology.abbreviation = ontXML.abbreviation;
				ontology.format = ontXML.format;
				// status: 3 means local ontology, 4 or 5 means remote?
				ontology.statusID = parseInt(ontXML.statusId, 10);
				ontology.version = StringUtil.trim(String(ontXML.versionNumber + " " + ontXML.versionStatus));
				ontology.internalVersionNumber = Number(ontXML.internalVersionNumber);
				ontology.isRemote = Utils.toBoolean(ontXML.isRemote, false);
				ontology.isView = Utils.toBoolean(ontXML.isView, false);
				ontology.dateCreated = DateUtils.parseSQLDate(String(ontXML.dateCreated));
				//trace("Found ontology: " + ontology.displayLabel);
				
				var categories:Array = parseIntIDs(ontXML.categoryIds);
				ontology.categoryIDs = categories;
				
				var groups:Array = parseIntIDs(ontXML.groupIds);
				ontology.groupIDs = groups;
				
				/* extra properties 
				ontology.internalVersionNumber = ontXML.internalVersionNumber;
				ontology.versionNumber = ontXML.versionNumber;
				ontology.versionStatus = ontXML.versionStatus;
				ontology.contactName = ontXML.contactName;
				ontology.contactEmail = ontXML.contactEmail; 
				ontology.isRemote = (parseInt(ontXML.isRemote, 10) == 1);
				ontology.isReviewed = (parseInt(ontXML.isReviewed, 10) == 1);
				ontology.isManual = (parseInt(ontXML.isManual, 10) == 1);
				ontology.isFoundry = (parseInt(ontXML.isFoundry, 10) == 1);
				ontology.synonymSlot = ontXML.synonymSlot;
				ontology.preferredNameSlot = ontXML.preferredNameSlot;
				ontology.description = ontXML.description;
				*/
			}
			return ontology;
		}
		
		private function parseOntologyMetricsXML(xml:XML, error:Error = null):NCBOOntologyMetricsEvent {
			var list:XMLList = xml.data.ontologyMetricsBean;
			var metrics:NCBOOntologyMetrics = null;
			if ((error == null) && (list.length() > 0)) {
				var metricsXML:XML = list[0];
				metrics = new NCBOOntologyMetrics();
				metrics.ontologyVersionID = metricsXML.id;
				metrics.numAxioms = metricsXML.numberOfAxioms;
				metrics.numClasses = metricsXML.numberOfClasses;
				metrics.numIndividuals = metricsXML.numberOfIndividuals;
				metrics.numProperties = metricsXML.numberOfProperties;
				metrics.maxDepth = metricsXML.maximumDepth;
				metrics.maxNumSiblings = metricsXML.maximumNumberOfSiblings;
				metrics.avgNumSiblings = metricsXML.averageNumberOfSiblings;
			} else if (error == null) {
				error = new Error("No ontology metrics were returned");
			}
			
			return new NCBOOntologyMetricsEvent(metrics, error);
		}
			
		/**
		 * Parses integer ids from XML for the groupIds or categoryIds.
		 * Expects the xml in the form:
		 * <categoryIds><int>5053</int><int>2081</int></categoryIds> 
		 * or
		 * <groupIds><int>5053</int><int>2081</int></groupIds>
		 */
		public function parseIntIDs(xml:XMLList):Array {
			var ids:Array = new Array();
			if (xml.length() > 0) {
				var list:XMLList = xml[0].int;
				for each (var id:String in list) {
					if (id.length > 0) {
						ids.push(id);
					}
				}
			}
			return ids;
		}
		
		
		
		/**
		 * Parses the path to root XML.
		 * The xml contains the classBeans, which each contain just the ChildCount and SubClass relations. 
		 * It starts at the root (e.g. THING) and goes down to the given concept.
		 * <success><data>
		 * 	<classBean>
		 * 		<id>Melanoma</id>
		 * 		<fullId>Melanoma</fullId>
		 * 		<label>Melanoma</label>
		 * 		<type>Class</type>
  		 * 		<relations>
		 * 			<entry>
		 * 					</entry>
		 * 				</relations>
		 * 			</classBean>
		 * 			... (classBeans)
		 * 		</list>
		 * 	</data></success>
		 */
		private function parsePathToRootXML(xml:XML, conceptID:String, ontologyID:String, error:Error = null):NCBOPathToRootEvent {
			var path:Array = null;
			if (!error && xml) {
				path = [];
				 
				var classBeans:XMLList = xml.data.classBean;
				if (classBeans.length() == 1) {
					var thingBean:XML = classBeans[0];
					// Step 1: quickly pull out the path to root from the subClass beans
					// this builds up a very simple tree of just the concept IDs
					var cid:ConceptID = parseConceptIDsFromClassBean(thingBean);
					//trace("Got conceptID:");
					//trace(cid.toString());
					
					// Step 2: build the single path to root for the concept in question
					// This is an array of Strings starting with the root (not including THING/owl:Thing)
					// and going down to the requested concept 
					path = cid.getPathFromRoot(conceptID);
					//trace("Path to root: " + path.join(" -> "));
					if (path.length > 0) {
						// Step 3: Fully parse the class beans to populate the cache
						// can't use the root (owl:thing or thing) - it is not allowed
						var actualRoots:XMLList = thingBean.relations.entry.list.classBean;
						for each (var bean:XML in actualRoots) {
							// need to parse the children too!
							parseSingleConceptXML(bean, ontologyID, true, true);
						}
						
						//Step 4: get the concepts for each id
						for (var i:int = 0; i < path.length; i++) {
							var id:String = path[i];
							var concept:NCBOConcept = getConceptFromCache(ontologyID, id);
							if (concept) {
								path[i] = concept;
							} else {
								//path[i] = new NCBOConcept(id, "[Unknown]", "concept", ontologyID);
								error = new Error("Error parsing term '" + ontologyID + "/" + id + "'");
								path = null;
								break;
							}
						}
					}
				}
			}
			
			return new NCBOPathToRootEvent(conceptID, ontologyID, path, error);
		}
		
		/**
		 * Recursively picks out just the ids of the sub classes foudn in the xml.
		 * It is building up a tree which is stored in the root ConceptID object.
		 */
		private function parseConceptIDsFromClassBean(bean:XML):ConceptID {
			var id:String = bean.id;
			var conceptID:ConceptID = new ConceptID(id);
			var entries:XMLList = bean.relations.entry;
			for each (var entry:XML in entries) {
				var type:String = entry.string;
				if (type == SUB_CLASS) {
					var classBeans:XMLList = entry.list.classBean;
					for each (var subClassBean:XML in classBeans) {
						var childID:ConceptID = parseConceptIDsFromClassBean(subClassBean);
						conceptID.childIDs.push(childID);
					}
				}
			}
			return conceptID;
		}
		
		/**
		 * Parses the concept xml.
		 * E.g.
		 * 	<success><data>
		 * 		<classBean>
		 * 			<id>owl:Thing</id>
		 * 			<label>owl:Thing</label>
		 * 			<relations>
		 * 				<entry>
		 * 					<string>rdf:type</string>
		 * 					<list>
		 * 						<string>DefaultOWLNamedClass(owl:Class, FrameID(0:9004 0))</string>
		 * 					</list>
		 *				</entry>
		 * 				<entry>
		 * 					<string>SuperClass</string>
		 * 					<list/>
		 * 				</entry>
		 * 				<entry>
		 * 					<string>ChildCount</string>
		 * 					<int>1</int>
		 * 				</entry>
		 * 				<entry>
		 * 					<string>SubClass</string>
		 * 					<list>
		 * 						<classBean>
		 * 							<id>ProteinOntology</id>
		 * 							<label>ProteinOntology</label>
		 * 							<relations>
		 * 								same as above, except no SubClass or SuperClass relation
		 * 							</relations>
		 * 						</classBean>
		 * 					</list>
		 * 				</entry>
		 * 			</relations>
		 * 		</classBean>
		 * 	</data></success>
		 */
		 // public for testing purposes only
		public function parseConceptXML(xml:XML, ontologyID:String, singleConcept:Boolean = false, error:Error = null):NCBOConceptsEvent {
			if (error) {
				return (singleConcept ? new NCBOConceptEvent(null, error) :  
					new NCBOConceptsEvent(null, "NCBOConceptsEvent", error));
			}
			
			var concepts:Array = new Array();
			var ontology:NCBOOntology = getOntology(ontologyID);
			if (ontology != null) {
				var list:XMLList = xml.data.classBean;
				for each (var classBean:XML in list) {
					var concept:NCBOConcept = parseSingleConceptXML(classBean, ontologyID);
					if (concept != null) {
						// we know that we've loaded all the neighbors of this concept now
						concept.hasLoadedNeighbors = true;
						concepts.push(concept);
					}
				}
			}
			
			// DEBUGGING
			if (concepts.length > 1) {
				trace("NCBORestService.parseConceptXML(): returning " + concepts.length + " concepts!");
			}
			
			var event:NCBOConceptsEvent;
			if (singleConcept) {
				event = new NCBOConceptEvent(concepts.length > 0 ? concepts[0] : null);
			} else {
				event = new NCBOConceptsEvent(concepts);
			}
			event.ontologyVersionID = ontologyID;
			return event;
		}
		
		/**
		 * Parses a single concept from the XML.
		 * Expects the xml to be like:
		 * 	<classBean>
		 * 		<id>ProteinOntology</id>
		 * 		<label>ProteinOntology</label>
		 * 		<relations>
		 * 			SuperClass, SubClass, ChildCount...
		 * 		</relations>
		 * 	</classBean>
		 */
		private function parseSingleConceptXML(xml:XML, ontologyID:String, 
				parseEntries:Boolean = true, parseEntriesRecursively:Boolean = false):NCBOConcept {
			var concept:NCBOConcept = null;
			var id:String = xml.id;
			// Dec 2009 - the type has been made a top level property
			var type:String = xml.type;
			// check that the id is valid - can't be "owl:Thing", "THING" etc
			if ((id != null) && (id.length > 0) && conceptFilter(id)) {
				var ontology:NCBOOntology = getOntology(ontologyID);
				concept = ontology.getConcept(id);
				if (concept == null) {
					// this is the ONLY place where concepts should be created!
					var name:String = String(xml.label);
					concept = ontology.addConcept(id, name, type);
				}
				
				// Adding the fullID - won't be there for all ontologies, probably only OWL
				concept.fullID = xml.fullId;
				
				// Dec 2009 - definitions, synonyms, and authors have been made top level properties
				setConceptProperty(concept, OntologyConstants.DEFINITION, xml.definitions.string);
				setConceptProperty(concept, OntologyConstants.SYNONYM, xml.synonyms.string);
				setConceptProperty(concept, OntologyConstants.AUTHOR, xml.authors.string);
				
				// save the class beans for later
				var classBeansForLater:Array = new Array();
				var superClassIDs:Map = new Map();
				var subClassIDs:Map = new Map();
				var otherConcept:NCBOConcept = null;
				var entries:XMLList = xml.relations.entry;
				for each (var loopEntry:XML in entries) {
					// either the rel type ("is_a") or a predefined value like "ChildCount"
					// MUST do this before we check for references
					var string:String = loopEntry.string;

					// check for references, shouldn't happen any more
					var entry:XML = checkForReference(loopEntry, entries);

					var isClassBean:Boolean = (entry.list.classBean.length() > 0);
					var isInstanceBean:Boolean = (entry.list.instanceBean.length() > 0);
					if (string == CHILD_COUNT) {
						concept.childCount = Utils.toInt(entry.int, 10, -1);
						//trace(concept.name + " child count: " + concept.childCount);
					//} else if (string == PARENT_COUNT) {
						// TODO the xml doesn't support this
						// see feature request #468
						// https://bmir-gforge.stanford.edu/gf/project/bioportal_core/tracker/?action=TrackerItemEdit&tracker_item_id=468
						//concept.parentCount = Utils.toInt(entry.int, 10, -1);
					} else if (string == SUPER_CLASS) {
						if (parseEntries) {
							for each (var superClassBean:XML in entry.list.classBean) {
								// don't parse the child entries of this node - only populate the id/label/properties
								otherConcept = parseSingleConceptXML(superClassBean, ontologyID, false);
								if (otherConcept != null) {
									// save the id of the parent for later
									superClassIDs.setValue(otherConcept.id, otherConcept);	
								}
							}
						}
					} else if (string == SUB_CLASS) {
						if (parseEntries) {
							for each (var subClassBean:XML in entry.list.classBean) {
								// only parse the child entries of this node if specifically request
								// otherwise only populate the id/label/properties
								otherConcept = parseSingleConceptXML(subClassBean, ontologyID, 
													parseEntriesRecursively, parseEntriesRecursively);
								if (otherConcept != null) {
									// save the id of the child for later
									subClassIDs.setValue(otherConcept.id, otherConcept);
								}
							}
						}
					}
					// Owl only 
					else if (StringUtils.equals(string, RDF_TYPE, true)) {
						if (entry.list.string.length() >= 1) {
							var rdfType:String = entry.list.string[0].text();
							// e.g. DefaultOWLNamedClass(owl:Class, FrameID(0:9004 0))
							var bracket:int = rdfType.indexOf("(");
							if (bracket != -1) {
								rdfType = rdfType.substring(0, bracket);
							}
							rdfType = stripLanguagePrefix(rdfType);
							if (type.length == 0) {
								concept.type = rdfType;
							} else {
								concept.setProperty(RDF_TYPE, rdfType);
							}
						}
					}
					// save these for later
					else if (isClassBean) {
						if (parseEntries) {
							// important - save the original entry, not the reference entry!
							classBeansForLater.push(loopEntry);
						}
					} else {
						if (entry.list.string.length() >= 1) {
							var props:Array = [];
							for each (var str:String in entry.list.string) {
								str = stripLanguagePrefix(str);
								props.push(str);
							}
							if (props.length == 1) {
								concept.setProperty(string, props[0]); 
							} else if (props.length > 1) {
								concept.setProperty(string, props);
							}
						}
					}
					
				}
				
				// now deal with the left over classbeans
				if (parseEntries) {
					addExtraClassBeans(concept, ontology, entries, classBeansForLater, superClassIDs, subClassIDs);
				}
				
				dispatchEvent(new NCBOConceptLoadedEvent(NCBOConceptLoadedEvent.CONCEPT_LOADED, concept));
			}
			
			return concept;
		}
		
		private function addExtraClassBeans(concept:NCBOConcept, ontology:NCBOOntology, entries:XMLList, 
											classBeansForLater:Array, superClassIDs:Map, subClassIDs:Map):void {
			// many of these will be duplicate relations that were defined in the SubClass and SuperClass beans
			// but this way we can pick out the relationship type
			if (classBeansForLater.length > 0) {
				for (var i:int = 0; i < classBeansForLater.length; i++) {
					var entry:XML = XML(classBeansForLater[i]);
					var rawRelType:String = String(entry.string);
					// check for reverse arcs (a "[R]" in the relType) 
					var isReverse:Boolean = StringUtils.startsWith(rawRelType, "[R]");
					var relType:String = parseRelationshipType(rawRelType);
					if (relType.length > 0) {
						// just in case this entry is actually a reference to another entry
						entry = checkForReference(entry, entries);
						
						for each (var classBean:XML in entry.list.classBean) {
							var otherConcept:NCBOConcept = parseSingleConceptXML(classBean, ontology.id);
							if (otherConcept != null) {
								//trace("Relation: " + concept.id + " <- " + relType + " -> " + otherConcept.id);
								
								var isParent:Boolean = superClassIDs.containsKey(otherConcept.id);
								var isChild:Boolean = subClassIDs.containsKey(otherConcept.id);
								
								if (isChild) {
									// Skip reverse arcs, bug #1108 ?
									//if (!isReverse) {
									
										// April 21st - parent -> child relationships are not inverted by default
										// if there is a [R] present, then we set it inverted
										ontology.addRelationship(concept, otherConcept, true, relType, isReverse);
									//}
									// need to remove this from the map since we've added the relationship
									subClassIDs.removeValue(otherConcept.id);
								} else if (isParent) {
									// Skip reverse arcs, bug #1108 ?
									//if (!isReverse) {
										// April 21st, 2009 - this is backwards - the relationship goes from
										// this node up to the parent, but the layouts need it to be from
										// the parent down to this node, so we invert the arrow
										
										// April 21st, 2010 - child -> parent relations by default are inverted
										// if there is a [R] present, then it actually goes parent -> child
										ontology.addRelationship(otherConcept, concept, true, relType, !isReverse);
									//}
									// need to remove this from the map since we've added the relationship
									superClassIDs.removeValue(otherConcept.id);
								} else {
									//ontology.addRelationship(otherConcept, concept, false, relType);
									ontology.addRelationship(concept, otherConcept, false, relType, isReverse);
								}
							}
						}
					}
				}
			}
				
			var parentIDs:Array = superClassIDs.keys;
			var leftOverParents:int = parentIDs.length; 
			if (leftOverParents > 0) {
				for (i = 0; i < leftOverParents; i++) {
					var parentID:String = String(parentIDs[i]);
					var parent:NCBOConcept = NCBOConcept(superClassIDs.removeValue(parentID));
					// add a relationship with the DEFAULT type - depends on OWL/OBO
					ontology.addRelationship(parent, concept, true);
				}
			}
			var childIDs:Array = subClassIDs.keys;
			var leftOverChildren:int = childIDs.length; 
			if (leftOverChildren > 0) {
				for (i = 0; i < leftOverChildren; i++) {
					var childID:String = String(childIDs[i]);
					var child:NCBOConcept = NCBOConcept(subClassIDs.removeValue(childID));
					// add a relationship with the DEFAULT type - depends on OWL/OBO
					ontology.addRelationship(concept, child, true);
				}
			}
		}
		
		private function parseTopLevelNodes(xml:XML, ontology:NCBOOntology, error:Error = null):NCBOConceptsEvent {
			// the pick out all the children of THING/owl:Thing
			var subClasses:Array = [];
			if (!error) {
				var list:XMLList = xml.data.classBean;
				if (list.length() == 1) {
					var subClassList:XMLList = list[0].relations.entry.list.classBean;
					for each (var classBean:XML in subClassList) {
						var concept:NCBOConcept = parseSingleConceptXML(classBean, ontology.id);
						if (concept) {
							subClasses.push(concept);
						}
					}
				}
			}
			ontology.topLevelNodes = subClasses;
			return new NCBOConceptsEvent(subClasses, "NCBOConceptsEvent", error, ontology.id);
		}
		
		private function getSubClassConceptIDs(xml:XML):Array {
			var ids:Array = [];
			var list:XMLList = xml.data.classBean;
			if (list.length() == 1) {
				var entries:XMLList = list[0].relations.entry;
				for each (var entryXML:XML in entries) {
					var type:String = entryXML.string;
					if (type == SUB_CLASS) {
						var subClassList:XMLList = entryXML.list.classBean;
						for each (var classBean:XML in subClassList) {
							var id:String = classBean.id;
							ids.push(id);
						}
						break;
					}
				}
			}
			return ids;
		}
		
		/**
		 * Parses an XMLList and puts the values into an array which is set as a concept property.
		 */
		private function setConceptProperty(concept:NCBOConcept, propertyName:String, entries:XMLList):void {
			var len:int = entries.length();
			if (len > 0) {
				var array:Array = new Array(len);
				var i:int = 0;
				for each (var xml:XML in entries) {
					var string:String = xml.toString();
					array[i++] = string;
				}
				if (array.length == 1) {
					concept.setProperty(propertyName, array[0]);
				} else {
					concept.setProperty(propertyName, array);
				}
			}
		}
		
		private function checkForReference(entry:XML, entries:XMLList):XML {
			var referenceEntry:XML = entry;
			var isReference:Boolean = (String(entry.list.@reference).length > 0);
			if (isReference) {
				// TODO references should be removed from the XML now, so this code is probably not needed
				// first need to check for a reference like: 
				/*<entry>
					<string>SubClass</string>
					<list reference="../../entry[2]/list"/>
				</entry>*/
				// Note that the reference index [2] is 1-based! And it omitted it means [1]
				var refXML:XMLList = entry.list.@reference;
				var reference:String = refXML.toString();
				var index:int = parseEntryReference(reference);
				if ((index >= 0) && (index < entries.length())) {
					referenceEntry = entries[index];
				}
			}
			return referenceEntry;
		}
		
		/**
		 * Parses a reference string like "../../entry[2]/list" to pull out the entry array index.
		 * The index value in the string is assumed to be 1-based (starting at 1), but it will be 
		 * returned zero-based.
		 * @param reference the reference string, containing the entry and the 1-based array index
		 * @return the entry array index (zero based!), or -1 if not found 
		 */
		private function parseEntryReference(reference:String):int {
			var index:int = -1;
			if (reference.length > 0) {
				// the reference will be like "../../entry[2]/list" OR 
				// we want to extract the "entry[2]" part
				var pattern:RegExp = /entry\[(\d+)\]?/;
				if (pattern.test(reference)) {
					// the result array will be: ["entry[2]", "[2]"] 
					var result:Array = pattern.exec(reference);
					if (result.length >= 2) {
						// the index we want is the second matched group
						var str:String = String(result[1]); 
						index = int(str);
					}
				} else {
					// special case, check for "../../entry/list" which is the same as "../../entry[1]/list"
					pattern = /entry\//;
					if (pattern.test(reference)) {
						// in this case we had a string like "../../entry/list", so we want the first index
						index = 1;
					}
				}
				// ** VERY IMPORTANT - the # in the reference string is not zero based, it starts at 1 **
				if (index > 0) {
					index--;
				}
			}
			return index;
		}
		
		private function parseRelationshipType(type:String):String {
			var relType:String = "";
			if (type.length > 0) {
				relType = type;
				// Strip out the reverse relationships like "[R]is_a"
				if (StringUtils.startsWith(type, "[R]")) {
					relType = type.substr(3);
				}
				//trace("Found relationship type: " + relType);
			}
			return relType;
		}
		
		/**
		 * Strips of the prefix "~#en " or any other language from the front of the string.
		 */
		private function stripLanguagePrefix(prop:String):String {
			if (StringUtils.startsWith(prop, "~#")) {
				prop = prop.substr(5);
			}
			return prop;
		}
		
		/**
		 * Parses the search results xml.
		 * The search results are just stubs - they only currently contain
		 * the ChildCount relation, and nothing else.
		 * E.g.
		 * <success><data>
		 *  <page>
		 * 		<pageNum>1</pageNum>
		 * 		<numPages>1</numPages>
		 * 		<pageSize>747</pageSize>
		 * 		<numResultsPage>747</numResultsPage>
		 * 		<numResultsTotal>747</numResultsTotal>
		 * 		<contents class="org.ncbo.stanford.bean.search.SearchResultListBean">
		 * 		  <searchResultList>
		 * 			<searchBean>
		 * 				<ontologyVersionId>29684</ontologyVersionId>
		 * 				<ontologyId>1089</ontologyId>
		 * 				<ontologyDisplayLabel>BIRNLex</ontologyDisplayLabel>
		 * 				<recordType>RECORD_TYPE_PREFERRED_NAME</recordType>
		 * 				<conceptId>http://bioontology.org/projects/ontologies/birnlex#birnlex_12</conceptId>
		 * 				<conceptIdShort>birnlex_12</conceptIdShort>
		 * 				<preferredName>Cell</preferredName>
		 * 				<contents>Cell</contents>
		 * 			</searchBean>
		 * 			...
		 * 		  </searchResultList>
		 * 		  <ontologyHitList>
		 * 			<ontologyHitBean>
		 *             <ontologyVersionId>38857</ontologyVersionId>
		 *             <ontologyId>1070</ontologyId>
		 *             <ontologyDisplayLabel>Biological process</ontologyDisplayLabel>
		 *             <numHits>52</numHits>
		 *           </ontologyHitBean>
		 *           ...
		 * 		  </ontologyHitList>
		 * 		</contents>
		 * 	</page>	
		 * </data></success>
		 */
		private function parseSearchResultsXML(xml:XML, searchParams:SearchParams, 
							parseHits:Boolean = true, error:Error = null):NCBOSearchEvent {
			if (error) {
				return new NCBOSearchEvent(null, null, searchParams, error);
			}

			// keep the order of the concepts the same as returned in the XML
			var allConcepts:Array = new Array();
			var ontologiesArray:Array = new Array();
			var ontologies:Object = new Object();
			var searchEvent:NCBOSearchEvent = new NCBOSearchEvent(allConcepts, ontologiesArray, searchParams);
			
			// if there are no search results, the <data/> tag will be empty
			if (xml.data.page.length() > 0) {
				// paging properties
				var page:XML = xml.data.page[0];
				searchEvent.pageNum = parseInt(String(page.pageNum), 10);
				searchEvent.numPages = parseInt(String(page.numPages), 10);
				searchEvent.pageSize = parseInt(String(page.pageSize), 10);
				searchEvent.numResultsPage = parseInt(String(page.numResultsPage), 10);
				searchEvent.numResultsTotal = parseInt(String(page.numResultsTotal), 10);
				
				var ontologyVersionID:String, ontologyID:String, ontologyName:String;
				var ontology:NCBOSearchResultOntology;
				
				var searchBeans:XMLList = page.contents.searchResultList.searchBean;
				if (searchBeans.length() >= 1) {
					for each (var searchBean:XML in searchBeans) {
						// ontology properties:
						ontologyVersionID = String(searchBean.ontologyVersionId);
						if (!ontologies.hasOwnProperty(ontologyVersionID)) {
							ontologyID = String(searchBean.ontologyId);
							ontologyName = String(searchBean.ontologyDisplayLabel);
							ontology = new NCBOSearchResultOntology(ontologyVersionID, ontologyID, ontologyName);
							// store the ontology by version id, it is the same as NCBOOntology.id
							ontologies[ontologyVersionID] = ontology;
							ontologiesArray.push(ontology);
						} else {
							ontology = NCBOSearchResultOntology(ontologies[ontologyVersionID]); 
						}
						
						// concept properties:
						var recordType:String = String(searchBean.recordType);
						var conceptID:String = String(searchBean.conceptId);
						var conceptIDShort:String = String(searchBean.conceptIdShort);
						if (conceptID.length > conceptIDShort.length) {
							// for some owl ontologies the conceptID is actually a full URL which is not 
							// what we want, we want just the simple id
							conceptID = conceptIDShort;
						}
						var prefName:String = String(searchBean.preferredName);
						var contents:String = String(searchBean.contents);
						var concept:NCBOSearchResultConcept = new NCBOSearchResultConcept(conceptID, prefName, 
													recordType, contents, ontology, searchParams.searchText);
						// check if the concept is allowed
						if (conceptFilter(concept)) {
							allConcepts.push(concept);
							// there is no point in storing the concepts inside the ontologies because
							// it creates a circular dependency which means it can't be saved to a SharedObject
							//ontology.addConcept(concept);
						} else {
							trace(concept.name + " is filtered from the search results");
						}
					}
				}
				
				if (parseHits) {
					var hitBeans:XMLList = page.contents.ontologyHitList.ontologyHitBean;
					/** Expects XML like:
					 * 	<ontologyHitBean>
					 *  	<ontologyVersionId>38587</ontologyVersionId>
					 *      <ontologyId>1115</ontologyId>
					 *      <ontologyDisplayLabel>Yeast phenotypes</ontologyDisplayLabel>
					 *      <numHits>3</numHits>
					 * 	</ontologyHitBean>...
					 */
					for each (var hitBean:XML in hitBeans) {
						ontologyVersionID = String(hitBean.ontologyVersionId);
						var numHits:int = parseInt(String(hitBean.numHits), 10);
						if (!ontologies.hasOwnProperty(ontologyVersionID)) {
							// add ontology, it's concepts must be paged out
							ontologyID = String(hitBean.ontologyId);
							ontologyName = String(hitBean.ontologyDisplayLabel);
							ontology = new NCBOSearchResultOntology(ontologyVersionID, ontologyID, ontologyName, numHits);
							ontologies[ontologyVersionID] = ontology;
							ontologiesArray.push(ontology);
						} else {
							// update the hits property
							ontology = NCBOSearchResultOntology(ontologies[ontologyVersionID]);
							ontology.hits = numHits;
						} 
					}
				}
			}
			ontologies = null;
			
			// save the number of hits (for previous searches)
			searchEvent.searchParams.results = allConcepts.length;
			
			return searchEvent;
		}
		
		private function conceptFilter(concept:Object):Boolean {
			var allow:Boolean = true;
			var name:String = "";
			if (concept is IConcept) {
				name = (concept as IConcept).name;
			} else if (concept is String) {
				name = (concept as String);
			} else {
				allow = false;
			}
			// remove all concepts like "owl:Thing", "owl:Nothing", "owl:Part", "THING"
			// and ":OWL-CLASS", ":CLASS", ":META-CLASS", ":SLOT", ":FACET"
			if (allow && (StringUtils.startsWith(name, "owl:") ||
						  StringUtils.equals(name, OntologyConstants.THING, true) ||  
						  StringUtils.startsWith(name, ":"))) {
				allow = false;
			}
			return allow;
		}
		
	}
}
	import org.ncbo.uvic.flex.OntologyConstants;
	

class ConceptID {
	
	public var id:String;
	public var childIDs:Array;
	
	public function ConceptID(id:String, childIDs:Array = null) {
		this.id = id;
		this.childIDs = (childIDs ? childIDs : []);
	}
	
	public function get subClassCount():uint {
		return childIDs.length;
	}
	
	public function toString():String {
		return prettyString();
	}
	
	private function prettyString(tabCount:int = 1):String {
		var str:String = id;
		if (childIDs.length > 0) {
			var tabs:String = "";
			for (var i:int = 0; i < tabCount; i++) {
				tabs += "   ";
			}
			if (tabs.length > 0) {
				tabs = tabs + "-> ";
			}
			for each (var child:ConceptID in childIDs) {
				str += "\n" + tabs + child.prettyString(tabCount+1);
			}
		}
		return str;
	}
	
	public function getPathFromRoot(endConceptID:String, includeRoot:Boolean = false):Array {
		var path:Array = [];
		buildPathFromRootRecursively(this, path, endConceptID);
		// remove owl:Thing or THING or :THING
		if (!includeRoot && (path.length >= 1)) {
			var root:String = path[0];
			if ((root == OntologyConstants.OWL_THING) || (root == OntologyConstants.THING) ||
				(root == OntologyConstants.THING2)) {
				path = path.slice(1);
			}
		}
		return path;
	}
	
	private static function buildPathFromRootRecursively(cid:ConceptID, path:Array, endConceptID:String):void {
		path.push(cid.id);
		if (cid.id == endConceptID) {
			return;
		}
		for each (var child:ConceptID in cid.childIDs) {
			if (child.subClassCount > 0) {
				buildPathFromRootRecursively(child, path, endConceptID);
			} else if (child.id == endConceptID) {
				path.push(child.id);
				break;
			}
		}
	}
	
}
