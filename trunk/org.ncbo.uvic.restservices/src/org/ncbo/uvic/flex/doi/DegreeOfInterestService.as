package org.ncbo.uvic.flex.doi
{
	import mx.messaging.ChannelSet;
	import mx.messaging.channels.AMFChannel;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.remoting.RemoteObject;
	import mx.utils.ObjectUtil;
	
	import org.ncbo.uvic.flex.NCBORestService;
	import org.ncbo.uvic.flex.model.IConcept;
	import org.ncbo.uvic.flex.model.INCBOItem;
	import org.ncbo.uvic.flex.model.IOntology;
	import org.ncbo.uvic.flex.model.NCBOSearchResultConcept;
	
	//[Event(name="itemLogged", type="org.ncbo.uvic.flex.events.NCBOLogEvent")]
	
	public class DegreeOfInterestService
	{
		
		//private static const ENDPOINT_URL:String = "http://localhost/amfphp/gateway.php";
		private static const ENDPOINT_URL:String = "http://keg.cs.uvic.ca/amfphp/gateway.php";
		private static const DESTINATION:String = "amfphp";
		private static const SERVICE:String = "ncbolog.DegreeOfInterestService";

		public static const DOI_KEY:String = "doi";
		public static const DAYS:int = 14;
		private static const DEFAULT_LANDMARK:uint = 50;
		private static const DEFAULT_INTERESTING:uint = 10;
		
		private static const STYLE_UNINTERESTING:String = "uninteresting";
		private static const STYLE_INTERESTING:String = "interesting";
		private static const STYLE_LANDMARK:String = "landmark";

		private static var _channelSet:ChannelSet;
		private static var _remoteObject:RemoteObject;
		
		public static var restService:NCBORestService = null;
		// maps the source to the boolean is highlighting value
		private static var highlighting:Object = new Object();
		// maps the source to the boolean is filtering value
		private static var filtering:Object = new Object();
		// maps the source to the boolean is sorting value
		private static var sorting:Object = new Object();
		// maps the source to the interest threshold values
		private static var interestThresholds:Object = new Object();
		// maps the source to the landmark threshold values
		private static var landmarkThresholds:Object = new Object();
		
		public static function isHighlighting(source:String):Boolean {
			return highlighting.hasOwnProperty(source);
		}
		
		public static function setHighlighting(source:String, on:Boolean):void {
			var oldValue:Boolean = isHighlighting(source); 
			if (on && !oldValue) {
				highlighting[source] = true;
			} else if (!on && oldValue) {
				delete highlighting[source];
			}
		}

		public static function isFiltering(source:String):Boolean {
			return filtering.hasOwnProperty(source);
		}
		
		public static function setFiltering(source:String, on:Boolean):void {
			var oldValue:Boolean = isFiltering(source); 
			if (on && !oldValue) {
				filtering[source] = true;
			} else if (!on && oldValue) {
				delete filtering[source];
			}
		}
		
		public static function isSorting(source:String):Boolean {
			return sorting.hasOwnProperty(source);
		}
		
		public static function setSorting(source:String, on:Boolean):void {
			var oldValue:Boolean = isSorting(source); 
			if (on && !oldValue) {
				sorting[source] = true;
			} else if (!on && oldValue) {
				delete sorting[source];
			}
		}
		
		public static function getStyleName(item:INCBOItem, source:String):String {
			var interesting:Boolean = isInteresting(item, source);
			var landmark:Boolean = isLandmark(item, source);
			var style:String = (landmark ? STYLE_LANDMARK : 
					(interesting ? STYLE_INTERESTING : STYLE_UNINTERESTING));
			return style;
		}

		public static function getInterestingThreshold(source:String):Number {
			var threshold:Number = DEFAULT_INTERESTING;
			if (source && interestThresholds.hasOwnProperty(source)) {
				threshold = Number(interestThresholds[source]);
			}
			return threshold;
		}
		
		public static function setInterestingThreshold(source:String, threshold:Number):void {
			if (source) {
				if (!isNaN(threshold) && (threshold >= 0)) {
					interestThresholds[source] = threshold; 
				} else if (interestThresholds.hasOwnProperty(source)) {
					delete interestThresholds[source];
				}
			}
		} 
		
		public static function setThresholds(source:String, interesting:Number, landmark:Number):void {
			setInterestingThreshold(source, interesting);
			setLandmarkThreshold(source, landmark);
		}
		
		public static function isInteresting(item:INCBOItem, source:String):Boolean {
			var doi:Number = getDegreeOfInterest(item);
			var threshold:Number = getInterestingThreshold(source);
			var interesting:Boolean = !isNaN(doi) && (doi >= threshold);
			return interesting;
		}
		
		public static function setInteresting(item:INCBOItem, source:String):void {
			if (!isInteresting(item, source)) {
				var threshold:Number = getInterestingThreshold(source);
				setDegreeOfInterest(item, threshold);
			} 
		}
		
		public static function getLandmarkThreshold(source:String):Number {
			var threshold:Number = DEFAULT_LANDMARK;
			if (source && landmarkThresholds.hasOwnProperty(source)) {
				threshold = Number(landmarkThresholds[source]);
			}
			return threshold;
		}
		
		public static function setLandmarkThreshold(source:String, threshold:Number):void {
			if (source) {
				if (!isNaN(threshold) && (threshold >= 0)) {
					landmarkThresholds[source] = threshold; 
				} else if (landmarkThresholds.hasOwnProperty(source)) {
					delete landmarkThresholds[source];
				}
			}
		} 
		
		public static function isLandmark(item:INCBOItem, source:String):Boolean {
			var doi:Number = getDegreeOfInterest(item);
			var threshold:Number = getLandmarkThreshold(source);
			var landmark:Boolean = !isNaN(doi) && (doi >= threshold);
			return landmark;
		}
				
		public static function setLandmark(item:INCBOItem, source:String):void {
			if (!isLandmark(item, source)) {
				var threshold:Number = getLandmarkThreshold(source);
				setDegreeOfInterest(item, threshold);
			} 
		}
		
		public static function getDegreeOfInterest(item:INCBOItem):Number {
			var doi:Number = NaN;
			if (item.hasProperty(DOI_KEY)) {
				doi = item.getNumberProperty(DOI_KEY);
			}
			return doi;
		}
		
		public static function setDegreeOfInterest(item:INCBOItem, doi:Number):void {
			if (!isNaN(doi)) {
				//debug("Setting DOI to " + doi + " for " + item);
				item.setProperty(DOI_KEY, doi);
			} else if (item.hasProperty(DOI_KEY)) {
				//debug("Removed DOI for " + ncboItem);
				item.removeProperty(DOI_KEY);
			}
		}
		
		private static function debug(msg:String):void {
			trace("[DOI] " + msg);
		}
		
		private static function error(functionName:String, msg:String):void {
			trace("[DOI] " + functionName + " error: " + msg);
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
			var resultHandler:Function = (token.resultHandler as Function);
			var result:Object = resultHandler(event.result, token);
			var callback:Function = (token.callback as Function);
			if (callback != null) {
				callback(result);
			}
		}
		
		private static function faultHandler(event:FaultEvent):void {
			var token:AsyncToken = event.token;
			var err:String;
			if (event.fault.faultString == "HTTP request error") {
				err = "Could not connect to the server.";
			} else {
				err = "Connection error: " + event.fault.faultString;
			}
	    	debug("fault: " + err);
	    	
    		var callback:Function = (token.callback as Function);
			if (callback != null) {
	    		callback(null, err);
	    	}
		}
		
				
		private static function createSimpleObject(item:Object):Object {
			var simple:Object = new Object();
			if (item) {
				var conceptID:String = "";
				var versionID:String = "";
				var virtualID:String = "";
				if (item is IConcept) {
					var c:IConcept = (item as IConcept);
					conceptID = c.id;
					versionID = c.ontologyVersionID;
					if (c is NCBOSearchResultConcept) {
						virtualID = (c as NCBOSearchResultConcept).ontologyID;
					} else if (restService) {
						var o:IOntology = restService.getOntology(c.ontologyVersionID, false);
						if (o) {
							virtualID = o.ontologyID;
						}
					}
				} else if (item is IOntology) {
					var ont:IOntology = (item as IOntology);
					versionID = ont.ontologyVersionID;
					virtualID = ont.ontologyID;
				}
				simple["conceptID"] = conceptID;
				simple["versionID"] = versionID;
				simple["virtualID"] = virtualID;
			}
			return simple;
		}
		
		public static function loadDegreeOfInterest(items:Array, callback:Function):void {
			var simpleItems:Array = [];
			for each (var item:Object in items) {
				var doi:Number = getDegreeOfInterest(item as INCBOItem);
				if (isNaN(doi)) {
					var simple:Object = createSimpleObject(item);
					simpleItems.push(simple);
				}
			}
			
			// lookup
			debug("loading DOI for " + simpleItems.length + " out of " + items.length);
			if (simpleItems.length > 0) {
				try {
					var token:AsyncToken = remoteObject.getDegreeOfInterestForItems(simpleItems, DAYS);
					token.callback = callback;
					token.resultHandler = degreeOfInterestResultHandler;
					token.inputItems = items;
				} catch (ex:Error) {
					error("loadDegreeOfInterest", ex.message);
				}
			} else {
				// no items need to be looked up
				callback(null);
			}
		}
		
		private static function degreeOfInterestResultHandler(result:Object, token:AsyncToken):Array {
			var changedItems:Array = [];
			var items:Array = (token.inputItems as Array); 
			var array:Array = (result as Array);
			if (!array && (result is Object)) {
				array = [ result ];
			}
			if (array) {
				var cid:String, vid:String, oid:String, doi:Number;
				for each (var simple:Object in array) {
					cid = "";
					vid = "";
					oid = "";
					doi = NaN;
					if (simple.hasOwnProperty("conceptID")) {
						cid = simple.conceptID;
					}
					if (simple.hasOwnProperty("versionID")) {
						vid = simple.versionID;
					}
					if (simple.hasOwnProperty("virtualID")) {
						oid = simple.virtualID;
					}
					if (simple.hasOwnProperty("doi")) {
						doi = Number(simple.doi);
					}
					
					if (!isNaN(doi)) {
						// find the matching input item
						for each (var inputItem:Object in items) {
							if (inputItem is IConcept) {
								var c:IConcept = (inputItem as IConcept);
								if ((cid == c.id) && (vid == c.ontologyVersionID)) {
									setDegreeOfInterest(c, doi);
									changedItems.push(c);
								}
								
							} else if (inputItem is IOntology) {
								var o:IOntology = (inputItem as IOntology);
								if (o.ontologyID == oid) {
									setDegreeOfInterest(o, doi);
									changedItems.push(o);
								}
							}
						}
					}
				} 
			}
			return changedItems;
		}
		
		public static function degreeOfInterestSortFunction(item1:INCBOItem, item2:INCBOItem):int {
			var doi1:Number = DegreeOfInterestService.getDegreeOfInterest(item1);
			var doi2:Number = DegreeOfInterestService.getDegreeOfInterest(item2);
			return ObjectUtil.numericCompare(doi2, doi1);	// descending is the default
		}

		public static function debugItems(items:Array, includeItemsWithNoDOI:Boolean = false):void {
			items.sort(degreeOfInterestSortFunction, Array.NUMERIC);
			var noDoi:int = 0;
			for each (var item:INCBOItem in items) {
				var id:String = item.id;
				var name:String = item.name;
				var doi:Number = getDegreeOfInterest(item);
				if (includeItemsWithNoDOI || (doi > 0)) {
					if (item is IOntology) {
						var oid:String = (item as IOntology).ontologyID;
						trace(id + ", " + name + ", " + oid + ", " + getDegreeOfInterest(item)); 
					} else if (item is IConcept) {
						var vid:String = (item as IConcept).ontologyVersionID;
						trace(id + ", " + name + ", " + vid + ", " + getDegreeOfInterest(item));
					}
				} else {
					noDoi++;
				}
			}
			if (noDoi > 0) {
				trace("No degree of interest for " + noDoi + " items");
			}
		}

	}
}