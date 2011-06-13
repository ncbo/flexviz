package org.ncbo.uvic.flex.logging
{
	import flash.errors.IOError;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.system.Capabilities;
	import flash.utils.getQualifiedClassName;
	
	import flex.utils.Utils;
	
	import mx.core.Application;
	import mx.messaging.ChannelSet;
	import mx.messaging.channels.AMFChannel;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.remoting.RemoteObject;
	
	import org.ncbo.uvic.flex.IRestService;
	import org.ncbo.uvic.flex.events.NCBOConceptEvent;
	import org.ncbo.uvic.flex.events.NCBOEvent;
	import org.ncbo.uvic.flex.events.NCBOLogEvent;
	import org.ncbo.uvic.flex.events.NCBOOntologyEvent;
	import org.ncbo.uvic.flex.events.NCBOSearchEvent;
	import org.ncbo.uvic.flex.model.IConcept;
	import org.ncbo.uvic.flex.model.IOntology;
	import org.ncbo.uvic.flex.model.NCBOSearchResultOntology;
	import org.ncbo.uvic.flex.search.SearchParams;
	
	//[Event(name="itemLogged", type="org.ncbo.uvic.flex.events.NCBOLogEvent")]
	
	public class LogService
	{
		
		//private static const ENDPOINT_URL:String = "http://localhost/amfphp/gateway.php";
		private static const ENDPOINT_URL:String = "http://keg.cs.uvic.ca/amfphp/gateway.php";
		private static const DESTINATION:String = "amfphp";
		private static const SERVICE:String = "ncbolog.LogService";
		private static const TYPE_INIT:String = "initialize";

		public static var LOG_ALL:Boolean = false;
		private static var LOG_STARTUP:Boolean = true;
		public static var LOG_CONCEPT:Boolean = true;
		private static var LOG_ONTOLOGY:Boolean = true;
		private static var LOG_SEARCH:Boolean = true;
		private static var LOG_NAVIGATION:Boolean = true;
		private static var LOG_ERROR:Boolean = true;
		private static var WAITING:Boolean = false;
		private static var WAITING_FUNCTIONS:Array = [];
		private static var APP_ID:String = "";
		private static var _channelSet:ChannelSet;
		private static var _remoteObject:RemoteObject;
		
		public static const dispatcher:EventDispatcher = new EventDispatcher();
		
		public static var restService:IRestService = null;
		
		private static var _domain:String;
		
		private static function debug(msg:String):void {
			//trace("[LOG] " + msg);
		}
		
		private static function error(functionName:String, msg:String):void {
			trace("[LOG] " + functionName + " error: " + msg);
		}
		
		public static function get domain():String {
			if (!_domain) {
				_domain = Utils.browserDomain;	
				if (!_domain) {
					_domain = Utils.domain;	// application domain
				}
			}
			return _domain;
		}
		
		public static function set domain(value:String):void {
			_domain = value;
		}
		
		private static function get channelSet():ChannelSet {
			if (_channelSet == null) {
				_channelSet = new ChannelSet();
				var channel:AMFChannel = new AMFChannel("my-amfphp", ENDPOINT_URL);
				_channelSet.addChannel(channel);
			}
			return _channelSet;
		}
				
		private static function get remoteObject():RemoteObject {
			if (_remoteObject == null) {
				_remoteObject = new RemoteObject(DESTINATION);
				_remoteObject.source = SERVICE;
				_remoteObject.channelSet = channelSet;		// don't need the services-config.xml file 
				_remoteObject.addEventListener(ResultEvent.RESULT, resultHandler);
				_remoteObject.addEventListener(FaultEvent.FAULT, faultHandler);
			}
			return _remoteObject;
		}
		
		private static function resultHandler(event:ResultEvent):void {
			var token:AsyncToken = event.token;
			var type:String = token.eventType;
			var result:Object = event.result;
			if (type == TYPE_INIT) {
				initializeHandler(result);
			} else {
				if (token.hasOwnProperty("callback")) {
					var callback:Function = (token.callback as Function);
					callback(result);
				} else {
					var str:String = "";
					if (result is Boolean) {
						//var b:Boolean = Boolean(result);
					} else if (result is Number) {
						//var n:Number = Number(result);
					} else if (result is String) {
						str = (result as String);
					} else if (result) {
						str = event.result.toString();
					}
					if (str.length > 0) {
						trace("[LOG_WARN] " + type + " result: " + str);
					}
				}
				// dispatch a log event after the callback has been called
				if (token.hasOwnProperty("logItem")) {
					var logItem:Object = token.logItem;
					if (logItem) {
						dispatcher.dispatchEvent(new NCBOLogEvent(NCBOLogEvent.ITEM_LOGGED, logItem));
					}
				}
			}
		}
		
		private static function faultHandler(event:FaultEvent):void {
			var token:AsyncToken = event.token;
			var type:String = token.eventType;
			var err:String;
			if (event.fault.faultString == "HTTP request error") {
				err = "Could not connect to the server.";
			} else {
				err = "Connection error: " + event.fault.faultString;
			}
	    	debug(type + " fault: " + err);
	    	
	    	if (token.hasOwnProperty("callback")) {
	    		var callback:Function = (token.callback as Function);
	    		callback(null, err);
	    	}
	    	
	    	// stop logging!
	    	LOG_ALL = false;
		}
		
		private static function initializeHandler(result:Object):void {
			WAITING = false;
			LOG_ALL = false;
			try {
				LOG_ALL = result.all;
				debug("Server responded, logging turned " + (LOG_ALL ? "on" : "off"));
				if (LOG_ALL) {
					LOG_STARTUP = result.startup;
					LOG_CONCEPT = result.concept;
					LOG_ONTOLOGY = result.ontology;
					LOG_SEARCH = result.search;
					LOG_NAVIGATION = result.navigation;
					LOG_ERROR = result.error;
					logStartupEvent();
				}
				resumeLogging();
			} catch (err:Error) {
				trace(err);
			}
			LOG_ALL = true;
		}
		
		public static function get isLogging():Boolean {
			return LOG_ALL;
		}
		
		public static function initialize(log:Boolean = true, appID:String = "", newDomain:String = ""):void {
			debug("Initializing logging (" + (log ? "on" : "off") + ")" + " for " + appID);
			LOG_ALL = log;
			var appIDChanged:Boolean = false;
			if ((appID != null) && (appID.length > 0) && (appID != APP_ID)) {
				APP_ID = appID;
				appIDChanged = true;
			}
			if (newDomain) {
				domain = newDomain;
			}
			
			if (LOG_ALL && appIDChanged) {
				try {
					// temporarily turn off logging until we get a result
					pauseLogging();
					var token:AsyncToken = remoteObject.isLogging(APP_ID);
					token.eventType = TYPE_INIT;
				} catch (ex:Error) {
					error("initialize", ex.message);
				}
			}
		}
		
		public static function logStartupEvent():void {
			if (APP_ID.length > 0) {
				if (WAITING) {
					callWhenReady(logStartupEvent);
				} else if (LOG_ALL && LOG_STARTUP) {
					try {
						var url:String = Application.application.url;
						var flashVersion:String = Capabilities.version;
						var os:String = Capabilities.os;
						var width:Number = Capabilities.screenResolutionX;
						var height:Number = Capabilities.screenResolutionY;
						
						debug("startup: '" + APP_ID + "', '" + url + "'");
						var token:AsyncToken = remoteObject.insertStartupEvent(APP_ID, url, flashVersion, os, width, height);
						token.eventType = "startup";
					} catch (ex:Error) {
						error("logStartupEvent", ex.message);
					}
				}
			}
		}
		
		public static function logRestServiceEvent(event:NCBOEvent):void {
			if (WAITING) {
				callWhenReady(logRestServiceEvent, arguments);
			} else if (LOG_ALL) {
				if (event is NCBOSearchEvent) {
					logSearch(NCBOSearchEvent(event));
				} else if (event is NCBOConceptEvent) {
					// this event will be handled by the back end logging service
					//logConceptEvent(NCBOConceptEvent(event));
				} else if (event is NCBOOntologyEvent) {
					// this event will be handled by the back end logging service
					//logOntologyEvent(NCBOOntologyEvent(event));
				}
			}
		}
		
		public static function logSearch(event:NCBOSearchEvent):void {
			if ((APP_ID.length > 0) && !event.isError && event.searchParams.isValid) {
				var params:SearchParams = event.searchParams;
				logSearch2(params.searchText, params.exactMatch, params.includeAttributes, event.serverTime,
						   event.concepts.length, params);
			}
		}
		
		public static function logSearch2(searchText:String, exactMatch:Boolean, includeAttributes:Boolean,
				searchTime:Number, results:Number, params:SearchParams = null):void {
			if ((APP_ID.length > 0) && (searchText.length >= 2)) {
				if (WAITING) {
					callWhenReady(logSearch2, arguments);
				} else if (LOG_ALL && LOG_SEARCH) {
					try {
						debug("search: '" + APP_ID + "', '" + searchText + "', " + results);
						var token:AsyncToken = remoteObject.insertSearchEvent(APP_ID, searchText, exactMatch, 
															includeAttributes, searchTime, results, params.ontologyIDsArray, domain);
						token.eventType = "search";
						token.logItem = params;
						// set the search event id
						if (params != null) {
							token.callback = function(result:Object, error:String = null):void {
								if (result is Number) {
									params.id = uint(Number(result));
								}
							};
						}
					} catch (ex:Error) {
						error("logSearch", ex.message);
					}
				}
			}
		}
		
		public static function logPreviousSearch(params:SearchParams):void {
			if ((APP_ID.length > 0) && (params.id > 0)) {
				if (WAITING) {
					callWhenReady(logPreviousSearch, arguments);
				} else if (LOG_ALL && LOG_SEARCH) {
					try {
						debug("previousSearch: " + params.id + " ('" + params.searchText + "')");
						var token:AsyncToken = remoteObject.insertPreviousSearchEvent(params.id);
						token.eventType = "previousSearch";
					} catch (ex:Error) {
						error("logPreviousSearch", ex.message);
					}
				}
			}
		}
		
		public static function logConceptEvent(concept:IConcept, virtualID:String = "", type:String = ""):void {
			if (concept) {
				logConceptEvent3(concept.id, concept.name, concept.ontologyVersionID, virtualID, type);
			}
		}
		
		public static function logConceptEvent2(event:NCBOConceptEvent, virtualID:String = "", type:String = ""):void {
			if (!event.isError && event.concept) {
				logConceptEvent3(event.concept.id, event.concept.name, event.concept.ontologyVersionID, virtualID, type);
			}
		}
		
		public static function logConceptEvent3(conceptID:String, conceptName:String = "", versionID:String = "", 
												virtualID:String = "", type:String = ""):void {
			if ((APP_ID.length > 0) && conceptID) {
				if (WAITING) {
					callWhenReady(logConceptEvent3, arguments);
				} else if (LOG_ALL && LOG_CONCEPT) {
					// load the virtual ontology id
					if (!virtualID && versionID && restService) {
						restService.getNCBOOntology(versionID, function(event:NCBOOntologyEvent):void {
							if (!event.isError && event.ontology && event.ontology.ontologyID) {
								logConceptEvent3(conceptID, conceptName, versionID, event.ontology.ontologyID, type);
							} else {
								logConceptEvent3(conceptID, conceptName, versionID, "0", type);
							}
						}, true, false);
					} else {
						if (!virtualID || isNaN(Number(virtualID))) {
							trace("logConcept: no ontology virtual id! " + virtualID);
						}
						try {
							debug("concept: '" + APP_ID + "', " + type + ", " + conceptID + ", '" + conceptName + "', " + 
									versionID + ", " + virtualID);
							var token:AsyncToken = remoteObject.insertConceptEvent(APP_ID, type, conceptID, conceptName, 
																					versionID, virtualID);
							token.eventType = "concept";
						} catch (ex:Error) {
							error("logConceptEvent", ex.message);
						}
					}
				}
			}
		}
		
		public static function logOntologyEvent(ontology:IOntology, type:String = ""):void {
			if (ontology) {
				logOntologyEvent3(ontology.id, ontology.name, ontology.ontologyID, type);
			}
		}
		
		public static function logOntologyEvent2(event:NCBOOntologyEvent, type:String = ""):void {
			if (!event.isError && event.ontology) {
				logOntologyEvent3(event.ontology.id, event.ontology.name, event.ontology.ontologyID, type);
			}
		}
		
		public static function logOntologyEvent3(ontologyVersionID:String, name:String = "", ontologyID:String = "", type:String = ""):void {
			if ((APP_ID.length > 0) && (ontologyVersionID || ontologyID)) {
				if (WAITING) {
					callWhenReady(logOntologyEvent3, arguments);
				} else if (LOG_ALL && LOG_ONTOLOGY) {
					if (ontologyVersionID && name && ontologyID) {
						try {
							debug("ontology: '" + APP_ID + "', " + type + ", " + ontologyVersionID + ", '" + name + "', " + ontologyID);
							var token:AsyncToken = remoteObject.insertOntologyEvent(APP_ID, type, ontologyVersionID, ontologyID, name);
							token.eventType = "ontology";
						} catch (ex:Error) {
							error("logOntologyEvent", ex.message);
						}
					} else if (restService) {
						// load the ontology details first
						if (!ontologyVersionID && ontologyID) {
							restService.getOntologyByVirtualID(ontologyID, function(event:NCBOOntologyEvent):void {
								logOntologyEvent2(event, type);
							}, false);
						} else if (ontologyVersionID) {
							restService.getNCBOOntology(ontologyVersionID, function(event:NCBOOntologyEvent):void {
								logOntologyEvent2(event, type);
							}, true, false);
						}
					}
				}
			}
		}
		
		public static function logNavigationEvent(versionID:String, virtualID:String, type:String, string:String = "", number:Number = 0):void {
			if ((APP_ID.length > 0) && type) {
				if (WAITING) {
					callWhenReady(logNavigationEvent, arguments);
				} else if (LOG_ALL && LOG_NAVIGATION) {
					if (!virtualID && versionID && restService) {
						restService.getNCBOOntology(versionID, function(event:NCBOOntologyEvent):void {
							if (!event.isError && event.ontology && event.ontology.ontologyID) {
								logNavigationEvent(versionID, event.ontology.ontologyID, type, string, number);
							} else {
								logNavigationEvent(versionID, "0", type, string, number);
							}
						}, true, false);
					} else {
						if (versionID && !virtualID || isNaN(Number(virtualID))) {
							trace("logNavigation: no ontology virtual id! " + virtualID);
						}				
						try {
							debug("navigation: '" + APP_ID + ", '" + type + "', " + versionID + "', '" + virtualID + "', '" + 
								  string + "', " + number);
							var token:AsyncToken = remoteObject.insertNavigationEvent(APP_ID, type, versionID, virtualID, string, number);
							token.eventType = "navigation";
						} catch (ex:Error) {
							error("logOntologyEvent", ex.message);
						}
					}
				}
			}
		} 
		
		public static function logError(err:Error):void {
			if ((APP_ID.length > 0) && err) {
				if (WAITING) {
					callWhenReady(logError, arguments);
				} else if (LOG_ALL && LOG_ERROR) {
					try {
						var name:String = "Error";
						var detail:String = null; // or do we want this? err.message;
						if (err is Fault) {
							var fault:Fault = Fault(err);
							name = fault.faultString;
							detail = fault.faultDetail;
							if (fault.rootCause is IOErrorEvent) {
								detail = (fault.rootCause as IOErrorEvent).text;
							}
						} else if (err is IOError) {
							var ioError:IOError = (err as IOError);
							name = ioError.name;
							detail = ioError.message;
						}
						if (detail != null) {
							debug("error: '" + APP_ID + "', '" + name + "', " + detail);
							var token:AsyncToken = remoteObject.insertErrorEvent(APP_ID, name, detail);
							token.eventType = "error";
						} else {
							debug("** " + getQualifiedClassName(err) + " - error not logged: " + err.toString());
						}
					} catch (ex:Error) {
						error("logError", ex.message);
					}
				}
			}
		}
				
		/**
		 * Get generic objects containing the ontology version ID, ontology ID, and ontology name.
		 * It only returns something if the search parameters contained ids.
		 */ 
		private static function getSearchResultOntologies(searchOntologies:Array):Array {
			var ontologies:Array = [];
			if (searchOntologies) {
				for each (var ontology:NCBOSearchResultOntology in searchOntologies) {
					var ontologyObject:Object = new Object();
					ontologyObject.versionID = ontology.ontologyVersionID;
					ontologyObject.ontologyID = ontology.ontologyID;
					ontologyObject.name = ontology.name;
					ontologies.push(ontologyObject);
				}
			}
			return ontologies;
		}
		
		private static function callWaitingFunctions():void {
			if (WAITING_FUNCTIONS.length > 0) {
				//trace("** Calling " + WAITING_FUNCTIONS.length + " waiting log functions");
				for (var i:int = 0; i < WAITING_FUNCTIONS.length; i++) {
					var obj:Object = WAITING_FUNCTIONS[i];
					// old way : (WAITING_FUNCTIONS[i] as Function);
					var func:Function = (obj["loadingFunction"] as Function);
					var args:Array = (obj["args"] as Array);
					if (args && (args.length > 0)) {
						func.apply(null, args);
					} else {
						func();
					}
				}
				WAITING_FUNCTIONS = [];
			}
		}
		
		private static function callWhenReady(func:Function, args:Array = null):void {
			var obj:Object = { loadingFunction: func, args: args };
			WAITING_FUNCTIONS.push(obj);
			//trace("Waiting functions: " + WAITING_FUNCTIONS.length);
		}
		
		public static function pauseLogging():void {
			WAITING = true;
		}
		
		public static function resumeLogging():void {
			WAITING = false;
			callWaitingFunctions();
		}


		public static function getRecentSearches(callback:Function, appID:String = "", excludeMine:Boolean = false,
										mustHaveResults:Boolean = true, max:Number = 10):void {
			// get twice as many search results to account for possible duplicates 
			var token:AsyncToken = remoteObject.getRecentSearchEvents(appID, excludeMine, mustHaveResults, max * 2, domain);
			token.eventType = "recentSearches";
			token.callback = function(result:Object, error:String = null):void {
				var searches:Array = null;
				if (result is Array) {
					searches = [];
					var results:Array = (result as Array);
					var seen:Object = {};
					// convert from objects into SearchParams, and remove duplicates
					for each (var search:Object in results) {
						var param:SearchParams = SearchParams.parse(search);
						var searchText:String = param.searchText.toLowerCase();
						if ((searchText.length > 0) && !seen.hasOwnProperty(searchText)) {
							searches.push(param);
							seen[searchText] = true;
						}
					}
					// remove extra searches
					if (searches.length > max) {
						searches = searches.slice(0, max - 1);
					}
				}
				callback(searches);
			};
		} 
		
		public static function getMostPopularSearches(callback:Function, appID:String = "", 
					excludeMine:Boolean = false, mustHaveResults:Boolean = true, max:Number = 10):void {
			var token:AsyncToken = remoteObject.getMostPopularSearchEvents(appID, excludeMine, mustHaveResults, max, domain);
			token.eventType = "mostPopularSearches";
			token.callback = function(result:Object, error:String = null):void {
				var searches:Array = null;
				if (result is Array) {
					searches = [];
					var results:Array = (result as Array);
					// convert from objects into SearchParams, and remove duplicates
					for each (var search:Object in results) {
						var param:SearchParams = SearchParams.parse(search);
						searches.push(param);
					}
				}
				callback(searches);
			};
		}

	}
}