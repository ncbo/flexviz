package util
{
	
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	
	import mx.controls.dataGridClasses.DataGridColumn;
	
	import org.ncbo.uvic.flex.events.NCBOSearchEvent;
	import org.ncbo.uvic.flex.model.NCBOSearchResultConcept;
	import org.ncbo.uvic.flex.model.NCBOSearchResultOntology;
	import org.ncbo.uvic.flex.search.SearchParams;
	
	/**
	 * Utility funtions for working with the SharedObject class.
	 * 
	 * @author Chris Callendar
	 * @date January 16th, 2009
	 */
	public class Shared
	{
		
		private static const FILE:String = "SearchUI_cache";
		
		private static const PREVIOUS_SEARCHES:String = "previousSearches";
		private static const LAST_SEARCH_DATE:String = "lastSearchDate";
		private static const LAST_SEARCH_CONCEPTS:String = "lastSearchConcepts";
		private static const LAST_SEARCH_PARAMS:String = "lastSearchParameters";
		private static const RESULT_COLUMNS:String = "resultColumns";
		
		/**
		 * Saves the properties from data into the SharedObject.
		 */
		public static function savePreviousSearches(searches:Array):void {
			try {
				SharedObject.defaultObjectEncoding = ObjectEncoding.AMF3;
				var shared:SharedObject = SharedObject.getLocal(FILE, "/");
				shared.data[PREVIOUS_SEARCHES] = searches;
				// not needed
				//shared.flush();
			} catch (error:Error) {
				trace("Error saving previous searches to shared data");
				trace(error);
			}
		}
		
		/**
		 * Loads and returns all the properties from the SharedObject
		 * in a new object.
		 */
		public static function loadPreviousSearches():Array {
			var searches:Array = new Array();
			try {
				SharedObject.defaultObjectEncoding = ObjectEncoding.AMF3;
				var shared:SharedObject = SharedObject.getLocal(FILE, "/");
				var array:Array = (shared.data[PREVIOUS_SEARCHES] as Array);
				if (array != null) {
					for (var i:int = 0; i < array.length; i++) {
						var obj:Object = array[i];
						// convert from a generic object 
						var params:SearchParams = SearchParams.parse(obj);
						searches.push(params);
					}
				}
			} catch (error:Error) {
				trace("Error loading previous searches from shared data");
				trace(error);
			}
			return searches;
		}
		
		public static function clearLastSearchResults():void {
			saveLastSearchResults(null);
		}
		
		/**
		 * Saves the last search results (concepts and search parameters).
		 * It also saves the current date/time too.
		 */
		public static function saveLastSearchResults(event:NCBOSearchEvent):void {
			try {
				SharedObject.defaultObjectEncoding = ObjectEncoding.AMF3;
				var shared:SharedObject = SharedObject.getLocal(FILE, "/");
				if ((event != null) && (event.concepts.length > 0)) {
					var time:Date = new Date();
					shared.data[LAST_SEARCH_DATE] = time.getTime();
					shared.data[LAST_SEARCH_CONCEPTS] = convertConceptsToSimpleObjects(event.concepts);
					shared.data[LAST_SEARCH_PARAMS] = event.searchParams;
				} else {
					delete shared.data[LAST_SEARCH_DATE];
					delete shared.data[LAST_SEARCH_CONCEPTS];
					delete shared.data[LAST_SEARCH_PARAMS];
				}
				shared.flush();
				trace("Shared size: " + shared.size + " bytes");
			} catch (error:Error) {
				trace("Error saving last search to shared data");
				trace(error);
			}
		}
		
		/**
		 * For some reason we need to convert the NCBOSearchResultConcept and NCBOSearchResultOntology 
		 * objects into plain objects because when we try to load the concepts back in
		 * it doesn't work - the concepts have no properties.
		 */ 
		private static function convertConceptsToSimpleObjects(concepts:Array):Array {
			var ontologies:Object = new Object();
			var objects:Array = [];
			for (var i:int = 0; i < concepts.length; i++) {
				var concept:NCBOSearchResultConcept = concepts[i];
				var conceptObj:Object = new Object();
				conceptObj.id = concept.id;
				conceptObj.name = concept.name;
				conceptObj.recordType = concept.recordType;
				//obj.contents = concept.contents;
				conceptObj.searchText = concept.searchText;
				var ontologyObj:Object = null;
				if (ontologies.hasOwnProperty(concept.ontology.ontologyVersionID)) {
					ontologyObj = ontologies[concept.ontology.ontologyVersionID];
				} else {
					ontologyObj = new Object();
					ontologyObj.ontologyVersionID = concept.ontology.ontologyVersionID;
					ontologyObj.ontologyID = concept.ontology.ontologyID;
					ontologyObj.displayLabel = concept.ontology.displayLabel;
					ontologyObj.hits = concept.ontology.hits;
					ontologies[ontologyObj.ontologyVersionID] = ontologyObj;
				}
				conceptObj.ontology = ontologyObj;
				objects.push(conceptObj);
			}
			return objects;
		}
		
		/**
		 * Loads the last search results if the search was done
		 * with in the last delta milliseconds.
		 * @param delta the number of milliseconds before now that we will get the search results for.
		 * 	If zero then the search results are returned regardless.
		 * @return an Array of NCBOSearchResultConcept objects, or null
		 */
		public static function loadLastSearchResults(delta:Number = 1800000):NCBOSearchEvent {
			var event:NCBOSearchEvent = null;
			var ontologiesArray:Array = [];
			var ontologies:Object = new Object();
			var concepts:Array = [];
			try {
				SharedObject.defaultObjectEncoding = ObjectEncoding.AMF3;
				var shared:SharedObject = SharedObject.getLocal(FILE, "/");
				var now:Number = new Date().getTime();
				var lastTime:Number = (delta <= 0 ? now : Number(shared.data[LAST_SEARCH_DATE]));
				if (!isNaN(lastTime)) {
					if ((now - lastTime) <= delta) {
						var paramsObject:Object = shared.data[LAST_SEARCH_PARAMS];
						var params:SearchParams = (paramsObject != null ? SearchParams.parse(paramsObject) : null);
						var objectsArray:Array = (shared.data[LAST_SEARCH_CONCEPTS] as Array);
						if (objectsArray != null) {
							for (var i:int = 0; i < objectsArray.length; i++) {
								var conceptObject:Object = objectsArray[i];
								// have to convert from plain objects into type objects
								if (conceptObject.hasOwnProperty("ontology")) {
									var ontologyObject:Object = conceptObject["ontology"];
									var versionID:String = ontologyObject["ontologyVersionID"];
									var ontology:NCBOSearchResultOntology = null;
									if (ontologies.hasOwnProperty(versionID)) {
										ontology = ontologies[versionID];
									} else {
										ontology = NCBOSearchResultOntology.parse(ontologyObject);
										if (ontology) {
											ontologies[ontology.ontologyVersionID] = ontology;
											ontologiesArray.push(ontology);
										}
									}
									var concept:NCBOSearchResultConcept = NCBOSearchResultConcept.parse(conceptObject, ontology);
									if (concept) { 
										concepts.push(concept);
									}
								}
							}
						}
					} else {
						// clear the search results
						trace("Clearing last results");
						clearLastSearchResults();
					}
				}
				event = new NCBOSearchEvent(concepts, ontologiesArray, params);
			} catch (error:Error) {
				trace("Error loading last search from shared data");
				trace(error);
				event = new NCBOSearchEvent([], [], null, error);
			}
			return event;
		}
		
		
		/**
		 * Saves the which datagrid result columns are visible to the SharedObject.
		 */
		public static function saveResultColumns(columns:Array):void {
			try {
				var columnsVisible:Array = new Array(columns.length);
				for (var i:int = 0; i < columns.length; i++) {
					var col:DataGridColumn = columns[i];
					columnsVisible[i] = col.visible;
				}
				
				SharedObject.defaultObjectEncoding = ObjectEncoding.AMF3;
				var shared:SharedObject = SharedObject.getLocal(FILE, "/");
				shared.data[RESULT_COLUMNS] = columnsVisible;
				// not needed
				//shared.flush();
			} catch (error:Error) {
				trace("Error saving previous searches to shared data");
				trace(error);
			}
		}
		
		/**
		 * Loads which of the data grid result columns are visible.
		 */
		public static function loadResultColumns(columns:Array):void {
			var searches:Array = new Array();
			try {
				SharedObject.defaultObjectEncoding = ObjectEncoding.AMF3;
				var shared:SharedObject = SharedObject.getLocal(FILE, "/");
				var array:Array = (shared.data[RESULT_COLUMNS] as Array);
				if (array != null) {
					if (array.length == columns.length) {
						for (var i:int = 0; i < array.length; i++) {
							var vis:Boolean = array[i];
							DataGridColumn(columns[i]).visible = vis;
						}
					} 
					// Nov 23rd - added 2 new columns, the ontology id and ontology versions id
					// these columns are at positions 3 and 4
					else if ((array.length == 6) && (columns.length == 8)) {
						for (i = 0; i < array.length; i++) {
							vis = array[i];
							// skip positions 3 and 4
							var column:DataGridColumn = (i <= 2 ? columns[i] : columns[i+2]);
							column.visible = vis;
						}
					} else {
						trace("warning - unequal column array lengths " + array.length + " - " + columns.length);
					}
				}
			} catch (error:Error) {
				trace("Error loading result column visibilities from shared data");
				trace(error);
			}
		}
	}
}