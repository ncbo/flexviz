package service
{
	import events.AnnotateTextEvent;
	import events.OBSEvent;
	
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;
	
	import flex.utils.ArrayUtils;
	import flex.utils.StringUtils;
	
	import model.Annotation;
	import model.AnnotationContext;
	import model.AnnotationStats;
	import model.Concept;
	import model.Ontology;
	import model.Resource;
	import model.SemanticType;
	
	import mx.managers.CursorManager;
	import mx.messaging.messages.HTTPRequestMessage;
	import mx.rpc.AsyncToken;
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.utils.StringUtil;
	
	import org.ncbo.uvic.flex.NCBORestService;
	
	/**
	 * OBS Rest service implementation.
	 * 
	 * For Use Case #4 see:
	 * http://obs.bioontology.org/oba/OBA_v1.1_rest.html
	 * 
	 * For Use Case #2/3 see:
	 * http://obs.bioontology.org/obr/OBR_v1.2_rest.html
	 * 
	 * For Ontology Recommender see:
	 * http://obs.bioontology.org/oba/Recommender.html
	 * 
	 * @author Chris Callendar
	 * @date February 2009
	 */
	public class OBSRestService
	{
		
		private static const APP_ID_KEY:String = NCBORestService.APP_ID_KEY;
		private static const APIKEY:String = NCBORestService.APIKEY;
		public static const APP_ID:String = NCBORestService.APP_ID_OBS;
		public static const DEFAULT_APIKEY:String = NCBORestService.APIKEY_OBS;
		public static const EMAIL:String = "obs@uvic.ca";
		private static const DEFAULT_BASE_URL:String = "http://rest.bioontology.org/";
			// "http://stagerest.bioontology.org/resource_index";
			// http://rest.bioontology.org/resource_index
			// old one "http://ncbolabs-dev2.stanford.edu:8080/OBS_v1/obr";
		private static const RESOURCE_URL:String = "resource_index"; 
		private static const ANNOTATOR_URL:String = "obs"; 
			// internal: "http://ncbo-obs-stage1.stanford.edu/obs";
		
		private static const RECOMMENDER_URL:String = "http://ncbolabs-dev2.stanford.edu:8080/OBS_v1";
		
		private static const ANNOTATOR_TIMEOUT:int = 100;
		private static const RESOURCE_INDEX_TIMEOUT:int = 60;
		
		// valid ontology status number
		private static const STATUS_VALID:uint = 28;
		
		public static const RESULT_FORMAT_TXT:String 	= "text";
		public static const RESULT_FORMAT_XML:String 	= "xml";
		public static const RESULT_FORMAT_CSV:String 	= "tabDelimited";
		public static const RESULT_FORMAT_OWL:String 	= "owl";
		public static const RESULT_FORMAT_RDF:String 	= "rdf";

		
		private var appID:String = APP_ID;
		public var apikey:String = DEFAULT_APIKEY;
		private var _baseURL:String = DEFAULT_BASE_URL;
		
		private var _restCalls:Array;
		
		// cache
		private var mappingTypes:Array;
		private var semanticTypes:Array;
		private var annotatorOntologies:Array;
		private var resourceOntologies:Array;
		private var resources:Array;
		
		// cache
		private var ontologyCache:Object;
		private var conceptCache:Object;		// cached by ontologyID/conceptID
		private var resourceCache:Object;
		
		// for resolving concept xpath references
		private var currentAnnotationBeanList:XMLList;	 
		
		private var isAnnotator:Boolean = false;
		private var isRecommender:Boolean = false;
		
		public function OBSRestService(apikey:String, applicationID:String = null, baseServerURL:String = null) {
			if (apikey != null) {
				this.apikey = apikey;
			}
			if (applicationID != null) {
				this.appID = applicationID;
			}
			if (baseServerURL != null) {
				baseURL = baseServerURL;
			}
			conceptCache = new Object();
			ontologyCache = new Object();
			resourceCache = new Object();
			_restCalls = [];
		}
		
		public function get restCalls():Array {
			return _restCalls;
		}
		
		public function get baseURL():String {
			return _baseURL;
		}
		
		public function set baseURL(url:String):void {
			if (url) {
				if (url.charAt(url.length - 1) != "/") {
					url = url + "/"; 
				}
				if (!StringUtils.startsWith(url, "http://", true)) {
					url = "http://" + url;
				}
				_baseURL = url;
			} else {
				_baseURL = DEFAULT_BASE_URL;
			}
		}
						
		//////////////////////////////
		// Cache Functions
		//////////////////////////////

		public function clearOntologies():void {
			ontologyCache = new Object();
			annotatorOntologies = null;
			resourceOntologies = null;
		}
		
		public function clearConcepts():void {
			conceptCache = new Object();
		}

		public function get cachedResourceOntologies():Array {
			return resourceOntologies;
		}

		public function get cachedAnnotatorOntologies():Array {
			return annotatorOntologies;
		}
		
		public function get cachedMappingTypes():Array {
			return mappingTypes;
		}

		public function get cachedSemanticTypes():Array {
			return semanticTypes;
		}
		
		public function getCachedResource(id:String):Resource {
			if (id && resourceCache.hasOwnProperty(id)) {
				return (resourceCache[id] as Resource);
			} 
			return null;
		}
		
		public function getCachedConcept(fullID:String):Concept {
			if (fullID && conceptCache.hasOwnProperty(fullID)) {
				return (conceptCache[fullID] as Concept);
			}
			return null;
		}
		
		public function getCachedOntology(id:String):Ontology {
			if (id && ontologyCache.hasOwnProperty(id)) {
				return (ontologyCache[id] as Ontology);
			}
			return null;
		}
		

		public function get annotatorBaseURL():String {
			return baseURL + ANNOTATOR_URL;
		}

		public function get resourcesBaseURL():String {
			return baseURL + RESOURCE_URL;
		}
		
		public function get recommenderBaseURL():String {
			return RECOMMENDER_URL;
		}


		//////////////////////////////////
		// Private OBS Service Functions
		//////////////////////////////////

		private function getURL(suffix:String):String {
			var url:String = (isRecommender ? recommenderBaseURL :  
				(isAnnotator ? annotatorBaseURL : resourcesBaseURL)) + suffix;
			return url;
		}

		private function getService(url:String, timeout:int = 20 /*seconds*/):HTTPService {
			var svc:HTTPService = new HTTPService();
			svc.url = url;
			svc.resultFormat = HTTPService.RESULT_FORMAT_E4X;
			svc.method = HTTPRequestMessage.POST_METHOD;
			svc.headers["Pragma"] = "no-cache";
			svc.headers["Cache-Control"] = "no-cache";
			svc.headers[APP_ID_KEY] = appID;
			svc.headers[APIKEY] = apikey;
			svc.headers["email"] = EMAIL;
			svc.requestTimeout = timeout;	// in seconds 
			svc.addEventListener(ResultEvent.RESULT, resultHandler);
			svc.addEventListener(FaultEvent.FAULT, faultHandler);
			return svc;
		}
		
		private function send(suffix:String, xmlHandler:Function, callback:Function, 
				resultEvent:OBSEvent, params:Object = null, postAppID:Boolean = true, timeout:int = 20):void {
			CursorManager.setBusyCursor();
			
			var url:String = getURL(suffix);
			isAnnotator = false;
			isRecommender = false;
			 
			// send an app id for stat tracking purposes
			if (postAppID) {
				// use POST parameter
				if (params == null) {
					params = new Object();
					params[APP_ID_KEY] = appID;
					params[APIKEY] = apikey;
				} else { 
					if (params.hasOwnProperty(APP_ID_KEY)) {
						params[APP_ID_KEY] = appID;
					} else {
						trace("WARNING - " + getQualifiedClassName(params) + " doesn't have the property " + APP_ID_KEY);
					}
					if (params.hasOwnProperty(APIKEY)) {
						params[APIKEY] = apikey;
					} else {
						trace("WARNING - " + getQualifiedClassName(params) + " doesn't have the property " + APIKEY);
					}
				}
			} else {
				// use GET parameter
				url = StringUtils.addURLParameter(url, APP_ID_KEY, appID);
				url = StringUtils.addURLParameter(url, APIKEY, apikey);
				url = StringUtils.addURLParameter(url, "email", EMAIL);
			}
			
			var svc:HTTPService = getService(url, timeout);
			trace("[REST] " + svc.url + (params != null ? " [params: " + ArrayUtils.mapToQueryString(params) + "]" : ""));
			if (_restCalls.length > 30) {
				_restCalls.shift();		// remove the first element
			}
			_restCalls.push(url);	// add to the end of the array
			
			var startTime:int = getTimer();
			var token:AsyncToken = svc.send(params);
			token.startTime = startTime;
			token.xmlHandler = xmlHandler;
			token.callback = callback;
			token.resultEvent = resultEvent;
			token.url = url;
		}
		
		private function postToNewWindow(suffix:String, vars:URLVariables, window:String = "_BLANK"):void {
			var url:String = getURL(suffix);
			isAnnotator = false;
			isRecommender = false;
			
			var request:URLRequest = new URLRequest(url);
			request.data = vars;
			request.method = URLRequestMethod.POST;
			navigateToURL(request, window);
		} 
				
		private function resultHandler(event:ResultEvent):void {
			CursorManager.removeBusyCursor();

			var token:AsyncToken = event.token;
			var startTime:int = int(token.startTime);
			var startParse:int = getTimer();
			var resultEvent:OBSEvent = (token.resultEvent as OBSEvent);
			resultEvent.serverTime = (startParse - startTime);
			var callback:Function = (token.callback as Function);
			var xmlHandler:Function = (token.xmlHandler as Function);
			var xml:XML = null;
			if (event.result is XML) {
				xml = (event.result as XML);
			} else {
				try {
					xml = XML(event.result);
				} catch (error:Error) {
					resultEvent.errorMessage = error.message;
				}
			}
			if (xml != null) {
				// check for error xml
				if (xml.nodeKind() == "text") {
					resultEvent.errorMessage = xml.toString().substr(0, 50);
				} else {
					xmlHandler(xml, resultEvent);
				}
			} else if (!resultEvent.isError) {
				resultEvent.errorMessage = "Resulting XML is null";
			}
			
			// June 28th - currently the service returns XML that is actually just plain text like
			/*
			1	National Drug File - Reference Terminology Public Inferred Edition, 2008_03_11	NDFRT
			2	ICPC2 - ICD10 Thesaurus, 200412	ICPC2ICD10ENG
			3	Human disease	40465 ...

			So it shows up incorrectly as an error.
			*/
			
			resultEvent.parseTime = (getTimer() - startParse);
			callback(resultEvent);
		}
		
		private function faultHandler(event:FaultEvent):void {
			var fault:Fault = event.fault;
			trace("Fault: " + fault);
			CursorManager.removeBusyCursor();
			
			var token:AsyncToken = event.token;
			var startTime:int = int(token.startTime);
			var resultEvent:OBSEvent = (token.resultEvent as OBSEvent);
			resultEvent.serverTime = (getTimer() - startTime);
			resultEvent.fault = fault;
	
			// Special handling for when an individual ontology can't be loaded
			var isStreamError:Boolean = (fault.message.indexOf("Stream Error.") != -1);
			if (isStreamError) {
				var url:String = token.url;
				var qm:int = url.indexOf("?");
				if (qm > 0) {
					url = url.substr(0, qm);
				}
				var regex:RegExp = /ontologies\/(.+)$/;
				var match:Array = url.match(regex);
				if (match != null) {
					var ontID:String = match[1];
					trace("Ontology " + ontID + " was not found");
					resultEvent.errorMessage = "Error: ontology not found for localOntologyId " + ontID;
				}
			}

			var callback:Function = (token.callback as Function);
			callback(resultEvent);
		}
				
		/**
		 * Returns a resource from the cache, or null if not loaded yet.
		 */
		public function getResource(id:String):Resource {
			if (resources != null) {
				for each (var res:Resource in resources) {
					if (res.id == id) {
						return res;
					}
				}
			}
			return null;
		}
		
		
		//////////////////////////////
		// OBS Service Functions
		//////////////////////////////
		
		/**
		 * Returns the ontologies from the new annotator service (for use case #4).
		 */
		public function getAnnotatorOntologies(callback:Function):void {
			var resultEvent:OBSEvent = new OBSEvent(OBSEvent.ONTOLOGIES);
			if (annotatorOntologies != null) {
				resultEvent.items = annotatorOntologies;
				callback(resultEvent);
			} else {
				// IMPORTANT - send the app ID parameter using GET, not POST
				// the ontologies service only allows GET requests
				isAnnotator = true;
				send("/ontologies", parseAnnotatorOntologies, callback, resultEvent, null, false/* postAppID */);
			}
		}
		
		/**
		 * Looks up one ontology from the new annotator service.
		 */
		public function getAnnotatorOntology(versionID:String, callback:Function):void {
			var resultEvent:OBSEvent = new OBSEvent(OBSEvent.ONTOLOGIES);
			/*var ontology:Ontology = getCachedOntology(versionID);
			if (ontology != null) {
				resultEvent.items = [ ontology ];
				callback(resultEvent);
			} else { */
				// IMPORTANT - send the app ID parameter using GET, not POST
				// the ontologies service only allows GET requests
				isAnnotator = true;
				send("/ontologies/" + versionID, parseAnnotatorOntology, callback, resultEvent, null, false/* postAppID */);
			//}
		}
		
		/**
		 * Returns the resuorce ontologies.
		 */
		public function getResourceOntologies(callback:Function):void {
			var resultEvent:OBSEvent = new OBSEvent(OBSEvent.ONTOLOGIES);
			if (resourceOntologies != null) {
				resultEvent.items = resourceOntologies;
				callback(resultEvent);
			} else {
				// IMPORTANT - send the app ID parameter using GET, not POST
				// the ontologies service only allows GET requests
				// March 23rd - was "/obs/ontologies"
				send("/ontologies", parseResourceOntologies, callback, resultEvent, null, 
					false/* postAppID */, 30);
			}
		}
		
		public function getSemanticTypes(callback:Function):void {
			var resultEvent:OBSEvent = new OBSEvent(OBSEvent.SEMANTIC_TYPES);
			if (semanticTypes != null) {
				resultEvent.items = semanticTypes;
				callback(resultEvent);
			} else {
				
				// JULY 2009 - Semantic Types are taking too long to load (timeout)
				// so load them from a static hardcoded file for now
//				var startParse:int = getTimer();
//				parseSemanticTypes(SemanticTypesXML.SEMANTIC_TYPES, resultEvent);
//				resultEvent.parseTime = getTimer() - startParse;
//				resultEvent.serverTime = 0;
//				trace("Warning - loaded hardcoded semantic types (" + resultEvent.parseTime + "ms)");
//				callback(resultEvent);
				
				// IMPORTANT - send the app ID parameter using GET, not POST
				// the ontologies service only allows GET requests
				isAnnotator = true;
				send("/semanticTypes", parseSemanticTypes, callback, resultEvent, null, false/* postAppID */);
			}
		}
		
		public function getMappingTypes(callback:Function):void {
			var resultEvent:OBSEvent = new OBSEvent(OBSEvent.MAPPING_TYPES);
			if (mappingTypes != null) {
				resultEvent.items = mappingTypes;
				callback(resultEvent);
			} else {
				// IMPORTANT - send the app ID parameter using GET, not POST
				// the ontologies service only allows GET requests
				isAnnotator = true;
				send("/mappingTypes", parseMappingTypes, callback, resultEvent, null, false/* postAppID */);
			}
		}
		
		public function getResources(callback:Function):void {
			var resultEvent:OBSEvent = new OBSEvent(OBSEvent.RESOURCES);
			if (resources != null) {
				resultEvent.items = resources;
				callback(resultEvent);
			} else {
				send("/resources", parseResources, callback, resultEvent);
			}
		}
		
		public function getResourceDetails(resourceID:String, callback:Function):void {
			var resultEvent:OBSEvent = new OBSEvent(OBSEvent.RESOURCES);
			// try to find it in the list of previously loaded resources
			if (resources != null) {
				for (var i:int = 0; i < resources.length; i++) {
					var resource:Resource = (resources[i] as Resource);
					if (resource.id == resourceID) {
						resultEvent.items.push(resource);
						break;
					}
				}
			}
			if (resultEvent.items.length == 0) {
				send("/resources/" + resourceID, parseResources, callback, resultEvent);
			} else {
				callback(resultEvent);
			}
		}
		
		public function annotateText(parameters:AnnotatorParameters, callback:Function):void {
			isAnnotator = true;
			send("/annotator", parseAnnotateTextResult, callback, 
				new AnnotateTextEvent(null, parameters), parameters, true, ANNOTATOR_TIMEOUT);
		}
		
		/**
		 * Perform another annotator query, but open the results in a new browser window, posting the parameters.
		 */
		public function annotateTextInNewWindow(vars:URLVariables, window:String = "_BLANK"):void {
			isAnnotator = true;
			postToNewWindow("/annotator", vars, window);
		}
		
		// TESTING
		public function annotateTextTest(callback:Function):void {
			var params:Object = {};
			params.format = "asXML";
			params.levelMax = 0;
			params.longestOnly = false;
			params.mappingTypes = null;
			params.ontologiesToExpand = "";
			params.ontologiesToKeepInResult = "";
			params.scored = true;
			params.semanticTypes = "";
			params.textToAnnotate = "melanoma";
			params.wholeWordOnly = true;
			params.stopWords = "";
			params.withDefaultStopWords = false;
			isAnnotator = true;
			send("/annotator", parseAnnotateTextResult, callback, 
				new AnnotateTextEvent(null, new AnnotatorParameters()),	params, true, ANNOTATOR_TIMEOUT);
		}
		
		// TODO the XML has been updated, but since this method doesn't get called 
		// it hasn't been updated yet
//		public function getAnnotationsForConcept(ontologyID:String, conceptID:String, resourceID:String, 
//									callback:Function, withContext:Boolean = true, counts:Boolean = false, 
//									offset:int = 1, limit:int = 10, params:Object = null):void {
//			var resultEvent:OBSEvent = new OBSEvent(OBSEvent.ANNOTATIONS_FOR_CONCEPT);
//			var url:String = StringUtil.substitute("/byconcept/{0}/{1}/{2}/{3}/{4}/{5}?conceptid={6}", 
//							ontologyID, resourceID, withContext, counts, offset, limit, encodeURIComponent(conceptID));
//			send(url, parseAnnotationsForConcept, callback, resultEvent, params, true, RESOURCE_INDEX_TIMEOUT); 
//		}
				
		public function getAnnotationsForResourceElement(callback:Function, params:ResourceIndexParameters):void {
			var resultEvent:OBSEvent = new OBSEvent(OBSEvent.ANNOTATIONS_FOR_ELEMENT);
			// modify the parameters
			params.withContext = false;
			// for the statistics (just the number of annotations)
			params.counts = true;
			send("/", parseAnnotationsForResourceElement, callback, resultEvent, params, true, RESOURCE_INDEX_TIMEOUT);
		}
		
		/**
		 * Perform another resource_index query, but open the results in a new browser window by posting the variables.
		 */
		public function getAnnotationsForResourceElementInNewWindow(vars:URLVariables, window:String = "_BLANK"):void {
			postToNewWindow("/", vars, window);
		}
		
		public function getAnnotationStatisticsForResourceElement(callback:Function, params:ResourceIndexParameters):void {
			var resultEvent:OBSEvent = new OBSEvent(OBSEvent.ANNOTATION_STATS_FOR_ELEMENT);
			
			var url:String = StringUtil.substitute("/byelement/{0}/true/true/true/0/0?elementid={1}", params.resourceids, encodeURIComponent(params.elementid));  
			if (params.resourceids.indexOf(",") != -1) {
				trace("WARNING - resourceids is plural now, the following call probably won't work if multiple resources are selected");
			}
			trace(url);
			send(url, parseAnnotationStatisticsForResourceElement, callback, resultEvent, params);
		}
		
		public function getDetailedAnnotation(elementID:String, ontologyID:String, conceptID:String, 
											  resourceID:String, callback:Function):void {
			var resultEvent:OBSEvent = new OBSEvent(OBSEvent.ANNOTATION_DETAILS);
			var url:String = StringUtil.substitute("/details/false/concept/{0}/resource/{1}?elementid={2}&conceptid={3}", 
							 			ontologyID, resourceID, encodeURIComponent(elementID), encodeURIComponent(conceptID));
			send(url, parseDetailedAnnotation, callback, resultEvent);
		}
		
		public function getAnnotationsForConcepts(callback:Function, params:Object):void {
			var resultEvent:OBSEvent = new OBSEvent(OBSEvent.ANNOTATIONS_FOR_CONCEPTS);
			send("/", parseAnnotationsForConcepts, callback, resultEvent, params); 
		}
		
		public function getOntologyRecommendations(callback:Function, params:Object):void {
			var resultEvent:OBSEvent = new OBSEvent(OBSEvent.ONTOLOGY_RECOMMENDATIONS);
			isRecommender = true;
			send("/recommender1.1/", parseOntologyRecommendations, callback, resultEvent, params);
		}
		
		///////////////////////////
		// XML Parser Functions
		///////////////////////////
		
		/**
		 * Parses the semantic types XML like:
		 * <data><list>
		 * 	 <semanticTypeBean>
		 * 		<id>2</id>
		 * 		<semanticType>T998</semanticType>
		 * 		<description>Jax Mouse/Human Gene dictionary concept</description>
		 * 	</semanticTypeBean>
		 *  ...
		 * </list>
		 */
		private function parseSemanticTypes(xml:XML, event:OBSEvent):void {
			this.semanticTypes = [];
			if (xml != null) {
				// NEW annotator service
				var list:XMLList = xml.data.list.elements("semanticTypeBean");
				if (list.length() == 0) {
					// Older annotator service
					list = xml.data.list.elements("object-array");
				}
				if (list.length() == 0) {
					// Old dev service
					list = xml.elements("string-array");
				}
				for each (var bean:XML in list) {
					// March 2010 - semantic types are now in bean form with description
					//var id:String = bean.id;	// not important
					var id:String = bean.semanticType;
					var name:String = bean.description;
					if (!name) { 
						// August 2009 - Annotator update
						var strings:XMLList = bean.elements("string");
						// Old Annotator way
						if (strings.length() == 0) {
							strings = bean.elements("stopword");
						}					
						if (strings.length() >= 2) {
							id = strings[0];	// T000, etc
							name = strings[1];
						}
					}
					if (name) {
						semanticTypes.push(new SemanticType(id, name));
					} else {
						trace("Warning - unable to parse semantic type"); 
						break;
					}
				}
			}
			semanticTypes.sortOn("name", Array.CASEINSENSITIVE);	// or by type?
			event.items = semanticTypes;
		}
		
		/**
		 * Parses the annotator ontologies XML like:
		 * <data><list>
		 * 	<ontologyBean>
		 * 		<localOntologyID>13323</localOntologyID>
		 * 		<ontologyName>Mouse gross anatomy and development</ontologyName>
		 * 		<ontologyVersion>1.2</ontologyVersion>
		 * 	</ontologyBean>
		 * 	...
		 * </list></data>
		 */
		private function parseAnnotatorOntologies(xml:XML, event:OBSEvent):void {
			this.annotatorOntologies = [];
			if (xml != null) {
				// NEW annotator service
				var list:XMLList = xml.data.list.ontologyBean;
				for each (var bean:XML in list) {
					var ontology:Ontology = parseOntology(bean);
					if (ontology) {
						annotatorOntologies.push(ontology);
					}
				}
			}
			event.items = annotatorOntologies;
		}
				
		/**
		 * Parses an annotator ontology XML like:
		 * <data>
		 * 	<ontologyBean>
		 * 		<localOntologyID>13323</localOntologyID>
		 * 		<ontologyName>Mouse gross anatomy and development</ontologyName>
		 * 		<ontologyVersion>1.2</ontologyVersion>
		 * 	</ontologyBean>
		 * </data>
		 */
		private function parseAnnotatorOntology(xml:XML, event:OBSEvent):void {
			if (xml != null) {
				var list:XMLList = xml.data.ontologyBean;
				if (list.length() == 1) {
					var ontology:Ontology = parseOntology(list[0]);
					if (ontology) {
						event.items = [ ontology ];
					}
				} else if (xml.name() == "errorStatus") {
					event.errorMessage = xml.longMessage.text();					
				}
			}
		}

		/**
		 * Parses the resource index ontologies XML like:
		 * <success><data><set>
		 * 	<obrOntologyBean>
		 * 		<localOntologyID>13323</localOntologyID>
		 * 		<ontologyName>Mouse gross anatomy and development</ontologyName>
		 * 		<ontologyVersion>1.2</ontologyVersion>
		 * 	</obrOntologyBean>
		 * 	...
		 * </set></data></success>
		 */
		private function parseResourceOntologies(xml:XML, event:OBSEvent):void {
			this.resourceOntologies = [];
			if (xml != null) {
				// August 2010 - new xml structure to be more consisten
				var list:XMLList = xml.data.set.ontology;
				if (list.length() == 0) {
					list = xml.data.set.obrOntologyBean;
				}
				if (list.length() == 0) {
					// OLD dev service
					list = xml.elements("obs.common.beans.ObrOntologyBean");
				}
				for each (var bean:XML in list) {
					var ontology:Ontology = parseOntology(bean);
					if (ontology) {
						resourceOntologies.push(ontology);
					}
				}
			}
			event.items = resourceOntologies;
		}
		
		/**
		 * Parses ontology XML and returns an Ontology object.
		 * Expected child elements of the bean: localOntologyID, ontologyName, ontologyVersion, virtualOntologyID
		 * Optional child elements: nbAnnotation, score, normalizedScore, overlap, nbAnnotatingConcept (all numbers)
		 */
		private function parseOntology(bean:XML):Ontology {
			var ontology:Ontology = null;
			var id:String = bean.localOntologyId;
			if (id.length == 0) {
				id = bean.localOntologyID;
			}
			if (ontologyCache.hasOwnProperty(id)) {
				ontology = (ontologyCache[id] as Ontology);
			} else {
				var name:String = bean.name;
				if (name.length == 0) {
					name = bean.ontologyName;	// old way (as of Jan 5th 2009), still used in resource ontologies
				}
				var version:String = bean.version;
				if (version.length == 0) {
					version = bean.ontologyVersion;	// old way
				}
				var nbAnnotations:int = parseBeanNumber(bean, "annotationCount");
				if (nbAnnotations == 0) {
					nbAnnotations = parseBeanNumber(bean, "nbAnnotation");
				}
				var virtualID:String = bean.virtualOntologyId;
				if (virtualID.length == 0) {
					virtualID = bean.virtualOntologyID;
				}
				
				
				// only allow ontologies with a status value of 28, or NaN (meaning no status tag) 
				var status:Number = parseBeanNumber(bean, "status", NaN);
				if ((status == STATUS_VALID) || isNaN(status)) { 
					ontology = new Ontology(id, name, version, nbAnnotations, virtualID);
					ontologyCache[id] = ontology;
					
					// other properties
					var format:String = bean.format;
					ontology.setProperty("format", format);
					var description:String = bean.description;
					ontology.setProperty("description", description);

					// not supported yet, but will be soon?  (March 2010)
					var abbrev:String = bean.abbreviation;
					ontology.abbreviation = abbrev;

					// only for the ontology recommended service - these values can change each call!
					ontology.score = parseBeanNumber(bean, "score");	// annotator too?
					ontology.numAnnotatingConcepts = parseBeanNumber(bean, "nbAnnotatingConcept");
					ontology.normalizedScore = parseBeanNumber(bean, "normalizedScore");
					ontology.overlap = parseBeanNumber(bean, "overlap");

				} else {
					trace("Ontology '" + name + "' has an invalid status: " + status + ", id=" + id);
				}		
			}

//			trace(ontology.nameAndID + ": score=" + ontology.score + ", norm=" + ontology.normalizedScore + 
//				", overlap=" + ontology.overlap);

			return ontology;
		}
		
		/** Parses a number from the xml bean with the given name. */
		private function parseBeanNumber(bean:XML, name:String, defaultValue:Number = 0):Number {
			var num:Number = defaultValue;
			if (bean.elements(name).length() == 1) {
				var value:Number = Number(bean.elements(name)[0].toString());
				if (!isNaN(value)) {
					num = value;
				}
			}
			return num;
		}
		
		/**
		 * Parses the mapping types XML like:
		 * <success><data>
		 *  <list>
		 * 		<stopword>from-mrrel</stopword>
		 * 		<stopword>Human</stopword>
		 * 		<stopword>inter-cui</stopword>
		 * 	</list>
		 * </data></success>
		 */
		private function parseMappingTypes(xml:XML, event:OBSEvent):void {
			this.mappingTypes = [];
			if (xml != null) {
				// NEW annotator service
				// August 2009 - changed back to string
				var list:XMLList = xml.data.list.string;
				// Original annotator
				if (list.length() == 0) {
					list = xml.data.list.stopword;
				}
				if (list.length() == 0) {
					// OLD dev service
					list = xml.elements("string");
				}
				for each (var type:XML in list) {
					mappingTypes.push(type.toString());
				}
				event.items = mappingTypes;
			}
		}
		
		/**
		 * Parse xml like this:
		 * <success><data><set><resource>
		 * 	<resourceName>Research crossroads</resourceName>
		 * 	<resourceId>RXRD</resourceId>
		 * 	<resourceStructure>...</resourceStructure>
		 * 	<resourceURL>http://www.researchcrossroads.org/</resourceURL>
		 * 	<resourceElementURL>
		 * 		http://www.researchcrossroads.org/index.php?view=article&id=50%3Agrant-details&grant_id=
		 * 	</resourceElementURL>
		 * 	<resourceDescription>
		 * 		Centralizing scientific and medical funding data so that researchers gain recognition for their work and funders make better investments.
		 * 	</resourceDescription>
		 * 	<resourceLogo>
		 * 		http://www.innolyst.com/images/stories/InnolystImages/researchcrossroads - final.jpg
		 * 	</resourceLogo>
		 * </resource>...
		 */
		private function parseResources(xml:XML, event:OBSEvent):void {
			this.resources = [];
			this.resourceCache = new Object();
			if (xml != null) {
				// this happens when all resources are asked for
				// New xml structure as of August 2010
				var list:XMLList = xml.data.set.resource;
				if (list.length() == 0) {
					// check for a single resource
					list = xml.data.resource;
				}
				// old naming
				if (list.length() == 0) { 
					list = xml.elements("obs.obr.populate.Resource");
				}
				if (list.length() == 0) {
					// check single resource, old way
					if (xml.name() == "obs.obr.populate.Resource") {
						var singleResource:Resource = parseResource(xml);
						resources.push(singleResource);
					}
				} else {
					for each (var res:XML in list) {
						var resource:Resource = parseResource(res);
						resources.push(resource);
					}
					resources.sortOn("id", Array.CASEINSENSITIVE);
				}
				event.items = resources;
			}
		}
		
		/**
		 * Parses a single resource from XML.
		 */
		private function parseResource(res:XML):Resource {
			var resource:Resource = null;
			var name:String = res.resourceName;
			var id:String = res.resourceId;
			if (id.length == 0) {
				id = res.resourceID;	// previous verions
			}
			if (resourceCache.hasOwnProperty(id)) {
				resource = (resourceCache[id] as Resource);
			} else {
				//var structure:XMLList = res.resourceStructure;
				var url:String = res.resourceURL;
				// Old way - use the resource url defined in the XML
				//var oldElementURL:String = res.resourceElementURL;
				// New way (sep2010) - use a predefined url like http://rest.bioontology.org/resource_index/element/{resourceid}?elementid={elementid}
				var elementURL:String = getURL("/element/" + encodeURIComponent(id) + "?elementid=");
				var desc:String = res.resourceDescription; 
				var logo:String = res.resourceLogo;
				var mainContext:String = res.mainContext;
				resource = new Resource(id, name, url, elementURL, desc, logo, mainContext);
				resourceCache[id] = resource;
			}
			return resource;
		}
		
		/**
		 * Parses the concept XML like:
		 * <concept>
		 * 		<localConceptID>38802/NCBITaxon:32011</localConceptID>
		 * 		<preferredName>Methylophilaceae</preferredName> 
		 * 		<isTopLevel>false</isTopLevel> 
		 * 		<localOntologyID>38802</localOntologyID> 
		 * 		<synonyms>
		 * 			<string>'Methylophilaceae'</string>...
		 * 		</synonyms>
		 * 		<localSemanticTypeIDs>
		 * 			<string>T999</string>... 
		 * 		</localSemanticTypeIDs>
		 * 	</concept>
		 */
		private function parseConcept(bean:XML):Concept {
			var concept:Concept = null;
			if (bean != null) {
				// check for XPath reference
				var beanRef:String = String(bean.@reference);
				if ((beanRef.length > 0) && currentAnnotationBeanList) {
					// concept reference - use the currentAnnotationBeanList XMLList to lookup the concept
					// will be like ""../../obs.common.beans.ObrAnnotationBean/concept" - meaning the first concept
					// or "../../obs.common.beans.ObrAnnotationBean[4]/concept" - meaning the 4th concept in the list
					var beanIndex:int = 0;
					var regexp:RegExp = /\[(\d+)\]/;
					var result:Object = regexp.exec(beanRef);
					if (result) {
						var num:Number = result[1];	// result[0] is the full string "[4]"
						if (!isNaN(num)) {
							beanIndex = num - 1;
						}
					}
					if ((beanIndex >= 0) && (beanIndex < currentAnnotationBeanList.length())) {
						// get the actual concept XML from the referenced annotation bean 
						var annotationBean:XML = currentAnnotationBeanList[beanIndex]; 
						bean = firstChild(annotationBean.concept);
					}
				}
				
				// this id contains the ontology ID and the concept ID
				var id:String = bean.localConceptId;
				if (id.length == 0) {
					id = bean.localConceptID;	// (August 2009) previous versions
				}
				if (id.length > 0) {
					if (conceptCache.hasOwnProperty(id)) {
						concept = (conceptCache[id] as Concept);
					} else {
						var name:String = bean.preferredName;
						var isTopLevel:Boolean = bean.isTopLevel;
						var ontologyID:String = bean.localOntologyId;
						if (ontologyID.length == 0) {
							ontologyID = bean.localOntologyID;	// (August 2009) previous versions
						}
						var synonyms:Array = [];
						for each (var synXML:XML in bean.synonyms.string) {
							synonyms.push(synXML.toString());
						}
						var semanticTypes:Array = [];
						// OLD?
						for each (var oldSemXML:XML in bean.localSemanticTypeIDs.string) {
							semanticTypes.push(oldSemXML.toString());
						}
						for each (var semXML:XML in bean.semanticTypes.semanticTypeBean) {
							var type:String = semXML.localSemanticTypeId.text();
							//var conceptId:String = semXML.conceptId;
							//var name:String = firstChild(semXML.elements("name"));
							semanticTypes.push(type);
						}

						concept = new Concept(id, name, isTopLevel, ontologyID, synonyms, semanticTypes);
						// save for later
						conceptCache[id] = concept;
						
						// try loading the ontology from the cache
						concept.ontology = getCachedOntology(concept.ontologyID);
					}
				}
			}
			return concept;
		}
		
		/**
		 * Parses the context from the XML.
		 * For Mgrep annotations the XML looks like this:
		 * <context class="obs.common.beans.MgrepContextBean">
		 *   <contextName>MGREP</contextName>
		 *   <isDirect>true</isDirect>
		 *   <term>
		 * 		<name>Melanoma</name>
		 * 		<localConceptId>MDR/C0025202</localConceptId>
		 * 		<isPreferred>1</isPreferred>
		 * 		<dictionaryId>1</dictionaryId>
             </term>
		 *   <from>2</from>
		 *   <to>19</to>
		 * </context>
		 * 
		 * For Mapping annotations the XML looks like this:
		 * <context class="obs.common.beans.MappingContextBean">
		 *   <contextName>MAPPING</contextName>
		 *   <isDirect>false</isDirect>
		 *   <mappedConceptId>NCI/C0025202</mappedConceptId>
		 *   <mappingType>inter-cui</mappingType>
		 * </context>
		 * 
		 * For IsaClosure annotations the XML looks like this:
		 * <context class="isaContextBean">
         *   <contextName>ISA_CLOSURE</contextName>
         *   <isDirect>false</isDirect>
         *   <concept>
         *      <localConceptID>ontology/conceptID</localConceptID>
         * 		<preferredName>...</preferredName>...
         *   </concept>
         *   <level>1</level>
         * </context>
		 */
		private function parseContext(bean:XML):AnnotationContext {
			var context:AnnotationContext = null;
			if (bean != null) {
				var contextClass:String = firstChild(bean.attribute("class"));
				var name:String = bean.contextName;
				var isDirect:Boolean = bean.isDirect;
				context = new AnnotationContext(name, contextClass, isDirect);
				
				var start:Number = Number(bean.from.toString());
				var end:Number = Number(bean.to.toString());
				
				var concept:Concept = null;
				var fullID:String;
				
				if (context.isMgrep) {
					// annotator 
					fullID = bean.term.localConceptId;
					if (!fullID) {
						fullID = bean.term.localConceptID;
					}
					// bug - the termID field is NOT the concept ID
					// it is some kind of internal id for the resource
//					if (fullID.length == 0) {
//						fullID = bean.termID;	// by resource element
//					}
					var termName:String = bean.term.name;
					if (termName.length == 0) {
						termName = bean.termName;	// by resource element
					}
					// MGREP only, remember - offsets are one based
					context.setMgrep(fullID, termName, start, end);
				} else if (context.isMapping) {
					// contains the ontologyId/conceptId - the mappedConceptID sets both
					fullID = bean.mappedConceptId;
					if (fullID.length == 0) {
						fullID = bean.mappedConceptID;	// by resource element
					}
					var mappingType:String = bean.mappingType;
					context.setMapping(fullID, "" /* concept name  not implemented yet */, mappingType, start, end);
					/* (future) full concept details included (not implement on backend yet, bug #1362)
					concept = parseConcept(firstChild(bean.concept));
					if (concept != null) {
						context.conceptID = concept.id;
						context.conceptName = concept.name;
						context.ontologyVersionID = concept.ontologyID;
						context.setMapping(concept.id, concept.name, concept.ontologyId, type);
					}*/
				} else if (context.isIsaClosure) {
					concept = parseConcept(firstChild(bean.concept));
					var level:String = bean.level;
					if (concept != null) {
						context.setIsA(concept.id, concept.name, concept.ontologyID, level, start, end);
					} else {
						context.level = level;
					}
				}
				
			}
			return context;
		}
		
		private function parseSingleAnnotation(annotationBean:XML, resourceID:String):Annotation {
			var annotation:Annotation = null;
			if (annotationBean != null) {
				var elementID:String = annotationBean.localElementId;
				if (elementID.length == 0) {
					elementID = annotationBean.localElementID;	 // (August 2009) previous versions
				}
				var score:Number = Number(annotationBean.score.toString());
				var concept:Concept = parseConcept(firstChild(annotationBean.elements("concept")));
				var context:AnnotationContext = parseContext(firstChild(annotationBean.elements("context")));
				if (context && concept && (context.ontologyVersionID.length == 0)) {
					context.ontologyVersionID = concept.ontologyVersionID;
				}
				if (context && concept && (context.conceptID.length == 0)) {
					context.conceptID = concept.id;
				}
				if (context && concept && (context.conceptName.length == 0)) {
					context.conceptName = concept.name;
				}
				
				// August 2010 - pick out the ResourceID from the element structure
				if (!resourceID) {
					resourceID = annotationBean.element.elementStructure.resourceId;
					if (!resourceID) {
						resourceID = annotationBean.element.elementStructure.resourceID;	// previous version
					}
				}
				
				annotation = new Annotation(elementID, resourceID, score, concept, context);

				// try to load the ontology from the cache
				if (concept != null) {
					annotation.ontology = getCachedOntology(concept.ontologyID);
				}
				// load the resource from the cache
				annotation.resource = getCachedResource(resourceID);
			}
			return annotation;
		}
		
		/**
		 * Parses the XML returned from annotating text, expected in the form:
		 * <success><data><annotatorResultBean>
		 * 	<dictionary>...</dictionary>
		 * 	<statistics>...</statistics>
		 * 	<parameters>...</parameters>
		 * 	<text>search text</text>
		 * 	<annotations>
		 * 		<annotationBean>
		 * 			<score>16.0</score>
		 *	 		<concept>
		 * 				<localConceptID>38802/NCBITaxon:32011</localConceptID>
		 * 				<preferredName>Methylophilaceae</preferredName> 
		 * 				<synonyms>
		 * 					<string>'Methylophilaceae'</string>...
		 * 				</synonyms>
		 * 				<isTopLevel>false</isTopLevel> 
		 * 				<localOntologyID>38802</localOntologyID> 
		 * 				<semanticTypes>
		 * 					<semanticTypeBean>
		 * 						<conceptId>MDR/C0029463</conceptId>
		 *	 					<localSemanticTypeId>T999</localSemanticTypeId> 
		 * 						<name>UMLS concept</name>
		 *					</semanticTypeBean>
		 * 				</semanticTypes>
		 * 			</concept>
		 * 			<context class="mgrepContextBean">
		 * 				<contextName>MGREP</contextName> 
		 * 				<isDirect>true</isDirect> 
		 * 				<term>...</term> 
		 * 				<from>24</from> 
		 * 				<to>29</to> 
		 * 			</context>
		 * 		</annotationBean>
		 * 	</annotations>
		 * 	<ontologies>
		 * 		<ontologyUsedBean>
		 *   		<localOntologyID>SNOMEDCT</localOntologyID>
		 *   		<ontologyName>SNOMED Clinical Terms, 2007_01_31</ontologyName>
		 *   		<ontologyVersion>2007_01_31</ontologyVersion>
		 *   		<nbAnnotation>39</nbAnnotation>
		 *   		<score>352.0</score> 
		 * 		</ontologyUsedBean>
		 * 	</ontologies>
		 * <annotatorResultBean></data></success>
		 */
		private function parseAnnotateTextResult(xml:XML, event:AnnotateTextEvent):void {
			var annotations:Array = [];
			var ontologies:Array = [];
			var annotationStats:Array = [];
			if (xml != null) {
				var resourceID:String = "";	// no resource id for annotating text?
				if (!checkError(xml, event)) {
					// new annotator server
					xml = xml.data.annotatorResultBean[0];
					// stats
					var statsList:XMLList = xml.statistics.statisticsBean; //elements("obs.common.beans.StatisticsBean");
					for each (var statsBean:XML in statsList) {
						var contextName:String = statsBean.contextName;
						var nbAnnotaions:int = int(Number(statsBean.nbAnnotation.toString()));
						var stats:AnnotationStats = new AnnotationStats(contextName, nbAnnotaions);
						annotationStats.push(stats);  
					}
					
					// load the ontologies first so that they are cached for the concepts later
					var ontologyList:XMLList = xml.ontologies.ontologyUsedBean; //elements("obs.common.beans.OntologyUsedBean");
					for each (var ontologyBean:XML in ontologyList) {
						var ontology:Ontology = parseOntology(ontologyBean);
						if (ontology) {
							ontologies.push(ontology);
						}
					}
					
					// now load the concepts
					currentAnnotationBeanList = xml.annotations.annotationBean; //elements("obs.common.beans.AnnotationBean");
					for each (var annotationBean:XML in currentAnnotationBeanList) {
						var annotation:Annotation = parseSingleAnnotation(annotationBean, resourceID);
						annotations.push(annotation);
					}
					currentAnnotationBeanList = null;
				}
			}
			event.annotations = annotations;
			event.ontologies = ontologies;
			event.annotationStats = annotationStats;
		}
		
		//  NOT USED (and out of date)
//		private function parseAnnotationsForConcept(xml:XML, event:OBSEvent):void {
//			// TODO the XML has been updated, but since this method doesn't get called 
//			// it hasn't been updated yet
//			var annotations:Array = [];
//			if (xml != null) {
//				// XML is like: <success><data><list><obrResultBean>...
//				
//				var resourceID:String = xml.resourceId;
//				if (resourceID.length == 0) {
//					resourceID = xml.resourceID;	// previous versions
//				}
//				currentAnnotationBeanList = xml.mgrepAnnotations.elements("obs.common.beans.ObrAnnotationBean");
//				if (currentAnnotationBeanList.length() == 0) {
//					currentAnnotationBeanList = xml.annotations.elements("obs.common.beans.ObrAnnotationBean");
//				}
//				for each (var annotationBean:XML in currentAnnotationBeanList) {
//					var annotation:Annotation = parseSingleAnnotation(annotationBean, resourceID);
//					annotations.push(annotation);
//				}
//				// if withContext=true then we get reported/directAnnotations, isaAnnotations, mappingAnnotations
//				currentAnnotationBeanList = xml.reportedAnnotations.elements("obs.common.beans.ObrAnnotationBean");
//				if (currentAnnotationBeanList.length() == 0) {
//					currentAnnotationBeanList = xml.directAnnotations.elements("obs.common.beans.ObrAnnotationBean");
//				}
//				for each (annotationBean in currentAnnotationBeanList) {
//					annotation = parseSingleAnnotation(annotationBean, resourceID);
//					annotations.push(annotation);
//				}
//				// also isaAnnotations
//				currentAnnotationBeanList = xml.isaAnnotations.elements("obs.common.beans.ObrAnnotationBean");
//				for each (annotationBean in currentAnnotationBeanList) {
//					annotation = parseSingleAnnotation(annotationBean, resourceID);
//					annotations.push(annotation);
//				}
//				// also mappingAnnotaions
//				currentAnnotationBeanList = xml.mappingAnnotations.elements("obs.common.beans.ObrAnnotationBean");
//				for each (annotationBean in currentAnnotationBeanList) {
//					annotation = parseSingleAnnotation(annotationBean, resourceID);
//					annotations.push(annotation);
//				}
//				currentAnnotationBeanList = null;
//			}
//			event.items = annotations;
//		}
		
		private function parseAnnotationsForResourceElement(xml:XML, event:OBSEvent):void {
			var annotations:Array = [];
			if (xml != null) {
				// New naming conventions (August 2010)
				var detailed:XMLList = xml.data.list.resultDetailed;
				if (detailed.length() == 0) {
					detailed = xml.data.list.result;
				}
				if (detailed.length() == 0) {
					detailed = xml.data.list.obrResultBeanDetailled;
				}
				if (detailed.length() == 0) {
					detailed = xml.data.list.obrResultBeanDetailed;
				}
				if (detailed.length() == 0) {
					detailed = xml.data.list.obrResultBean;
				}
				// Old Naming Conventions
				if (detailed.length() == 0) {
					// gotta love mispeltings
					xml.elements("obs.common.beans.ObrResultBeanDetailled");
				}
				if (detailed.length() == 0) {
					detailed = xml.elements("obs.common.beans.ObrResultBeanDetailed");
				}
				if (detailed.length() == 0) {
					detailed = xml.elements("obs.common.beans.ObrResultBean");
				}
				if (detailed.length() == 1) {
					xml = detailed[0];
				} else if (detailed.length() > 1) {
					//trace("Multiple annotation result details found: " + detailed.length());
					for each (var detail:XML in detailed) {
						parseAnnotationsForResourceElement(detail, event);
						annotations = annotations.concat(event.items);
					}
					event.items = annotations;
					return;
				}
				
				// annotation stats
				var statsBeans:XMLList = xml.resultStatistics.statistics;
				if (statsBeans.length() == 0) { 
					statsBeans = xml.statistics.statisticsBean;
				} 
				if (statsBeans.length() == 0) {
					// old naming
					statsBeans = xml.statistics.elements("obs.common.beans.StatisticsBean");
				}
				if (statsBeans.length() >= 1) {
					var bean:XML = statsBeans[0];
					var contextName:String = bean.contextName;
					var nbAnnotations:int = bean.annotationCount;
					if (nbAnnotations == 0) {
						nbAnnotations = bean.nbAnnotation;
					}
					event.annotationStats = [ new AnnotationStats(contextName, nbAnnotations) ];
				}
				
				//var elementID:String = xml.localElementId;
				var resourceID:String = xml.resourceId;
				if (resourceID.length == 0) {
					resourceID = xml.resourceID;	// previous versions
				}
				var mode:String = xml.mode;	// UNION, INTERSECTION
				var annotation:Annotation;
				
				var ontologyIDs:XMLList = xml.parameters.localOntologyIds;
				if (ontologyIDs.length() == 0) {
					ontologyIDs = xml.parameters.localOntologyIDs;	// previous versions
				}

				// ***For use case #4 (OBA) you can have the 3 following different types: MGREP, ISA_CLOSURE, MAPPING:
				// (everything come into the <annotations> xml element

				// ***For use case #3 (OBR by element) you can have the 4 following different types: 
				// MGREP, REPORTED, ISA_CLOSURE, MAPPING
				// If withContext=false everything come into the <annotations> xml element and no context information is returned
				// If withContext=true <annotations> will be empty and the corresponding annotations will be in 
				// <directAnnotations> , <isaAnnotations>, <mappingAnnotations>

				currentAnnotationBeanList = xml.annotations.annotation;
				if (currentAnnotationBeanList.length() == 0) {
					currentAnnotationBeanList = xml.annotations.obrAnnotationBean;
				}
				for each (var annotationBean:XML in currentAnnotationBeanList) {
					annotation = parseSingleAnnotation(annotationBean, resourceID);
					annotations.push(annotation);
				}

				currentAnnotationBeanList = xml.mgrepAnnotations.annotation;
				if (currentAnnotationBeanList.length() == 0) {
					currentAnnotationBeanList = xml.mgrepAnnotations.obrAnnotationBean;
				}
				if (currentAnnotationBeanList.length() == 0) { 
					currentAnnotationBeanList = xml.mgrepAnnotations.elements("obs.common.beans.ObrAnnotationBean");
				}
				if (currentAnnotationBeanList.length() == 0) {
					// old way (pre-July 2010)
					currentAnnotationBeanList = xml.annotations.elements("obs.common.beans.ObrAnnotationBean");
				}
				for each (annotationBean in currentAnnotationBeanList) {
					annotation = parseSingleAnnotation(annotationBean, resourceID);
					annotations.push(annotation);
				}

				// if withContext=true then we get directAnnotations, isaAnnotations, mappingAnnotations
				currentAnnotationBeanList = xml.reportedAnnotations.annotation;
				if (currentAnnotationBeanList.length() == 0) {
					currentAnnotationBeanList = xml.reportedAnnotations.obrAnnotationBean;
				}
				if (currentAnnotationBeanList.length() == 0) {
					currentAnnotationBeanList = xml.reportedAnnotations.elements("obs.common.beans.ObrAnnotationBean");
				}
				if (currentAnnotationBeanList.length() == 0) {
					// old way (pre July 2010)
					currentAnnotationBeanList = xml.directAnnotations.elements("obs.common.beans.ObrAnnotationBean");
				}
				for each (annotationBean in currentAnnotationBeanList) {
					annotation = parseSingleAnnotation(annotationBean, resourceID);
					annotations.push(annotation);
				}
				// also isaAnnotations
				currentAnnotationBeanList = xml.isaAnnotations.annotation;
				if (currentAnnotationBeanList.length() == 0) {
					currentAnnotationBeanList = xml.isaAnnotations.obrAnnotationBean;
				}
				if (currentAnnotationBeanList.length() == 0) {
					currentAnnotationBeanList = xml.isaAnnotations.elements("obs.common.beans.ObrAnnotationBean");
				}
				for each (annotationBean in currentAnnotationBeanList) {
					annotation = parseSingleAnnotation(annotationBean, resourceID);
					annotations.push(annotation);
				}
				// also mappingAnnotaions
				currentAnnotationBeanList = xml.mappingAnnotations.annotation;
				if (currentAnnotationBeanList.length() == 0) {
					currentAnnotationBeanList = xml.mappingAnnotations.obrAnnotationBean;
				}
				if (currentAnnotationBeanList.length() == 0) {
					currentAnnotationBeanList = xml.mappingAnnotations.elements("obs.common.beans.ObrAnnotationBean");
				}
				for each (annotationBean in currentAnnotationBeanList) {
					annotation = parseSingleAnnotation(annotationBean, resourceID);
					annotations.push(annotation);
				}
				currentAnnotationBeanList = null;
			}
			event.items = annotations;
		}
		
		private function parseAnnotationStatisticsForResourceElement(xml:XML, event:OBSEvent):void {
			var annotationStats:Array = [];
			if (xml != null) {
				// Pick out the single result detail bean
				var list:XMLList = xml.data.resultDetailed;
				if (list.length() == 0) {
					list = xml.data.obrResultBeanDetailled;
				}
				if (list.length() == 0) {
					list = xml.data.obrResultBeanDetailed;
				}
				if (list.length() == 0) {
					list = xml.data.result;
				}
				if (list.length() == 1) {
					xml = list[0];
				}
				
				var elementID:String = xml.localElementId;
				if (elementID.length == 0) {
					elementID = xml.localElementID;	// previous versions
				}
				var resourceID:String = xml.resourceId;
				if (resourceID.length == 0) {
					resourceID = xml.resourceID;	// previous
				}
				//var mode:String = xml.mode;	// UNION, INTERSECTION
				//var localConceptIDs:Array;
				list = xml.resultStatistics.statistics;
				if (list.length() == 0) {
					list = xml.statistics.statisticsBean;
				}
				if (list.length() == 0) {
					list = xml.statistics.elements("obs.common.beans.StatisticsBean");
				}
				if (list.length() == 0) {
					list = xml.elements("obs.common.beans.ObrResultBean").statistics.elements("obs.common.beans.StatisticsBean");
				}
				for each (var statsBean:XML in list) {
					var contextName:String = statsBean.contextName;
					var nbAnnotations:int = int(Number(statsBean.annotationCount.toString()));
					if (nbAnnotations == 0) {
						nbAnnotations = int(Number(statsBean.nbAnnotation.toString()));
					}
					var stats:AnnotationStats = new AnnotationStats(contextName, nbAnnotations);
					annotationStats.push(stats);  
				}
			}
			event.items = annotationStats;
		}
		
		private function parseDetailedAnnotation(xml:XML, event:OBSEvent):void {
			var annotations:Array = [];
			if (xml != null) {
				// resourceID is not in the xml anymore?  (Dec 2009) 
				var resourceID:String = xml.resourceId;
				if (resourceID.length == 0) {
					resourceID = xml.resourceID;	// previous versions
				}
				var elementID:String = null;
				// New naming (August 2010)
				currentAnnotationBeanList = xml.data.list.annotation;
				if (currentAnnotationBeanList.length() == 0) {
					currentAnnotationBeanList = xml.data.list.obrAnnotationBean;
				}
				if (currentAnnotationBeanList.length() == 0) {
					currentAnnotationBeanList = xml.data.list.obrAnnotationBeanDetailled;
				}
				if (currentAnnotationBeanList.length() == 0) {
					currentAnnotationBeanList = xml.data.list.obrAnnotationBeanDetailed;
				}				
				if (currentAnnotationBeanList.length() == 0) {
					// NOTE spelling mistake on "Detailed"!  (Dec 2009)
					currentAnnotationBeanList = xml.elements("obs.common.beans.ObrAnnotationBeanDetailled");
				}
				if (currentAnnotationBeanList.length() == 0) {
					currentAnnotationBeanList = xml.elements("obs.common.beans.ObrAnnotationBeanDetailed");
				}
				for each (var bean:XML in currentAnnotationBeanList) {
					var annotation:Annotation = parseSingleAnnotation(bean, resourceID);
					if (elementID == null) {
						elementID = annotation.elementID; 
					}
					annotations.push(annotation);
				}
				currentAnnotationBeanList = null;
			}
			event.items = annotations;
		}
		
		private function parseAnnotationsForConcepts(xml:XML, event:OBSEvent):void {
			// this is the same as the handler for resource element case?
			parseAnnotationsForResourceElement(xml, event);
		}
		
		/**
		 * <list>
		 * 	<obs.common.beans.OntologyUsedBean>
		 * 	  <localOntologyID>39284</localOntologyID>
		 * 	  <ontologyName>Chemical entities of biological interest</ontologyName>
		 * 	  <ontologyVersion>1.49</ontologyVersion>
		 * 	  <nbAnnotation>61</nbAnnotation>
		 * 	  <score>740.0</score>	
		 * 	</obs.common.beans.OntologyUsedBean>
		 *  ...
		 * </list>
		 */
		private function parseOntologyRecommendations(xml:XML, event:OBSEvent):void {
			var ontologies:Array = []; 
			if (xml != null) {
				var list:XMLList = xml.elements("obs.common.beans.RecommendedOntologyBean");
				for each (var bean:XML in list) {
					var ontology:Ontology = parseOntology(bean);
					if (ontology) {
						ontologies.push(ontology);
					}
				}
			}
			event.items = ontologies;
		} 
		
		private function checkError(xml:XML, event:OBSEvent):Boolean {
			if (xml.name() == "errorStatus") {
				var shortMsg:String = xml.shortMessage;
				var longMsg:String = xml.longMessage;
				var errorCode:String = xml.errorCode;
				event.fault = new Fault(errorCode, longMsg, shortMsg);
				return true;
			}
			return false;
		}
		
		/////////////////////
		// UTIL FUNCTIONS
		/////////////////////
		
		private function firstChild(list:XMLList):XML {
			if ((list != null) && (list.length() > 0)) {
				return list[0];
			}
			return null;
		}
		
	}
}