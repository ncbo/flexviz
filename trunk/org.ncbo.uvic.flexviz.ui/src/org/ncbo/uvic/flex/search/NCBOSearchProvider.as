package org.ncbo.uvic.flex.search
{
	import ca.uvic.cs.chisel.flexviz.ExtendedFlexGraph;
	import ca.uvic.cs.chisel.flexviz.FlexGraph;
	import ca.uvic.cs.chisel.flexviz.events.GraphLayoutEvent;
	import ca.uvic.cs.chisel.flexviz.model.GroupedNode;
	import ca.uvic.cs.chisel.flexviz.model.IGraphArc;
	import ca.uvic.cs.chisel.flexviz.model.IGraphModel;
	import ca.uvic.cs.chisel.flexviz.model.IGraphNode;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.utils.getTimer;
	
	import flex.utils.StringUtils;
	import flex.utils.Utils;
	import flex.utils.ui.ContentWindow;
	import flex.utils.ui.UIUtils;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.events.CloseEvent;
	import mx.managers.BrowserManager;
	import mx.managers.CursorManager;
	import mx.managers.IBrowserManager;
	import mx.managers.PopUpManager;
	import mx.utils.StringUtil;
	
	import org.ncbo.uvic.flex.NCBORestService;
	import org.ncbo.uvic.flex.NCBOToolTipProperties;
	import org.ncbo.uvic.flex.NCBOVersion;
	import org.ncbo.uvic.flex.OntologyConstants;
	import org.ncbo.uvic.flex.Shared;
	import org.ncbo.uvic.flex.events.ConceptsExpandCollapseEvent;
	import org.ncbo.uvic.flex.events.NCBOConceptEvent;
	import org.ncbo.uvic.flex.events.NCBOConceptsEvent;
	import org.ncbo.uvic.flex.events.NCBOEvent;
	import org.ncbo.uvic.flex.events.NCBOOntologyEvent;
	import org.ncbo.uvic.flex.events.NCBOOntologyMetricsEvent;
	import org.ncbo.uvic.flex.events.NCBOOperationEvent;
	import org.ncbo.uvic.flex.events.NCBOOperationStartingEvent;
	import org.ncbo.uvic.flex.events.NCBOOperationsEvent;
	import org.ncbo.uvic.flex.events.NCBOSearchEvent;
	import org.ncbo.uvic.flex.events.NodeLabelFieldChangedEvent;
	import org.ncbo.uvic.flex.events.OntologyChangedEvent;
	import org.ncbo.uvic.flex.filter.NCBOOrphanNodeFilter;
	import org.ncbo.uvic.flex.logging.FlexVizLogger;
	import org.ncbo.uvic.flex.logging.LogService;
	import org.ncbo.uvic.flex.model.IConcept;
	import org.ncbo.uvic.flex.model.NCBOConcept;
	import org.ncbo.uvic.flex.model.NCBOOntology;
	import org.ncbo.uvic.flex.model.NCBORelationship;
	import org.ncbo.uvic.flex.model.NCBOSearchResultConcept;
	import org.ncbo.uvic.flex.model.OntologyGraphItemFactory;
	import org.ncbo.uvic.flex.ui.ConceptPropertyWindow;
	import org.ncbo.uvic.flex.ui.DebugPanel;
	import org.ncbo.uvic.flex.ui.LinkToWindow;
	import org.ncbo.uvic.flex.ui.NodeLabelChooser;
	import org.ncbo.uvic.flex.ui.OntologyChooser;
	import org.ncbo.uvic.flex.ui.OntologyMetricsWindow;
	import org.ncbo.uvic.flex.ui.SearchResultsPanel;
	import org.ncbo.uvic.flex.util.NavigateToBioPortal;
	
	/**
	 * Dispatched when the ontology id changes.
	 * @eventType = org.ncbo.uvic.flex.events.OntologyChangedEvent.ONTOLOGY_CHANGED
	 */
	[Event(name="ontologyChanged", type="org.ncbo.uvic.flex.events.OntologyChangedEvent")]

	/**
	 * Dispatched when one or more concepts are expanded.
	 * @eventType = org.ncbo.uvic.flex.events.ConceptsExpandCollapseEvent.CONCEPTS_EXPANDED
	 */
	[Event(name="conceptsExpanded", type="org.ncbo.uvic.flex.events.ConceptsExpandCollapseEvent")]
	
	/**
	 * Dispatched when one or more concepts are collapsed.
	 * @eventType = org.ncbo.uvic.flex.events.ConceptsExpandCollapseEvent.CONCEPTS_COLLAPSED
	 */
	[Event(name="conceptsCollapsed", type="org.ncbo.uvic.flex.events.ConceptsExpandCollapseEvent")]
	
	/**
	 * Dispatched when the node label field changes.
	 * @eventType = org.ncbo.uvic.flex.events.NodeLabelFieldChangedEvent.NODE_LABEL_FIELD_CHANGED
	 */
	[Event(name="nodeLabelFieldChanged", type="org.ncbo.uvic.flex.events.NodeLabelFieldChangedEvent")]
	
	
	/**
	 * This class is the main controller between the NCBO REST services and the FlexGraph.  
	 * It handles all the communications (searching etc) and builds up the graph nodes and arcs.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBOSearchProvider extends EventDispatcher
	{

		private static const EMAIL:String = "flexviz@uvic.ca";
		
		public static const WARNING_NODE_COUNT:int = 60;
		public static const GROUP_CHILDREN_COUNT:int = 10;

		public static const PROP_ROOT:String = "root";

		private var _baseServerURL:String;
		private var _ontologyVersionID:String;
		private var _ontologyVirtualID:String;
		private var _lastOntologyID:String;
		private var _service:NCBORestService;
		private var _graph:FlexGraph;
		private var factory:OntologyGraphItemFactory;
		private var _baseTitle:String = "BioPortal Ontology Visualization";
		private var _swfURL:String;
		
		private var _lastSearch:String;
		
		// UI fields and components
		private var _searchMode:SearchMode;
		private var _searchBy:SearchBy;
		private var _showOption:SearchShowOption;
		
		private var tryToGetOntologyName:Boolean;
		
		private var _warningNodeCount:int = WARNING_NODE_COUNT;
		private var _showWarning:Boolean = true;
		private var _showedChildCountWarningAlready:Boolean = false;
		private var _busy:Boolean = false;
		private var _nodeBeingExpanded:IGraphNode;
		// contains a map of the ids of the concepts that should be grouped
		private var conceptIDsToGroup:Object;
		
		private var _browser:IBrowserManager;
		private var _setBrowserTitle:Boolean;
		
		private var _userID:String;

		private var _previousSearches:ArrayCollection;
		
		private var _logger:FlexVizLogger;
		
		public function NCBOSearchProvider(graph:FlexGraph, setTitleOnBrowser:Boolean = false) {
			this._graph = graph;
			this._baseServerURL = null;
			this._ontologyVersionID = null;
			this._service = null;
			this._browser = null;
			this._setBrowserTitle = setTitleOnBrowser;
			this._userID = null;
			this.factory = new OntologyGraphItemFactory();
			this._previousSearches = new ArrayCollection();
			this.tryToGetOntologyName = true;
			
			this._searchMode = SearchMode.CONTAINS;
			this._searchBy = SearchBy.NAME;
			this._showOption = SearchShowOption.NEIGHBORHOOD;
			
			if (graph is ExtendedFlexGraph) {
				var exGraph:ExtendedFlexGraph = (graph as ExtendedFlexGraph);
				exGraph.searchBar.searchBox.dataProvider = _previousSearches;
				// turn off the default loading of all nodes into the autocomplete
				// we'll track our own previous searches
				exGraph.searchBar.loadModelElements = false;
				// also don't add the searched text - we'll add if the search has results
				exGraph.searchBar.addSearchedText = false;
			}
			
			// use a special orphan node filter to keep roots visible
			graph.filterManager.orphanNodeFilter = new NCBOOrphanNodeFilter(graph.filterManager.orphanNodeFilter.filterOn);
		}
		
		override public function toString():String {
			return "NCBOSearchProvider: " + ontologyID;
		}
		
		private function debug(msg:String):void {
			if (graph.DEBUG) {
				trace(msg);
			}
		}
				
		public function initLogger():void {
			_logger = new FlexVizLogger(this);
		}

		public function get graph():FlexGraph {
			return _graph;
		}
		
		public function get userID():String {
			return _userID;
		}
		
		public function set userID(uid:String):void {
			_userID = uid;
		}
		
		public function get swfURL():String {
			return _swfURL;
		}
		
		public function set swfURL(value:String):void {
			if (value) {
				_swfURL = value;
			}
		}
			
		public function get nodeLabelField():String {
			return factory.labelField;
		}
		
		public function set nodeLabelField(field:String):void {
			factory.labelField = field;
			if (_ontologyVersionID != null) {
				factory.reloadNodeLabels(getOntology(), graph.model);
			} 
		}
		
		public function get warningNodeCount():int {
			return _warningNodeCount;
		}
		
		public function set warningNodeCount(count:int):void {
			_warningNodeCount = count;
		}
		
		public function get baseServerURL():String {
			return _baseServerURL;
		}
		
		public function set baseServerURL(url:String):void {
			_baseServerURL = url;
			if (_service != null) {
				_service.baseURL = url;
			}
		}
		
		public function get baseTitle():String {
			return _baseTitle;
		}
		
		public function set baseTitle(title:String):void {
			_baseTitle = title;
		}
		
		public function get service():NCBORestService {
			if (_service == null) {
				// pass rest service errors onto the graph (displayed in the error pane)
				var errorFunction:Function = function(error:Error):void {
					// also removes the busy cursor, and hides the progress panel
					graph.error(error);
				};
				_service = new NCBORestService(NCBORestService.APIKEY_FLEXVIZ, NCBORestService.APP_ID_FLEXVIZ, baseServerURL, errorFunction, EMAIL);
				// use our own custom alert messages
				_service.alertErrorFunction = alertErrorMessage;
			}
			return _service;
		}
		
		public function get ontologyID():String {
			return ontologyVersionID;
		}
		
		public function get ontologyVersionID():String {
			return _ontologyVersionID;
		}
		
		public function get ontologyVirtualID():String {
			return _ontologyVirtualID;
		}
		
		/**
		 * Sets the current ontology VERSION id.
		 * Also saves this id to the client's shared object if it differs from the previous id.
		 */ 
		public function set ontologyID(id:String):void {
			if ((id == null) && (_ontologyVersionID != null)) {
				if (_service != null) {
					_service.clearConcepts(_ontologyVersionID);
				}
				_ontologyVersionID = null;
				// also need to clear the filters
				graph.filterManager.clearAllFilters();
				// also need to clear the history navigation stack
				graph.navigationManager.clear();
			} else if ((id != null) && (id != _ontologyVersionID)) {
				// need to clear the concept cache from the currently loaded ontology 
				if (_service != null) {
					_service.clearConcepts(_ontologyVersionID);
				}
				
				this._ontologyVersionID = id;
				this._ontologyVirtualID = "";
				// load the virtual id too
				if (_service && id) {
					_service.getNCBOOntology(id, function(event:NCBOOntologyEvent):void {
						if (!event.isError && event.ontology && event.ontology.ontologyID) {
							_ontologyVirtualID = event.ontology.ontologyID;
							if (graph is ExtendedFlexGraph) {
								Shared.addRecentOntology(event.ontology);
							}
						} 
					}, true, false);
				}
				
				// load the saved searches for this ontology
				if (graph is ExtendedFlexGraph) { 
					loadPreviousSearches();
				}
				
				// also need to clear the filters
				graph.filterManager.clearAllFilters();
				// also need to clear the history navigation stack
				graph.navigationManager.clear();
				// save this to the client for next time
				Shared.saveLastOntologyID(id);
				
				dispatchEvent(new OntologyChangedEvent(id, ontologyVirtualID));
			}
		}
		
		/** Loads the last ontology ID from the client's shared object.. */
		public function get lastOntologyID():String {
			if (_lastOntologyID == null) {
				// load from the client
				var last:String = Shared.loadLastOntologyID();
				if (last != null) {
					_lastOntologyID = last;
				}
			}
			return _lastOntologyID;
		}
		
		public function set lastOntologyID(id:String):void {
			_lastOntologyID = id;
		}
		
		/** Displays the current ontology's name on the graph's watermark label. */
		public function loadOntologyName():void {
			// only try to get the ontology name if it is the extended graph,
			// and if we haven't tried and failed before
			if (tryToGetOntologyName) {		// && (graph is ExtendedFlexGraph)
				var callback:Function = function(event:NCBOOntologyEvent):void {
					if (event.ontology != null) {
						graph.headerLabelText = event.ontology.displayLabel;
						var title:String = (baseTitle ? baseTitle + " - " : "") + event.ontology.displayLabel;
						setBrowserTitle(title);
					} else {
						graph.headerLabelText = "";
						tryToGetOntologyName = false;
						setBrowserTitle(baseTitle);
					}
				};
				// don't alert any errors for this request
				service.getNCBOOntology(ontologyID, callback, true, false);
			}
		}
		
		protected function setBrowserTitle(title:String):void {
			if (_setBrowserTitle) {
				browserManager.setTitle(title);
			}
		}
		
		protected function get browserManager():IBrowserManager {
			if (_browser == null) {
				_browser = BrowserManager.getInstance();
				_browser.init("", baseTitle);
			}
			return _browser;
		}
		
		public function set searchBoxText(text:String):void {
			if (graph is ExtendedFlexGraph) {
				var extGraph:ExtendedFlexGraph = (graph as ExtendedFlexGraph);
				extGraph.searchBar.searchText = text;
			}
		}

		public function get searchMode():SearchMode {
			return _searchMode;
		}
		
		public function set searchMode(mode:SearchMode):void {
			_searchMode = mode;
		}
		
		public function get searchBy():SearchBy {
			return _searchBy; 
		}

		public function set searchBy(by:SearchBy):void {
			_searchBy = by;
		}
		
		public function get showOption():SearchShowOption {
			return _showOption;
		}
		
		public function set showOption(show:SearchShowOption):void {
			if (show != _showOption) {
				_showOption = show;
				Shared.saveSearchShowOption(show);
			}
		}
		
		private function error(msg:String = "", error:Error = null):void {
			trace("Error: " + msg);
			if (error) {
				trace(error.message);
			}
		}
		
		/**
		 * Overrides the default rest service alert error dialog to handle the special case where
		 * an ontology has been deprecated.  In this case it asks the user if he/she wants to load a 
		 * different version of the current ontology.
		 */
		public function alertErrorMessage(msg:String, title:String = "Error", closeHandler:Function = null):void {
			// special check for when an ontology is deprecated - let the user open a newer version
			if (StringUtils.startsWith(msg, "Ontology has been deprecated")) {
				var closeWrapper:Function = function(event:CloseEvent):void {
					closeHandler(event);
					if (event.detail == Alert.YES) {
						graph.callLater(chooseOntologyVersion);
					}
				};
				msg = msg + "\nDo you want to load a different version?";
				Alert.show(msg, title, Alert.YES | Alert.NO, graph, closeWrapper);
				
			} else {
				Alert.show(msg, title, Alert.OK, null, closeHandler);
			}
		}
		
		private function focusSearchBox():void {
			if (graph is ExtendedFlexGraph) {
				(graph as ExtendedFlexGraph).searchBar.searchBox.setFocus();	
			}
		}
		
		private function setSearchResults(results:int, error:Boolean = false, errorMsg:String = null):void {
			if (graph is ExtendedFlexGraph) {
				var lbl:String;
				if (error) {
					lbl = errorMsg;
				} else {
					lbl = "Found " + results + " matching term" + (results == 1 ? "" : "s");	
				}
				(graph as ExtendedFlexGraph).searchBar.setSearchResultsLabel(lbl, error)	
			}
		}

		public function changeOntology(id:String, clear:Boolean = true, showOntRoots:Boolean = true, 
									   loadOntName:Boolean = true):void {
			if (id != ontologyVersionID) {
				ontologyID = id;
				if (clear) {
					graph.clear();
				}
				if (showOntRoots) {
					showRoots();
				}
				if (loadOntName) {
					loadOntologyName();
				}
			}
		}
		
		public function getOntology(id:String = null):NCBOOntology {
			if ((id == null) && (ontologyID != null)) {
				id = ontologyID;
			}
			if (id != null) {
				return service.getOntology(id);
			}
			return null;
		}
		
		public function getConcept(id:String):NCBOConcept {
			if ((ontologyID != null) && (service != null)) {
				return service.getConceptFromCache(ontologyID, id);
			}	
			return null;
		}
		
		public function getRelationship(id:String):NCBORelationship {
			if ((ontologyID != null) && (service != null)) {
				return service.getRelationshipFromCache(ontologyID, id);
			}
			return null;
		}
		
		public function get selectedConcept():NCBOConcept {
			var node:IGraphNode = graph.selectedNode;
			if (node) {
				return getConcept(node.id);
			}
			return null;
		}
		
		public function get selectedConcepts():Array {
			var concepts:Array = [];
			var nodes:Array = graph.selectedNodes;
			for each (var node:IGraphNode in nodes) {
				var concept:NCBOConcept = getConcept(node.id);
				if (concept) {
					concepts.push(concept);
				}
			}
			return concepts;
		}
		
		/**
		 * Determines if a concept can be expanded.  This will return true if a concept
		 * has children or parents that are not in the graph.
		 */
		public function canBeExpanded(conceptID:String):Boolean {
			var concept:NCBOConcept = getConcept(conceptID);
			if (concept != null) {
				if (!childrenVisible(concept) || !parentsVisible(concept)) {
					return true;
				} 
			}
			return false;
		}
		
		public function get nodeBeingExpanded():IGraphNode {
			return _nodeBeingExpanded;
		}
		
		public function clearBeingExpanded():void {
			_nodeBeingExpanded = null;
		}
		
		public function get previousSearches():ArrayCollection {
			return _previousSearches;
		}
		
		/**
		 * Saves the searches for a given ontology to the shared data.
		 */
		public function saveSearch(txt:String):void {
			if (!previousSearches.contains(txt)) {
				previousSearches.addItem(txt);
				if (previousSearches.length > 10) {
					previousSearches.removeItemAt(0);
				}
				Shared.savePreviousSearches(previousSearches.source.slice(), ontologyID);
			}	
		}
		
		/**
		 * Loads the searches for a given ontology from the shared data.
		 */
		private function loadPreviousSearches():void {
			var searches:Array = Shared.loadPreviousSearches(ontologyID);
			previousSearches.source = searches.slice();
			previousSearches.refresh();
		}
		
		public function get lastSearch():String {
			return _lastSearch;
		}
		
		public function performLastSearch():void {
			if (lastSearch != null) {
				performSearch(lastSearch);
			}
		}
		
		public function performSearch(text:String):void {
			text = StringUtil.trim(text);
			_lastSearch = text;
			if (searchBy == SearchBy.ID) {
				performSearchByID(text);
			} else {
				performSearchByName(text, searchMode);
			}
		}
		
		public function performSearchByID(idText:String, clearGraph:Boolean = true, 
							select:Boolean = true, match:Boolean = true, save:Boolean = true):void {
			if ((ontologyID != null) && (service != null)) {
				if (idText.length > 0) {
					graph.startProgress("Searching for '" + idText + "'");
					service.getConceptByID(ontologyID, idText, function(event:NCBOConceptEvent):void {
						setSearchResults(1);
						var callback:Function = function():void {
							if (event.concept) {
								if (!match) {
									graph.matchingNodes = null;
								}
								if (select) {
									graph.selectedNode = graph.model.getNode(event.concept.id);
								}
							}
						};
						var concepts:Array = [];
						// the concept will be null if it is filtered out (e.g. ":SYSTEM-CLASS")
						if (event.concept) {
							concepts.push(event.concept);
						}
						showNeighbors(concepts, showOption, clearGraph, callback);
						// save the searched for ID
						if (save && (event.concepts.length == 1)) {
							saveSearch(idText);
						}
					});
				} else {
					error("Please enter a search string");
					setSearchResults(0, true, "Please enter a search string"); 
					focusSearchBox();
				}
			}
		}

		public function performSearchByName(nameText:String, mode:SearchMode):void {
			if ((ontologyID != null) && (service != null) && (nameText != null)) {
				nameText = StringUtil.trim(nameText);
				if (nameText.length > 0) {
					graph.startProgress("Searching for '" + nameText + "'");
					var ontology:NCBOOntology = getOntology(ontologyID);
					service.getConceptsByName(ontology, nameText, mode, handleSearchResults);
				} else {
					error("Please enter a search string");
					setSearchResults(0, true, "Please enter a search string"); 
					focusSearchBox();
				}
			}
		}
		
		private function handleSearchResults(searchEvent:NCBOSearchEvent):void {
			var ontologies:Array = searchEvent.ontologies;
			var concepts:Array = searchEvent.concepts.slice();
   			
   			// shouldn't be necessary - the search should only be on one ontology
   			// select only the concepts from the current ontology
			if (ontologies.length > 1) {
				var ontology:NCBOOntology = null;
				for (var i:int = 0; i < ontologies.length; i++) {
					var o:NCBOOntology = (ontologies[i] as NCBOOntology);
					if (o.id == ontologyID) {
						ontology = o; 
						break;
					}
				}
				if (ontology) {
					concepts = concepts.filter(function(concept:NCBOConcept, i:int, a:Array):Boolean {
						return ontology.hasConcept(concept.id);
					});
					trace("Filtered the search result terms " + concepts.length + "/" + searchEvent.concepts.length);
				} else {
					concepts = [];
   					trace("Unexpected number of search result ontologies!  Expected 1, but got " + ontologies.length);
   					trace("No terms were found for the current ontology: " + ontologyID);
				}
			}
			
   			var hits:int = concepts.length;
    		if (hits > 0) {
				setSearchResults(hits);
				// save the search
   				saveSearch(searchEvent.searchText);
    			
    			if (hits == 1) {
    				loadSearchResultConcepts([ NCBOSearchResultConcept(concepts[0]).id ], searchEvent.searchParams);
    			} else {
    				// show a popup window that lets the user choose the results to show
					var title:String = "Search Results for '" + searchEvent.searchParams.searchText + "'";
					var resultsWindow:SearchResultsPanel = new SearchResultsPanel();
					resultsWindow.show(concepts, title, graph, function(event:CloseEvent):void {
						if (event.detail == ContentWindow.OK) {
							var conceptIDs:Array = new Array();
							var concepts:Array = resultsWindow.selectedResults;
				    		for (var i:int = 0; i < concepts.length; i++) {
			    				conceptIDs.push(NCBOSearchResultConcept(concepts[i]).id);
			    			}
			    			// bug #1674 - path to root doesn't do anything
			    			showOption = resultsWindow.showOption;
			    			loadSearchResultConcepts(conceptIDs, searchEvent.searchParams);
						} else {
							showSearchResults([], searchEvent.searchParams, false);	// cancel
						}
					}, showOption);
    			}
    		} else {
    			showSearchResults([], searchEvent.searchParams);
    		}
		}
		
		private function loadSearchResultConcepts(conceptIDs:Array, searchParams:SearchParams, showAlert:Boolean = true):void {
			// Convert the NCBOSearchResultConcepts into NCBOConcepts
			var op:LoadConceptsOperation = new LoadConceptsOperation(service, ontologyID, conceptIDs, 
				function(opEvent:NCBOOperationsEvent):void {
					var concepts:Array = opEvent.matchingConcepts;
					// log the selected search results first
					if (concepts.length <= 2) {
						for each (var concept:NCBOConcept in concepts) { 
							FlexVizLogger.logSearchResult(concept, ontologyVirtualID);
						}
					} else {
						trace("[LOG] warning - more than 2 search result terms were selected, skipping logging");
					}

					// now layout the concepts
					showSearchResults(concepts, searchParams, showAlert);
				});
			runOperation(op);			
		}
		
		private function showSearchResults(concepts:Array, searchParams:SearchParams, showAlert:Boolean = true):void {
			if (concepts.length > 0) {
				showNeighbors(concepts, showOption);
			} else {
				graph.hideProgress();
				if (showAlert) {
					Alert.show("No terms found that match '" + searchParams.searchText + "'", "No results");
				}
			}
		}
		
		private function set busy(working:Boolean):void {
			if (working != _busy) {
				_busy = working;
				if (_busy) {
					CursorManager.setBusyCursor();
				} else {
					CursorManager.removeBusyCursor();					
				}
			}
		}
		
		private function get busy():Boolean {
			return _busy;
		}
				
		/**
		 * Calls IRestServiceOperation.start()
		 * Also prints out a debug message about the run time of the operation if in debug mode.
		 * If the user clicks the progress stop button then the operation is stopped.
		 * If the operation loads too many nodes a dialog will warn the user.
		 */
		private function runOperation(op:IRestServiceOperation):void {
			if (graph.DEBUG) {
				var listener:Function = function(event:NCBOEvent):void {
					op.removeEventListener(NCBOOperationEvent.OPERATION_FINISHED, listener);
					debug(Utils.getSimpleClassName(op) + " time: server=" + event.serverTime + " ms, parse=" + 
						event.parseTime + " ms, total=" + event.time); 
				};
				op.addEventListener(NCBOOperationEvent.OPERATION_FINISHED, listener);
			}
			// show the stop button if the operation can be stopped
			graph.progressPanel.showStopButton = op.canBeStopped;
			if (op.canBeStopped) {
				var progressStoppedListener:Function = function(event:Event):void {
					graph.removeEventListener(FlexGraph.PROGRESS_STOPPED, progressStoppedListener);
					op.stop();
				};
				graph.addEventListener(FlexGraph.PROGRESS_STOPPED, progressStoppedListener);
				var finishedListener:Function = function(event:NCBOEvent):void {
					op.removeEventListener(NCBOOperationEvent.OPERATION_FINISHED, finishedListener);
					graph.removeEventListener(FlexGraph.PROGRESS_STOPPED, progressStoppedListener);
					graph.progressPanel.showStopButton = false;
				};
				op.addEventListener(NCBOOperationEvent.OPERATION_FINISHED, finishedListener);
				
				// prompt the user when the operation has loaded a lot of terms
				if (op is SequenceOperation) {
					var promptHandler:Function = function(event:NCBOOperationStartingEvent):void {
						// count how many terms have been loaded so far
						var nodeCount:int = event.parentOperation.neighborConcepts.length;
						// warn when we reach 10 less than the warning count, otherwise a similar dialog pops again
						if (_showWarning && (nodeCount >= (warningNodeCount-10))) {
							// pause the operation and prompt the user
							event.pauseOperation();
							var callback:Function = function(yes:Boolean):void {
								if (yes) {
									event.continueOperation();	// continues the operation
								} else {
									event.stopOperation();	// calls the callback
								}
							};
							showWarningDialog("Found " + nodeCount + " terms so far, do you want to continue?\nIt may take a long time to finish.", callback);
						}
					};
					(op as SequenceOperation).addEventListener(NCBOOperationStartingEvent.OPERATION_STARTING, promptHandler);
				}
			}
			// finally start the operation
			op.start();
		}

		/**
		 * Runs the last layout if changed is greater than zero, otherwise the progress is hidden.
		 * Also possibly repaints a single node, or all the nodes.
		 * It will also center the graph on a focussed node after the layout animation has finished.
		 */
		private function runLayout(changed:int = 0, focusNode:IGraphNode = null, 
						repaintNode:IGraphNode = null, repaintAllNodes:Boolean = false):void {
			// remove busy cursor if it was set
			busy = false;
			if (changed > 0) {
				var startTime:int = getTimer();
				var finished:Function = function(event:GraphLayoutEvent):void {
					graph.removeEventListener(GraphLayoutEvent.GRAPH_LAYOUT_FINISHED, finished);
					if (repaintNode != null) {
						graph.repaintNode(repaintNode);
					} 
					if (repaintAllNodes) {
						graph.repaintNodes();
					} 
					// now that the layout is finished, center on the focussed node
					if (focusNode != null) {
						graph.centerOnNode(focusNode);
					}
					var layoutTime:int = getTimer() - startTime;
					debug("Layout animation time: " + layoutTime + " ms");
				};
				graph.addEventListener(GraphLayoutEvent.GRAPH_LAYOUT_FINISHED, finished);
				
				// it is not very smooth to keep the focus node centered during the layout animation
				// so instead we focus on the node after the layout has finished (above)
				graph.runLayout(null/*, focusNode*/);	
			} else {
				graph.hideProgress();
			}
		}
	
		public function showDebugPanel():void {
			var debugPanel:DebugPanel = new DebugPanel();
			debugPanel.service = this.service;
			debugPanel.version = NCBOVersion.VERSION_DATE;
			PopUpManager.addPopUp(debugPanel, graph, true); 
			PopUpManager.centerPopUp(debugPanel);
			debugPanel.addEventListener(CloseEvent.CLOSE, function(event:CloseEvent):void {
				PopUpManager.removePopUp(debugPanel);
				baseServerURL = service.baseURL;
			});
		}
		
		public function downloadOntology():void {
			service.getNCBOOntology(ontologyID, function(event:NCBOOntologyEvent):void {
				if (!event.isError) {
					NavigateToBioPortal.downloadOntology(event.ontology);
				}
			}, true, false);
		}
		
		public function showOntologyMetrics():void {
			service.getOntologyMetrics(ontologyID, function(event:NCBOOntologyMetricsEvent):void {
				if (event.metrics) {
					OntologyMetricsWindow.show(graph, event.metrics, "blueWindow");
				} else {
					trace("Error showing metrics: " + event.error);
				}
			});
		}
		
		public function chooseOntology():void {
			graph.startProgress("Loading ontologies");

			var currentOntology:NCBOOntology = getOntology();
			// try to get the last ontology
			if (!currentOntology) {
				var last:String = lastOntologyID; 
				if (last != null) {
					currentOntology = getOntology(last);
				}
			}
			OntologyChooser.show(graph, ontologyChosen, service, currentOntology, false);
		}
		
		public function chooseOntologyVersion():void {
			if (ontologyID) {
				graph.startProgress("Loading ontology versions");
				service.getNCBOOntology(ontologyID, function(event:NCBOOntologyEvent):void {
					var ontology:NCBOOntology = event.ontology;
					if (ontology) {
						OntologyChooser.show(graph, ontologyChosen, service, ontology, true);
	    				LogService.logOntologyEvent(ontology, "versions");
					} else {
						graph.hideProgress();
					}
				}, true, false);
			}
		}
				
		private function ontologyChosen(newOntology:NCBOOntology):void {
			if (newOntology) {
				var currentOntology:NCBOOntology = getOntology();
				if ((currentOntology == null) || (newOntology.id != currentOntology.id)) {
					changeOntology(newOntology.id);
				}
			}
			graph.hideProgress();
		}
		
		public function chooseLabelField():void {
			// load all the available tooltip properties from cached concepts in the ontology
			var allProps:Array = new Array();
			var ontology:NCBOOntology = getOntology();
			if (ontology != null) {
				allProps = ontology.collectConceptProperties();
				// add the predefined properties to the front of the array
				allProps.unshift(NCBOToolTipProperties.PARENT_COUNT);
				allProps.unshift(NCBOToolTipProperties.CHILD_COUNT);
				allProps.unshift(NCBOToolTipProperties.TYPE);
				allProps.unshift(NCBOToolTipProperties.NAME);
				allProps.unshift(NCBOToolTipProperties.ID);
			}
			var defaultProp:String = NCBOToolTipProperties.NAME;
			var currentProp:String = nodeLabelField;
			if (currentProp == null) {
				currentProp = defaultProp;
			}
			
			var title:String = "Node Label Properties";
			var labelChooser:NodeLabelChooser = new NodeLabelChooser(title, allProps, currentProp, defaultProp);
			
			// this gets called after the window closes
			labelChooser.closeFunction = function(okClicked:Boolean = false):void {
				var selectedProp:String = labelChooser.selectedProperty;
				if (okClicked && (selectedProp != currentProp)) {
					nodeLabelField = selectedProp;
					dispatchEvent(new NodeLabelFieldChangedEvent(nodeLabelField));
				}
				PopUpManager.removePopUp(labelChooser);
			}
			
			PopUpManager.addPopUp(labelChooser, graph, true);
			PopUpManager.centerPopUp(labelChooser);
			labelChooser.setFocus();
		}
		
		public function showSelectedNodeProperties():void {
			var selected:Array = graph.selectedNodes;
			if (selected.length > 0) {
				var node:IGraphNode = IGraphNode(selected[0]);
				var concept:NCBOConcept = getConcept(node.id);
				showConceptProperties(concept);
			}
		}
		
		public function showConceptProperties(concept:NCBOConcept, loadNeighbors:Boolean = true):void {
			if (concept) {
				// bug #1667 - need to load the full details for the concept
				if (loadNeighbors && !concept.hasLoadedNeighbors) {
					var callback:Function = function(event:NCBOConceptEvent):void {
						showConceptProperties(event.concept, false);
					};
					service.getConceptByID(ontologyID, concept.id, callback, true, false);
				} else {
					var window:ConceptPropertyWindow = new ConceptPropertyWindow(concept);
					var closeHandler:Function = function(event:CloseEvent):void {
						PopUpManager.removePopUp(window);
					};
					window.addEventListener(CloseEvent.CLOSE, closeHandler);
					PopUpManager.addPopUp(window, DisplayObject(graph), true);
					PopUpManager.centerPopUp(window);
					
					FlexVizLogger.logProperties(concept, ontologyVirtualID);
				}
			}			
		}
		
		public function showLinkToWindow(basic:Boolean = false):void {
			var concept:NCBOConcept = selectedConcept;
			if (concept) {
				// load the ontology (needed for the virtual ontology id)
				service.getNCBOOntology(ontologyID, function(event:NCBOOntologyEvent):void {
					var url:String = getConceptLink(concept.id, basic);
					var bpURL:String = NavigateToBioPortal.getBioPortalURL(ontologyID, concept.id);
					var ontologyVersionID:String = ontologyID;
					var ontologyVirtualID:String = (event.ontology ? event.ontology.ontologyID : "");
					LinkToWindow.showWindow(graph, url, bpURL, concept.name, ontologyVersionID, ontologyVirtualID);
					FlexVizLogger.logLinkTo(concept, ontologyVirtualID);
				}, true, false);
				
			}
		}
		
		/**
		 * Returns the URL of the concept in FlexViz (to the html file).
		 */
		public function getConceptLink(conceptID:String = "", basic:Boolean = false):String {
			var urlParams:URLVariables = new URLVariables();
			urlParams["ontology"] =  ontologyID;
			urlParams["virtual"] = false;	// important
			if (conceptID.length > 0) {
				urlParams["nodeid"] = conceptID;
			}
			if (basic && (showOption.name == SearchShowOption.HIERARCHY_TO_ROOT.name)) {
				urlParams["show"] = showOption.name;
			}
			// parameters to skip:
			var skip:Array = [ "v", "debug", "log", "show", "doi" ];

			// add in the browser params and flashvars
			var params:Object = Utils.getCombinedParameters();
			for (var key:String in params) {
				if (!urlParams.hasOwnProperty(key) && (skip.indexOf(key) == -1)) {
					var value:String = params[key];
					if (value) {
						urlParams[key] = params[key];
					}
				}
			}
			
			var url:String = swfURL;
			if (url) {
				var qm:int = url.indexOf("?");
				if (qm != -1) {
					url = url.substr(0, qm);
				}
				var hash:int = url.indexOf("#");
				if (hash != -1) {
					url = url.substr(0, hash);
				}
				url = url + (url.indexOf("?") == -1 ? "?" : "&") + urlParams.toString();
				trace("Concept link: " + url);
			}
			return url;
		}
		
		public function showSelectedConceptInNewWindow(basic:Boolean = false):void {
			var selectedNode:IGraphNode = graph.selectedNode;
			if (selectedNode) {
				var concept:NCBOConcept = getConcept(selectedNode.id);
				if (concept) {
					var app:Application = (Application.application as Application);
					var url:String = app.url;
					if (app.loaderInfo) { 
						url = app.loaderInfo.url;
					}
					var lastSlash:int = url.lastIndexOf("/");
					if (lastSlash != -1) {
						url = url.substr(0, lastSlash + 1);
						var swf:String = (basic ? "BasicFlexoViz.swf" : "FlexoViz.swf");
						url += swf; 
					} else {
						var qm:int = url.lastIndexOf("?");
						if (qm != -1) {
							url = url.substr(0, qm);
						}
					}
					url += "?ontology=" + ontologyID + "&nodeid=" + concept.id;
					if (basic) {
						url += "&show=" + showOption.name;
					}
					//trace(url);
					navigateToURL(new URLRequest(url), NavigateToBioPortal.NEW_WINDOW);
				}
			}
		}
		
		public function showRoots(clearGraph:Boolean = true):void {
			if ((ontologyID != null) && (service != null)) {
				// the only allowed values are: Children, or Hierarchy To Root
				var option:SearchShowOption = showOption;
				if (showOption != SearchShowOption.HIERARCHY_TO_ROOT) {
					option = SearchShowOption.CHILDREN;
				}
				
				graph.startProgress("Showing roots...");
				service.getTopLevelNodes(ontologyID, function(event:NCBOConceptsEvent):void {
					// mark these concepts are being roots
					for each (var concept:IConcept in event.concepts) {
						concept.setProperty(PROP_ROOT, true);
					}
					if (event.concepts.length > 1) {
						// just show the roots, no children
						buildGraphNoWarning([], event.concepts, clearGraph);
					} else {
						// expand the only root to show the children
						showNeighbors(event.concepts, option, clearGraph);
					}
				});
				
				FlexVizLogger.logOntologyRoots(getOntology());
			}
		}
		
		public function showChildren(concepts:Array, clearGraph:Boolean = false, callback:Function = null):void {
			showNeighbors(concepts, SearchShowOption.CHILDREN, clearGraph, callback);
		}
		
		public function showParents(concepts:Array, clearGraph:Boolean = false, callback:Function = null):void {
			showNeighbors(concepts, SearchShowOption.PARENTS, clearGraph, callback);
		}
		
		public function showHierarchyToRoot(concepts:Array, clearGraph:Boolean = false, callback:Function = null):void {
			showNeighbors(concepts, SearchShowOption.HIERARCHY_TO_ROOT, clearGraph, callback);
		}
		
		public function showNeighbors(concepts:Array, show:SearchShowOption, clearGraph:Boolean = true, callback:Function = null):void {
			if ((ontologyID != null) && (service != null) && (concepts != null) && (concepts.length > 0)) {
				busy = true;
				var progressMsg:String;

				var opClass:Class;
				if (show == SearchShowOption.CHILDREN) {
					progressMsg = "children";
					opClass = LoadChildrenOperation;
				} else if (show == SearchShowOption.PARENTS) {
					progressMsg = "parents";
					opClass = LoadParentsOperation;
				} else if (show == SearchShowOption.HIERARCHY_TO_ROOT) {
					progressMsg = "hierarchy to root";
					opClass = LoadHierarchyToRootOperation;
				} else { //if (show == SearchShowOption.NEIGHBORHOOD) {
					progressMsg = "neighborhood";
					opClass = LoadNeighborhoodOperation;
				}
				graph.updateProgress("finding " + progressMsg);
				
				if (concepts.length == 1) {
					var type:String = (clearGraph ? "focus on " : "show ") + progressMsg;
					FlexVizLogger.logNeighbors(concepts[0], ontologyVirtualID, type); 
				}
				
				var finishedCallback:Function = function():void {
					busy = false;
					graph.hideProgress();
					if (callback != null) {
						callback();
					}
				};
				
				// need to warn the user if loading too many children
				if (_showWarning && ((show == SearchShowOption.CHILDREN) || 
					(show == SearchShowOption.NEIGHBORHOOD))) {
					var conceptCount:int = 0;
					for (var i:int = 0; i < concepts.length; i++) {
						var concept:NCBOConcept = NCBOConcept(concepts[i]);
						if (!concept.hasLoadedNeighbors) {
							conceptCount += concept.childCount;
						} else if (concept.childCount > 0) {
							var visChildren:uint = childrenVisibleCount(concept);
							var hiddenChildren:uint = concept.childCount - visChildren;
							conceptCount += hiddenChildren;
						}
					}
					if (conceptCount >= warningNodeCount) {
						var lbl:String = "About to display " + conceptCount + " nodes on the screen.\n" + 
							"This may take a long time - do you want to continue?";
						var warningCallback:Function = function(yes:Boolean):void {
							if (yes) {
								_showedChildCountWarningAlready = true;
								showNeighborsNoWarning(concepts, opClass, clearGraph, finishedCallback);
							} else {
								finishedCallback();
							}
						};
						showWarningDialog(lbl, warningCallback);
					} else {
						showNeighborsNoWarning(concepts, opClass, clearGraph, finishedCallback);
					}
		
					// notify listeners that concepts were expanded
					dispatchEvent(new ConceptsExpandCollapseEvent(ConceptsExpandCollapseEvent.CONCEPTS_EXPANDED, concepts));
					
				} else {
					showNeighborsNoWarning(concepts, opClass, clearGraph, finishedCallback);
				}				
			} else {
				graph.hideProgress();
				if (callback != null) {
					callback();
				}
			}
		}
		
		private function showNeighborsNoWarning(concepts:Array, opClass:Class, clearGraph:Boolean = true, 
												callback:Function = null):void {
			var op:IRestServiceOperation = new MultipleConceptsOperation(service, ontologyID, concepts, opClass, 
				function(event:NCBOOperationsEvent):void {
					buildGraph(event.matchingConcepts, event.neighborConcepts, clearGraph, callback);
				});
			runOperation(op);
		}
		
		public function showChildrenOfSelected(clearGraph:Boolean = false):void {
			showNeighborsOfSelected(SearchShowOption.CHILDREN, clearGraph);
		}
		
		public function showParentsOfSelected(clearGraph:Boolean = false):void {
			showNeighborsOfSelected(SearchShowOption.PARENTS, clearGraph);
		}
				
		public function showHierarchyToRootOfSelected(clearGraph:Boolean = false):void {
			// ensure that the entire hierarchy is displayed
			showNeighborsOfSelected(SearchShowOption.HIERARCHY_TO_ROOT, clearGraph);
		}
		
		public function showNeighborsOfSelected(mode:SearchShowOption, clearGraph:Boolean = false, callback:Function = null):void {
			var concepts:Array = new Array();
			var selectedNodes:Array = graph.selectedNodes;
			
			// if the only selected node is a grouped node, then just ungroup it
			if ((selectedNodes.length == 1) && (selectedNodes[0] is GroupedNode)) {
				graph.ungroupNode(selectedNodes[0] as GroupedNode, true);
				if (callback != null) {
					callback();
				}
				return;
			}
			
			for (var i:int = 0; i < selectedNodes.length; i++) {
				var node:IGraphNode = IGraphNode(selectedNodes[i]);
				var concept:NCBOConcept = getConcept(node.id);
				if (concept) {
					concepts.push(concept);
				}
			}
			
			// highlight the hierarchy to root
			if ((mode == SearchShowOption.HIERARCHY_TO_ROOT) && (callback == null)) {
				callback = showHierarchyToRootCallback;
			}
			
			var title:String = (clearGraph ? "Focusing On " : "Showing ") + mode.toString();
			graph.startProgress(title);
			showNeighbors(concepts, mode, clearGraph, callback);
		}
		
		private function showHierarchyToRootCallback():void {
			// highlight the path the root
			var arcs:Array = new Array();
			// IGraphNodes
			var selNodes:Array = graph.selectedNodes;
			for (var i:int = 0; i < selNodes.length; i++) {
				var node:IGraphNode = IGraphNode(selNodes[i]);
				var concept:NCBOConcept = getConcept(node.id);
				if (concept) {
					var map:Object = new Object();
					collectAncestorRelationships(concept, map);
					for (var relID:String in map) {
						var arc:IGraphArc = graph.model.getArc(relID);
						if (arc) {
							arcs.push(arc);
						}
					}
				}
			}
			graph.highlightedArcs = arcs;
		}
		
		private function collectAncestorRelationships(concept:NCBOConcept, map:Object):void {
			for (var i:int = 0; i < concept.relationships.length; i++) {
				var rel:NCBORelationship = NCBORelationship(concept.relationships[i]);
				// select all the relationships that have the concept as the destination, and aren't self loops
				// this will select all the parent - child relationships
				if ((rel.destination == concept) && (rel.source != concept) && !map.hasOwnProperty(rel.id)) {
					map[rel.id] = rel;
					// recurse on the parent concept
					collectAncestorRelationships(rel.source, map);
				}
			}
		}
		
		public function removeSelected():void {
			var selected:Array = graph.selectedNodes;
			if (selected.length > 0) {
				for (var i:int = 0; i < selected.length; i++) {
					var node:IGraphNode = IGraphNode(selected[i]);
					graph.model.removeNode(node);	// also de-selects
				}
				graph.repaintNodes();
			}
		}
		
		public function removeParentsOfSelected():void {
			var selected:Array = graph.selectedNodes;
			var removedCount:int = 0;
			for (var i:int = 0; i < selected.length; i++) {
				var node:IGraphNode = IGraphNode(selected[i]);
				var concept:NCBOConcept = getConcept(node.id);
				if ((concept != null) && concept.hasLoadedNeighbors && concept.hasParents) {
					for (var j:int = 0; j < concept.parents.length; j++) {
						var parent:NCBOConcept = NCBOConcept(concept.parents[j]);
						if (graph.model.removeNodeByID(parent.id, true)) {
							removedCount++;
						}							
					}
					graph.repaintNode(node);	// update the "+" sign
				}
			}
			// TODO do we actually want to run the layout again?
			runLayout(removedCount);
		}
		
		/**
		 * Removes all the children or descendants of the selected nodes.
		 * @param directChildrenOnly if true then only the direct children are removed, if false
		 * 	then all loaded descendants are removed (default).
		 */
		public function removeChildrenOfSelected(directChildrenOnly:Boolean = false):void {
			var selected:Array = graph.selectedNodes;
			var removedCount:int = 0;
			for (var i:int = 0; i < selected.length; i++) {
				var node:IGraphNode = IGraphNode(selected[i]);
				var concept:NCBOConcept = getConcept(node.id);
				if ((concept != null) && concept.hasLoadedNeighbors && concept.hasChildren) {
					var children:Array = (directChildrenOnly ? concept.children : concept.loadedDescendants);
					for (var j:int = 0; j < children.length; j++) {
						var child:NCBOConcept = NCBOConcept(children[j]);
						if (graph.model.removeNodeByID(child.id, true)) {
							removedCount++;
						}							
					}
					graph.repaintNode(node);	// update the "+" sign
				}
			}
			runLayout(removedCount);
		}
		
		/**
		 * Collects all the loaded children or descendants of the node and groups them together
		 * as a new GroupedNode.  It also includes the root node as well by default.
		 * @param node the node whose children or descendants will be grouped
		 * @param directChildrenOnly if true then only the direct children are grouped, if false
		 * 	then all loaded descendants are grouped (default)
		 * @param includeRoot if true (default) then the root node is grouped as well
		 */ 
		public function groupSubgraph(root:IGraphNode, directChildrenOnly:Boolean = false, includeRoot:Boolean = true):void {
			var concept:NCBOConcept = null;
			if (root) { 
				concept = getConcept(root.id); 
			}
			if (concept && concept.hasLoadedNeighbors) {
				var children:Array = (directChildrenOnly ? concept.children : concept.loadedDescendants);
				if (children.length > 0) {
					var nodes:Array = [];
					var location:Point = null;
					if (includeRoot) {
						// add this node first
						nodes.push(root);
						location = new Point(root.x, root.y);
					}
					for each (var subConcept:NCBOConcept in children) {
						var subNode:IGraphNode = graph.model.getNode(subConcept.id);
						if (subNode && subNode.visible) {
							nodes.push(subNode);
						}
					}
					graph.groupNodes(nodes, root.text + " subgraph", OntologyConstants.GROUPED_CONCEPTS, true, location);
				}
			}
		}
		
		/**
		 * Selects the root node and all its visible descendant nodes.
		 */
		public function selectSubgraph(root:IGraphNode):void {
			var concept:NCBOConcept = null;
			if (root) { 
				concept = getConcept(root.id); 
			}
			if (concept && concept.hasLoadedNeighbors) {
				var descendants:Array = concept.loadedDescendants;
				if (descendants.length > 0) {
					var selectedNodes:Array = [ root ];
					// add this node first
					selectedNodes.push(root);
					for each (var subConcept:NCBOConcept in descendants) {
						var subNode:IGraphNode = graph.model.getNode(subConcept.id);
						if (subNode && subNode.visible) {
							selectedNodes.push(subNode);
						}
					}
					graph.selectedNodes = selectedNodes;
				}
			}
		}
		
		/**
		 * This function will determine whether the entire neighborhood of the node is displayed.
		 * If so, then all the descendents of the node are hidde.
		 * Otherwise each missing neighbor node is displayed.
		 * @param expandOnly if true then we will only expand if necessary, and will not collapse
		 * @param collapseOnly if true then we will only collapse if neccesary, and will not expand
		 */
		public function toggleNeighborhood(node:IGraphNode, expandOnly:Boolean = false, 
											collapseOnly:Boolean = false):void {
			var concept:NCBOConcept = getConcept(node.id);
			if (concept == null) {
				debug("WARNING - couldn't get term from cache with id '" + node.id + "'");
				return;
			}
			var childrenShowing:Boolean = childrenVisible(concept);
			var parentsShowing:Boolean = parentsVisible(concept); 
			if ((childrenShowing && parentsShowing) || collapseOnly) {
				// collapse the visible descendants
				if (!expandOnly) {
					busy = true;
					// hide the entire descendant sub graph
					var removed:int = 0;
					var cachedDescendants:Array = concept.loadedDescendants;
					graph.startProgress("Hiding descendants of " + node.text, cachedDescendants.length);
					for (var i:int = 0; i < cachedDescendants.length; i++) {
						var desc:NCBOConcept = NCBOConcept(cachedDescendants[i]);
						graph.updateProgress(desc.name, i + 1, cachedDescendants.length);
						if (graph.model.removeNodeByID(desc.id, true)) {
							removed++;
						}
					}
					runLayout(removed, node, node);
					
					// notify listeners that the concept was collapsed
					dispatchEvent(new ConceptsExpandCollapseEvent(ConceptsExpandCollapseEvent.CONCEPTS_COLLAPSED, [ concept ]));
					
					FlexVizLogger.logExpandCollapse(concept, ontologyVirtualID, true, true);
				}
			} else if (expandOnly || !collapseOnly) {
				busy = true;
				// check if too many children are going to be displayed
				if (_showWarning && (concept.childCount >= warningNodeCount)) {
					// mark that we've already displayed the warning so that it isn't displayed again
					_showedChildCountWarningAlready = true;
					
					var closeHandler:Function = function(yes:Boolean):void {
						if (yes) {
							addNeighbors(concept, node, childrenShowing, parentsShowing);
						} else {
							busy = false;
						}
					};
					var lbl:String = "Warning - this term has " + concept.childCount + " children. Do you want to continue?";
					showWarningDialog(lbl, closeHandler);
				} else {
					_showedChildCountWarningAlready = false;
					addNeighbors(concept, node, childrenShowing, parentsShowing);	
				}
				
				FlexVizLogger.logExpandCollapse(concept, ontologyVirtualID, true, true);
			}
		}
		
		private function addNeighbors(concept:NCBOConcept, node:IGraphNode, childrenShowing:Boolean, parentsShowing:Boolean):void {
			var what:String;
			if (!childrenShowing && !parentsShowing) {
				what = "neighborhood";
			} else if (!childrenShowing) {
				what = "children";
			} else {
				what = "parents";
			}
			graph.startProgress("Showing " + what + " of " + node.text);
			
			var added:int = 0;
			var neighborConcepts:Array = new Array();
			
			// show the parents (only gets called if the parents aren't already showing) 
			var parentCallback:Function = function(event:NCBOOperationEvent):void {
				//ArrayUtils.combine(neighborConcepts, event.neighborConcepts, neighborConcepts);
				neighborConcepts = neighborConcepts.concat(event.neighborConcepts);
				//added += addParentsToGraph(event.neighborConcepts, node.layoutX, node.layoutY);
				//runLayout(added, true, node, node);
				var parentsAddedCallback:Function = function():void {
					graph.repaintNode(node);
					graph.hideProgress();
					busy = false;
				};
				if (neighborConcepts.length > 0) {
					buildGraph([ concept ], neighborConcepts, false, parentsAddedCallback);
				} else {
					parentsAddedCallback();
				}
			};
			var parentOp:LoadParentsOperation = new LoadParentsOperation(service, ontologyID, concept, parentCallback);

			if (!childrenShowing) {
				// save this node - it is accessed in the FlexoVizComponent
				// it also gets cleared after the layout is run in FlexoVizComponent
				_nodeBeingExpanded = node;
				// show missing children
				var childCallback:Function = function(event:NCBOOperationEvent):void {
					//added += addChildrenToGraph(event.neighborConcepts, node.layoutX, node.layoutY);
					//ArrayUtils.combine(neighborConcepts, event.neighborConcepts, neighborConcepts);
					var children:Array = event.neighborConcepts;
					// check if we need to group some of the children (too many displayed)
					groupChildConcepts(children);
					neighborConcepts = neighborConcepts.concat(children);
					// check if the parents need to be loaded too
					if (!parentsShowing) {
						runOperation(parentOp);	// also runs the layout
					} else {
						var childrenAddedCallback:Function = function():void {
							graph.repaintNode(node);
							graph.hideProgress();
							busy = false;
						};
						//runLayout(added, true, node, node);
						if (neighborConcepts.length > 0) {
							buildGraph([ concept ], neighborConcepts, false, childrenAddedCallback);
						} else {
							childrenAddedCallback();
						}
					}
				};
				var childOp:LoadChildrenOperation = new LoadChildrenOperation(service, ontologyID, concept, childCallback);
				runOperation(childOp);
				
				// notify listeners that the concept was expanded
				dispatchEvent(new ConceptsExpandCollapseEvent(ConceptsExpandCollapseEvent.CONCEPTS_EXPANDED, [ concept ]));
				
			} else if (!parentsShowing) {
				// show missing parents only
				runOperation(parentOp);
			}
		}
		
		/**
		 * Returns a map of the concept ids that should be grouped.
		 * This will happen if too many nodes are going to be displayed.
		 */
		private function groupChildConcepts(children:Array):void {
			var notShowing:Array = [];
			for each (var concept:NCBOConcept in children) {
				var grouped:Boolean = graph.groupingManager.isGrouped(concept.id);
				var inModel:Boolean = !grouped && graph.model.containsNodeByID(concept.id);
				if (!grouped && !inModel) {
					notShowing.push(concept);
				}
			}
			if (notShowing.length > GROUP_CHILDREN_COUNT) {
				// sort alphabetically
				notShowing.sortOn("name");
				conceptIDsToGroup = {};
				for (var i:int = GROUP_CHILDREN_COUNT; i < notShowing.length; i++) {
					concept = NCBOConcept(notShowing[i]);
					conceptIDsToGroup[concept.id] = true;
				}
			}
		}
		
		/**
		 * Checks the conceptIDsToGroup map to see if any concepts were flagged to be grouped.
		 * If so it collects the graph nodes (which should now be in the model) and performs 
		 * the grouping (no animation). It also clears the conceptIDsToGroup map at the end.
		 */
		private function performGrouping():void {
			if (conceptIDsToGroup != null) {
				var nodes:Array = [];
				for (var id:String in conceptIDsToGroup) {
					var node:IGraphNode = graph.model.getNode(id);
					if (node) {
						nodes.push(node);
					}
				}
				if (nodes.length >= 2) {
					var groupedNodeName:String = "Grouped Terms (" + nodes.length + ")";
					//trace("Grouping child terms: " + nodes.join(", "));
					var groupedNode:GroupedNode = graph.groupingManager.groupNodes(nodes, groupedNodeName, 
								OntologyConstants.GROUPED_CONCEPTS, false);
					// need to run the layout when ungrouping
					groupedNode.runLayoutOnUnGroup = true;
				}
				conceptIDsToGroup = null;
			}
		}
		
		/**
		 * Determines if all the children of a concept are visible in the graph.
		 */
		public function childrenVisibleByID(conceptID:String):Boolean {
			var visible:Boolean = false;
			var concept:NCBOConcept = getConcept(conceptID);
			if (concept != null) {
				visible = childrenVisible(concept);
			}
			return visible;
		}
		
		/**
		 * Determines if at least one of the children of a concept are visible in the graph.
		 */
		public function someChildrenVisibleByID(conceptID:String):Boolean {
			var visible:Boolean = false;
			var concept:NCBOConcept = getConcept(conceptID);
			if (concept != null) {
				visible = (childrenVisibleCount(concept) > 0);
			}
			return visible;
		}
		
		/**
		 * Determines if all the children for a concept are visible in the graph.
		 * Checks that each child is in the graph model.
		 */
		private function childrenVisible(concept:NCBOConcept):Boolean {
			var visible:Boolean = false;
			if (concept.hasLoadedNeighbors) {
				visible = true;
				if (concept.hasChildren) {
					var children:Array = concept.children;
					for (var i:int = 0; i < children.length; i++) {
						var child:NCBOConcept = NCBOConcept(children[i]);
						if (!graph.model.containsNodeByID(child.id)) {
							visible = false;
							break;
						}
					}
				}
			}
			return visible;
		}
		
		/**
		 * Counts up how many children are visible on the screen
		 */
		private function childrenVisibleCount(concept:NCBOConcept):uint {
			var count:uint = 0;
			if (concept.hasLoadedNeighbors) {
				if (concept.hasChildren) {
					var children:Array = concept.children;
					for (var i:int = 0; i < children.length; i++) {
						var child:NCBOConcept = NCBOConcept(children[i]);
						if (graph.model.containsNodeByID(child.id)) {
							count++;
						}
					}
				}
			}
			return count;
		}
		
		/**
		 * Determines if all the parents of a concept are visible in the graph.
		 */
		public function parentsVisibleByID(conceptID:String):Boolean {
			var visible:Boolean = false;
			var concept:NCBOConcept = getConcept(conceptID);
			if (concept != null) {
				visible = parentsVisible(concept);
			}
			return visible;
		}
		
		/**
		 * Determines if all the parents for an concept are visible in the graph.
		 * Checks that each parent is in the graph model.
		 */
		private function parentsVisible(concept:NCBOConcept):Boolean {
			var visible:Boolean = false;
			if (concept.hasLoadedNeighbors) {
				visible = true;
				if (concept.hasParents) {
					var parents:Array = concept.parents;
					for (var i:int = 0; i < parents.length; i++) {
						var parent:NCBOConcept = NCBOConcept(parents[i]);
						if (!graph.model.containsNodeByID(parent.id)) {
							visible = false;
							break;
						}
					}
				}
			}
			return visible;
		}
		
		/**
		 * Counts up how many parents are visible on the screen
		 */
		private function parentsVisibleCount(concept:NCBOConcept):uint {
			var count:uint = 0;
			if (concept.hasLoadedNeighbors) {
				if (concept.hasParents) {
					var parents:Array = concept.parents;
					for (var i:int = 0; i < parents.length; i++) {
						var parent:NCBOConcept = NCBOConcept(parents[i]);
						if (graph.model.containsNodeByID(parent.id)) {
							count++
						}
					}
				}
			}
			return count;
		}
		
		/**
		 * Determines if a concept with the childID is actually a child of the concept with the parentID.
		 * Returns false if either concept isn't in the cache. 
		 */
		public function isChildByID(childID:String, parentID:String):Boolean {
			var child:NCBOConcept = getConcept(childID);
			var parent:NCBOConcept = getConcept(parentID);
			var isChild:Boolean = (child && parent && (parent.children.indexOf(child) != -1));
			return isChild; 
		}
		
		/**
		 * Adds the missing children and their relationships/arcs to the graph model (does NOT run a layout).
		 * @param children the children NCBOConcept objects to add
		 * @param initialX the initial x value for the node (optional)
		 * @param initialY the initial y value for the node (optional)
		 * @return the number of children actually added to the graph that weren't already showing
		 */
//		private function addChildrenToGraph(children:Array, initialX:Number = 0, initialY:Number = 0):int {
//			var added:int = 0;
//			var rels:Object = new Object();
//			var rel:NCBORelationship;
//			var childCount:int = children.length;
//			if (childCount > 0) {
//				graph.updateProgress(null, 0, childCount);
//				for (var i:int = 0; i < childCount; i++) {
//					var child:NCBOConcept = NCBOConcept(children[i]);
//					graph.updateProgress(null, i + 1, childCount);
//					if (addNode(graph.model, child, initialX, initialY)) {
//						added++;
//						for (var j:int = 0; j < child.relationships.length; j++) {
//							rel = NCBORelationship(child.relationships[j]);
//							if (!rels.hasOwnProperty(rel.id)) {
//								rels[rel.id] = rel;
//							}
//						}
//					}
//				}
//			}
//			if (added > 0) {
//				// add the arcs
//				var relsCount:int = ArrayUtils.mapSize(rels);
//				var progress:int = 1;
//				graph.updateProgress("adding relationships", 0, relsCount);
//				for each(rel in rels) {
//					addArc(graph.model, rel);
//					graph.updateProgress(null, progress++, relsCount);
//				}
//			}
//			return added;
//		}
		
		/**
		 * Adds the missing parents and their relationships/arcs to the graph model (does NOT run a layout).
		 * @param parents the parent NCBOConcept objects to add
		 * @param initialX the initial x value for the node (optional)
		 * @param initialY the initial y value for the node (optional)
		 * @return the number of parents actually added to the graph that weren't already showing
		 */
//		private function addParentsToGraph(parents:Array, initialX:Number = 0, initialY:Number = 0):int {
//			var added:int = 0;
//			var rels:Object = new Object();
//			var rel:NCBORelationship;
//			var parentCount:int = parents.length;
//			if (parentCount > 0) {
//				graph.updateProgress(null, 0, parentCount);
//				for (var i:int = 0; i < parentCount; i++) {
//					var parent:NCBOConcept = NCBOConcept(parents[i]);
//					graph.updateProgress(null, i + 1, parentCount);
//					if (addNode(graph.model, parent, initialX, initialY)) {
//						added++;
//						for (var j:int = 0; j < parent.relationships.length; j++) {
//							rel = NCBORelationship(parent.relationships[j]);
//							if (!rels.hasOwnProperty(rel.id)) {
//								rels[rel.id] = rel;
//							}
//						}
//					}
//				}
//			}
//			if (added > 0) {
//				// add the arcs
//				var relsCount:int = ArrayUtils.mapSize(rels);
//				var progress:int = 1;
//				graph.updateProgress("adding relationships", 0, relsCount);
//				for each(rel in rels) {
//					addArc(graph.model, rel);
//					graph.updateProgress(null, progress++, relsCount);
//				}
//			}
//			return added;
//		}
		
		private function showWarningDialog(lbl:String, callback:Function):void {
			// hide the busy cursor until after the warning is closed dialog
			var wasBusy:Boolean = busy;
			if (wasBusy) {
				busy = false;
			}
			
			var closeHandler:Function = function(yes:Boolean, checkboxSelected:Boolean):void {
				_showWarning = !checkboxSelected;	// update whether warnings are allowed
				busy = wasBusy;	// restore the busy cursor
				if (callback != null) {
					callback(yes);
				}
			};
			
			UIUtils.createCheckBoxConfirmPopup(lbl, "Warning", "Don't show this warning", false, 
				ContentWindow.YES | ContentWindow.NO, ContentWindow.YES, null, closeHandler);
						
		}
		
		private function buildGraph(matchingConcepts:Array, neighborConcepts:Array,
									clearGraph:Boolean = true, callback:Function = null):void {
			// when we get here, we expect everything to be loaded
			// also check how many nodes will be displayed and show a warning if necessary 
			var model:IGraphModel = graph.model;

			const matchingCount:int = matchingConcepts.length;
			const neighborCount:int = neighborConcepts.length;
			var newConceptCount:int = matchingCount + neighborCount;
			
			// count the total number of concepts that will be added to the graph
			if (!clearGraph) {
				var map:Object = new Object();
				var concept:NCBOConcept;
				var i:int;
				for (i = 0; i < matchingCount; i++) {
					concept = matchingConcepts[i];
					if (graph.model.containsNodeByID(concept.id) && !map.hasOwnProperty(concept.id)) {
						map[concept.id] = true;
						newConceptCount--;
					}
				}
				for (i = 0; i < neighborCount; i++) {
					concept = neighborConcepts[i];
					if (graph.model.containsNodeByID(concept.id) && !map.hasOwnProperty(concept.id)) {
						map[concept.id] = true;
						newConceptCount--;
					}
				}
				map = null;
			}
			debug("Adding " + newConceptCount + " nodes to the graph");
			
			// check if we should display the warning dialog
			if (_showWarning && !_showedChildCountWarningAlready && (newConceptCount >= _warningNodeCount)) {
				var closeHandler:Function = function(yes:Boolean):void {
					if (yes) {
						buildGraphNoWarning(matchingConcepts, neighborConcepts, clearGraph);
					}
					if (callback != null) {
						callback();
					}
				};
				var lbl:String = "About to add " + newConceptCount + " nodes on the screen.\n" + 
							"This may take a long time - do you want to continue?";
				showWarningDialog(lbl, closeHandler);
			} else {
				buildGraphNoWarning(matchingConcepts, neighborConcepts, clearGraph);
				if (callback != null) {
					callback();
				}
			}
		}
		
		private function buildGraphNoWarning(matchingConcepts:Array, 
				neighborConcepts:Array, clearGraph:Boolean = true):void {

			_showedChildCountWarningAlready = false;	// clear this flag for next time
	
			var startTime:int = getTimer();
	
			var model:IGraphModel = graph.model;
			const matchingCount:int = matchingConcepts.length;
			const neighborCount:int = neighborConcepts.length;
			var maxProgress:int = matchingCount + neighborCount;
			var progress:int = 1;
			var node:IGraphNode;
			var concept:NCBOConcept;
			var i:int;
			
			graph.updateProgress("building graph", 0, maxProgress);
			// improve performance by prevent UI updates while we are adding and removing nodes
			graph.preventUIChanges = true;
			
			var removedNodes:int = 0;
			var addedNodes:int = 0;
			var addedArcs:int = 0;
			var allConcepts:Object = new Object();
			var matchNodes:Array = new Array();
			var filteredNodeTypes:Array = new Array();
			// load the matching nodes first
			for (i = 0; i < matchingCount; i++) {
				concept = NCBOConcept(matchingConcepts[i]);
				graph.updateProgress(concept.name, progress++, maxProgress);
				if (!allConcepts.hasOwnProperty(concept.id)) {
					allConcepts[concept.id] = concept;
					if (addNode(model, concept)) {
						addedNodes++;
						if (isNodeTypeFiltered(concept.type) && (filteredNodeTypes.indexOf(concept.type) == -1)) {
							filteredNodeTypes.push(concept.type);
						}
					}
					maxProgress += concept.relationships.length;
					
					// save this for later when we set the matching nodes
					node = model.getNode(concept.id);
					matchNodes.push(node);
				}
			}
			
			// now load all the neighbors
			for (i = 0; i < neighborCount; i++) {
				concept = NCBOConcept(neighborConcepts[i]);
				graph.updateProgress(concept.name, progress++, maxProgress);
				if (!allConcepts.hasOwnProperty(concept.id)) {
					allConcepts[concept.id] = concept;
					if (addNode(model, concept)) {
						addedNodes++;
						if (isNodeTypeFiltered(concept.type) && (filteredNodeTypes.indexOf(concept.type) == -1)) {
							filteredNodeTypes.push(concept.type);
						}
					}
					maxProgress += concept.relationships.length;
				}
			}
				
			// now add all the relationships
			var filteredRels:Array = new Array();
			for each (concept in allConcepts) {
				for (i = 0; i < concept.relationships.length; i++) {
					graph.updateProgress("adding relationships", progress++, maxProgress);
					var rel:NCBORelationship = NCBORelationship(concept.relationships[i]);
					if (addArc(model, rel)) {
						addedArcs++;
						if (isArcTypeFiltered(rel.type) && (filteredRels.indexOf(rel.type) == -1)) {
							filteredRels.push(rel.type);
						}
					}
				}
			}
			
			// set the footer label to indicate that some node/rel types are hidden
			var warningLabel:String = null;
			if ((filteredRels.length > 0) && (filteredNodeTypes.length > 0)) {
				warningLabel = "Warning - some node and arc types are hidden";
			} else if (filteredRels.length > 0) {
				warningLabel = "Warning - the following arc types are hidden: " + filteredRels.join(", ");
			} else if (filteredNodeTypes.length > 0) {
				warningLabel = "Warning - the following node types are hidden: " + filteredNodeTypes.join(", ");
			}
			if (warningLabel != null) {
				graph.setFooterLabel(warningLabel, 0xff3333, 5000);
			}
			
			if (clearGraph) {
				// now remove all the other existing nodes by id
				// this ensures that we only show the requested graph
				// and remove any of the previous nodes that are no longer wanted
				removedNodes += model.removeNodesByIDExcept(allConcepts);
			}
			
			// check if any nodes need to be grouped now that they have been added to the model
			performGrouping();
			// TODO - matching nodes shouldn't be grouped - do we need to check?
			// we are grouping the children which shouldn't be matching nodes I think
			
			graph.matchingNodes = matchNodes;
			var firstMatch:IGraphNode = (matchNodes.length > 0 ? IGraphNode(matchNodes[0]) : null);
			
			// allow UI changes again (adds and removes the node ui components), but don't layout!
			graph.allowUIChanges(false);
			
			var buildTime:int = getTimer() - startTime;
			debug("Graph build time: " + buildTime + " ms");
			
			// only layout if the graph changed
			var changed:int = (addedNodes + addedArcs + removedNodes);
			runLayout(changed, firstMatch, null, true);
		}
		
		/**
		 * Adds a new node to the graph model, if it doesn't already exist in the model.
		 * If no initial x,y values are given it will attempt to position the new node next to the first found
		 * connected node that is already in the graph.
		 * @param model the model to add the node too
		 * @param concept the concept to be added - will be set as the data property of the created IGraphNode/DefaultGraphNode object
		 * @param initialX the initial x position for the node (optional)
		 * @param initialY the initial y position for the node (optional)
		 */ 
		private function addNode(model:IGraphModel, concept:NCBOConcept, initialX:Number = 0, initialY:Number = 0):Boolean {
			var added:Boolean = false;
			// first check if the node is actually grouped - if so we'll skip creating the node and will ungroup instead
			var grouped:Boolean = graph.groupingManager.isGrouped(concept.id); 
			if (grouped) {
				// ungroup?
				//trace("Trying to create a new node that is grouped, ungrouping instead...");
				var groupedNode:GroupedNode = graph.groupingManager.getGroupedNodeForNode(concept.id);
				graph.ungroupNode(groupedNode, false);
			} else {
				var inModel:Boolean = model.containsNodeByID(concept.id);
				if (!inModel) {
					var node:IGraphNode = factory.createNode(concept);
					// must set this location BEFORE adding to the model
					if ((initialX != 0) || (initialY != 0)) {
						node.setLocation(initialX, initialY);
					} else {
						var pos:Point = tryToPositionNode(concept);
						node.setLocation(pos.x, pos.y);
					}
					// add the node to the model, this fires an event which updates the UI
					model.addNode(node);
					added = true;
					if (concept.hasProperty(PROP_ROOT)) {
						node.setProperty(PROP_ROOT, concept.getProperty(PROP_ROOT));
					}
				}
			}
			return added;
		}
		
		/**
		 * Adds a new arc to the graph model if it doesn't already exist.
		 * @param model the model to add the arc to
		 * @param rel the relationship to be added - will be set as the data property on the 
		 * 	created IGraphArc/DefaultGraphArc object
		 */
		private function addArc(model:IGraphModel, rel:NCBORelationship):Boolean {
			var added:Boolean = false;
			var arc:IGraphArc;
			if (!model.containsArcByID(rel.id)) {
				var src:IGraphNode = model.getNode(rel.source.id);
				var dest:IGraphNode = model.getNode(rel.destination.id);
				if (src && dest) {
					arc = factory.createArc(rel, src, dest, isArcInverted(rel));
					model.addArc(arc);
					added = true;
				}
			} else {
				// make sure the relType is in sync
				arc = model.getArc(rel.id);
				if (arc && (arc.type != rel.type)) {
					trace("Arc type changed: " + arc.type + " -> " + rel.type);
					model.updateArcType(arc, rel.type);
				} 
			}
			return added;
		}
		
		/**
		 * Attempts to position the node at the same position as the first found
		 * node that already exists in the model who is connected to the given concept.
		 */
		protected function tryToPositionNode(concept:NCBOConcept, centerOnCanvas:Boolean = true):Point {
			var position:Point = new Point();
			var positioned:Boolean = false;
			var connected:Array = concept.connectedConcepts;
			if (connected.length > 0) {
				for (var i:int = 0; i < connected.length; i++) {
					var c:NCBOConcept = NCBOConcept(connected[i]);
					var neighborNode:IGraphNode = graph.model.getNode(c.id);
					if (neighborNode != null) {
						position.x = neighborNode.layoutX;
						position.y = neighborNode.layoutY;
						positioned = true;
						break;
					}
				}
			}
			
			// if we couldn't position the node, then center it
			if (!positioned && centerOnCanvas) {
				var center:Point = graph.canvasCenter;
				position.x = center.x;
				position.y = center.y; 
			}
			return position;
		}
		
		/**
		 * Checks if the arc should be inverted - certain relationship types (is_a, part_of, _develops_from)
		 * are inverted - the arrow head goes from the child to the parent.
		 * The NCBORelationship also has an inverted property.
		 */ 
		public function isArcInverted(rel:NCBORelationship):Boolean {
			// April 21st, 2010 - Instead of hardcoding which relationships are inverted, instead now only the 
			// OWL rel types are hardcoded, and the OBO ones are determined from the [R] flag.
			var inverted:Boolean = rel.inverted || OntologyConstants.isArcTypeInverted(rel.type);
//			if (!inverted) {
//				// check for types that are similar to is_a, part_of, was_a
//				var relType:String = rel.type.toLowerCase().replace("_", " ");
//				if (StringUtils.contains(relType, "is a") || StringUtils.contains(relType, "part of") || 
//					StringUtils.contains(relType, "was a")) {
//					inverted = true;
//				}
//			}
			return inverted;
		}
		
		/** Determines if the arc type is filtered (not visible). */
		public function isArcTypeFiltered(type:String):Boolean {
			var visible:Boolean = graph.filterManager.arcTypeFilter.isTypeVisible(type);
			return !visible;
		}

		/** Determines if the node type is filtered (not visible). */
		public function isNodeTypeFiltered(type:String):Boolean {
			var visible:Boolean = graph.filterManager.nodeTypeFilter.isTypeVisible(type);
			return !visible;
		}
		
	}
}