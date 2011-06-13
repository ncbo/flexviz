// ActionScript file for Search.mxml

import events.ConceptLinkEvent;

import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.external.ExternalInterface;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.net.URLRequest;
import flash.net.navigateToURL;
import flash.ui.Keyboard;

import flex.utils.StringUtils;
import flex.utils.Utils;
import flex.utils.ui.MoveResize;
import flex.utils.ui.TextHighlighter;
import flex.utils.ui.UIUtils;
import flex.utils.ui.chooser.ClearTextInput;
import flex.utils.ui.events.ItemsChangedEvent;

import mx.collections.ArrayCollection;
import mx.collections.Sort;
import mx.collections.SortField;
import mx.controls.LinkButton;
import mx.controls.TextInput;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.controls.listClasses.IListItemRenderer;
import mx.core.Application;
import mx.core.UIComponent;
import mx.events.CloseEvent;
import mx.events.CollectionEvent;
import mx.events.DataGridEvent;
import mx.events.EffectEvent;
import mx.events.FlexEvent;
import mx.events.ResizeEvent;
import mx.events.ValidationResultEvent;
import mx.managers.CursorManager;
import mx.managers.PopUpManager;
import mx.rpc.Fault;
import mx.utils.StringUtil;

import org.ncbo.uvic.flex.NCBORestService;
import org.ncbo.uvic.flex.doi.DegreeOfInterestService;
import org.ncbo.uvic.flex.events.NCBOConceptEvent;
import org.ncbo.uvic.flex.events.NCBOLogEvent;
import org.ncbo.uvic.flex.events.NCBOOntologiesEvent;
import org.ncbo.uvic.flex.events.NCBOSearchEvent;
import org.ncbo.uvic.flex.logging.LogService;
import org.ncbo.uvic.flex.model.NCBOConcept;
import org.ncbo.uvic.flex.model.NCBOOntology;
import org.ncbo.uvic.flex.model.NCBOSearchResultConcept;
import org.ncbo.uvic.flex.model.NCBOSearchResultOntology;
import org.ncbo.uvic.flex.search.SearchParams;
import org.ncbo.uvic.flex.ui.ConceptPropertyWindow;
import org.ncbo.uvic.flex.ui.DebugPanel;
import org.ncbo.uvic.flex.util.NavigateToBioPortal;

import renderers.ConceptLinkItemHighlightRenderer;

import ui.ColumnsPopUp;
import ui.DOIPopUp;
import ui.OntologyResultsFilterPopUpBox;
import ui.ScrollingButtonBox;

import util.Shared;

// turn this flag on to use test data - it causes fake search results to appear on startup
// this is useful when testing something in the results panel
private static const TESTING:Boolean = false;

private static const EMAIL:String = "search@uvic.ca";
private static const MAX_SAVED_SEARCHES:int = 10;
private static const ALL_ONTOLOGIES:NCBOOntology = new NCBOOntology("", "", "All Ontologies");
private static const NO_CONCEPT_RESULTS:NCBOSearchResultConcept = new NCBOSearchResultConcept("", "No results", "", "", null, "");

// The search results are saved for 30 minutes, so if you navigate away from the search
// page and come back, the results will be loaded again.
private static const SAVE_SEARCH_RESULTS_TIME:int = 1800000; // 30 minutes

private static const DOI_RESULTS:String = "searchResults";
private static const DOI_ONTOLOGIES:String = "searchOntologies";

private static const MAIN_BOX_WIDTH:int = 900;

[Embed("/assets/black_arrow_down.png")] 
public const downIcon:Class;
[Embed("/assets/black_arrow_up.png")] 
public const upIcon:Class;
[Embed("/assets/black_arrow_right.png")] 
public const rightIcon:Class;
[Embed("/assets/black_arrow_left.png")] 
public const leftIcon:Class;
[Embed("/assets/view_details.png")] 
public const detailsIcon:Class;
[Embed("/assets/viz.png")] 
public const vizIcon:Class;
[Embed("/assets/diamond.gif")] 
public const doiIcon:Class;

[Bindable]
private var service:NCBORestService;

private var lastSearchText:String = "";

[Bindable]
// contains the ontology search results as NCBOSearchResultOntology objects
private var ontologyResults:ArrayCollection = new ArrayCollection();

[Bindable]
// contains the selected concept search results as NCBOSearchResultConcept objects
private var conceptResults:ArrayCollection = new ArrayCollection();

private const ontologiesTextHighlighter:TextHighlighter = new TextHighlighter();
private const conceptsTextHighlighter:TextHighlighter = new TextHighlighter();

[Bindable]
// contains the previous search strings for autocompletion
private var autoCompleteSearchTexts:ArrayCollection = new ArrayCollection();

[Bindable]
// contains the previous searches as SearchParams objects
private var previousSearches:ArrayCollection = new ArrayCollection([ "" ]);
// holds the last previous search params - used for logging when a previous search is run
private var lastPreviousSearch:SearchParams = null;

private var params:FlexParams;

// this is used to store the search params that we need to save
// but can't do so until the ontologies have loaded (to get the ontology name)
// only happens when a search is performed before the ontologies have loaded
private var saveSearchParamsAfterOntologiesLoaded:SearchParams;
private var initialSearchParams:SearchParams;

private var lastHelpPanelBounds:Rectangle = new Rectangle(100, 150, 650, 565);
private var propertyWindows:Array = [];

private function loadParameters():void {
	params = new FlexParams();
	dateVersionLabel.visible = params.debug;
	if (params.banner) {
		currentState = "Banner";
	}
	searchText = params.search;
	NavigateToBioPortal.baseURL = params.redirectURL;
	LogService.initialize(params.log, "search", Utils.browserDomain);
	service = new NCBORestService(NCBORestService.APP_ID_SEARCH, params.server, errorFunction, EMAIL);
	
	LogService.dispatcher.addEventListener(NCBOLogEvent.ITEM_LOGGED, searchItemLogged);
	
	DegreeOfInterestService.restService = service;
}

private function created():void {
	loadParameters();
	
	// add support for CTRL-T and CTRL-N shortcuts to open a new browser tab
	Utils.addOpenNewTabListener();
	
	if (Application.application.width < 950) {
		// use full width, and remove the expand button
		toggleFullWidth();
		useFullWidthButton.visible = false;
		topBox.setStyle("paddingRight", 0);
	}

	initializeOntologyFilterBox();
	initializeConceptResults();
	OntologyResultsFilterPopUpBox(showOntologyResultsButton.popUp).init(ontologyResults, conceptResults, showOntologyResultsButton);
	
	// load the columns into the popup, and sets which are visible from the shared object
	ColumnsPopUp(columnsPopupButton.popUp).loadColumns(conceptResultsList.columns);
	
	if (TESTING) {
		conceptResultsPanel.visible = true;
		loadTestData();
	} else {
		// check if we should run a search right away
		// this happens if a search parameter is specified in the html
		if (params.search.length > 0) {
			// run the search
			initialSearchParams = new SearchParams(params.search);
			if (params.ontology.length > 0) {
				// the ontologyName isn't known yet!
				initialSearchParams.ontologyIDs = params.ontology;
			}
			performSearch(initialSearchParams);
		}
		
		if (params.showPopularSearches) {
			LogService.getMostPopularSearches(mostPopularSearchesHandler);
		}
		if (params.showRecentSearches) {
			LogService.getRecentSearches(recentSearchesHandler);
		}
	}
	
	Application.application.addEventListener(ResizeEvent.RESIZE, handleResize);
	Application.application.addEventListener(FlexEvent.APPLICATION_COMPLETE, appComplete);
	handleResize();
	
	loadPreviousSearches();
	initHelp();

}

private function appComplete(event:FlexEvent):void {
	Application.application.removeEventListener(FlexEvent.APPLICATION_COMPLETE, appComplete);
	Application.application.stage.addEventListener(KeyboardEvent.KEY_DOWN, globalKeyHandler);
	// use JavaScript to focus our Flex application
	searchTextInput.setFocus();
	ExternalInterface.call("focusApp");
}

private function globalKeyHandler(event:KeyboardEvent):void {
	var char:String = String.fromCharCode(event.charCode).toUpperCase();
	if (event.keyCode == Keyboard.ESCAPE) {
		if (previousSearchesDropDownBox.visible) {
			togglePreviousSearches();
		}
		//if (ontologyResultsBox.visible) {
			//toggleOntologyResultsBox();
		//}
	} else if (event.ctrlKey && event.shiftKey && (char == "D")) {
		event.stopImmediatePropagation();
		showDebugPanel();
	}
}

private function showDebugPanel():void {
	var debugPanel:DebugPanel = new DebugPanel();
	debugPanel.service = service;
	debugPanel.version = (Application.application.parameters.hasOwnProperty("v") ? 
							Application.application.parameters["v"] : "?");
	PopUpManager.addPopUp(debugPanel, DisplayObject(this), true); 
	PopUpManager.centerPopUp(debugPanel);
	debugPanel.addEventListener(CloseEvent.CLOSE, function(event:CloseEvent):void {
		PopUpManager.removePopUp(debugPanel);
	});
}

private function reportBugs():void {
	navigateToURL(new URLRequest("mailto:support@bioontology.org"), "_blank");
}

private function errorFunction(error:Error):void {
	debug(error.message);
	var errorMsg:String = "";
	if (error is Fault) {
		var fault:Fault = (error as Fault);
		if (fault.faultString == "HTTP request error") {
			errorMsg = "Error connecting to the server.";
		}
	}
	if (errorMsg.length == 0) {
		errorMsg = error.message;		
	}
	setError(errorMsg);
	
	cursorManager.removeBusyCursor();
	if (progress && progress.visible) {
		progress.visible = false;
	}
	if (!searchButton.enabled && searchTextInput.enabled) {
		searchButton.enabled = true;
	}
}

private function setError(txt:String, style:String = "error"):void {
	if (errorLabel.styleName != style) {
		errorLabel.styleName = style; 
	}
	errorLabel.text = txt;
}

private function debug(msg:String):void {
	if (params.debug) {
		trace(msg);
	}
}

private function handleResize(event:ResizeEvent = null):void {
	var appHeight:Number = Application.application.height;
	var resultY:Number = topBanner.height + searchPanel.height; //conceptResultsPanel.y;
	var panelHeight:Number = Math.max(100, appHeight - resultY - 10);
	conceptResultsPanel.height = panelHeight;
	
	if (mainBox.width != MAIN_BOX_WIDTH) {
		mainBox.width = Application.application.width - 16;
	}
}


/////////////////////////
// SEARCH PANEL
/////////////////////////


private function searchInputCreated(event:FlexEvent):void {
	var clearTextInput:ClearTextInput = searchTextInput.combo.promptTextInput;
	var textInput:TextInput = clearTextInput.textInput;
	textInput.setStyle("borderStyle", "none");
}

private function searchTextKeyDown(event:KeyboardEvent):void {
	if (event.keyCode == Keyboard.ENTER) {
		searchButtonClicked();
	}
}

private function searchButtonClicked():void {
	// make sure that the search is enabled!
	if (searchButton.enabled) {
		// validate the text now
		searchTextValidator.source = searchTextInput;
		var result:ValidationResultEvent = searchTextValidator.validate();
		if (result.type == ValidationResultEvent.VALID) {
			performSearch(searchParams);
		} else {
			searchTextInput.setFocus();
		}
	}
}

private function performSearch(params:SearchParams, hits:Boolean = true):void {
	// hide previous search
	if (previousSearchesDropDownBox.visible) {
		togglePreviousSearches();
	}
	setError("");
	
	if (params.isValid) {
		lastSearchText = params.searchText;
		// update the date
		params.date = new Date();		
		
		// add to autocomplete
		if (!autoCompleteSearchTexts.contains(params.searchText)) {
			autoCompleteSearchTexts.addItem(params.searchText);
		}
		
		// clear current search results
		ontologyResults.removeAll();
		ontologyResults.refresh();
		conceptResults.removeAll();
		// remove the results sorting - use the default sort order from the server
		if (conceptResults.sort) {
			conceptResults.sort = null;
		}
		conceptResults.refresh();
		// clear the results filters
		conceptResultsFilter.text = "";
		exactMatchesCheckBox.selected = false;
		resultsDOIPopUpButton.enabled = false;
		
		// temporary disable the search button
		searchButton.enabled = false;

		progress.visible = true;
		CursorManager.setBusyCursor();
		service.search(params, searchResultsHandler, hits);
		
		// check if this search matches the last loaded previous search, if so log it
		if ((lastPreviousSearch != null) && (params.searchText == lastPreviousSearch.searchText)) {
			LogService.logPreviousSearch(lastPreviousSearch);
			// don't clear the lastPreviousSearch variable, the search can be run again
		} else if (lastPreviousSearch) {
			// only clear if the search doesn't match the previous search
			lastPreviousSearch = null;
		}
	} else {
		// show the error border around the input
		searchTextValidator.source = searchTextInput;
		searchTextValidator.validate();
	}
}

private function get searchParams():SearchParams {
	var params:SearchParams = new SearchParams(searchText);
	params.exactMatch = (exactMatchRadioButton && exactMatchRadioButton.selected);
	params.includeAttributes = includeAttributes;
	
	// get the checked ontologies
	var selOntologies:Array = selectedOntologies;
	// special case if all ontologies are showing AND selected (no category or text filters)
	if (ontologyFilterBox && ontologyFilterBox.allOntologiesSelected) {
		selOntologies = [];
	}
	for (var i:int = 0;i < selOntologies.length; i++) {
		var ontology:NCBOOntology = (selOntologies[i] as NCBOOntology);
		params.addOntology(ontology);
	}
	return params;
}

public function getHighlightText():String {
	return lastSearchText;
}

private function get searchText():String {
	return (searchTextInput ? StringUtil.trim(searchTextInput.text) : "");
}

private function set searchText(txt:String):void {
	if (searchTextInput) {
		searchTextInput.text = txt;
	}
}

private function get exactMatch():Boolean {
	return  (exactMatchRadioButton && exactMatchRadioButton.selected);
}

private function set exactMatch(exact:Boolean):void {
	if (exactMatchRadioButton && containsRadioButton) {
		if (exact) {
			exactMatchRadioButton.selected = true;
		} else {
			containsRadioButton.selected = true;
		}
	}
}

private function get includeAttributes():Boolean {
	return (includeAttributesCheckBox ? includeAttributesCheckBox.selected : false);
}

private function set includeAttributes(props:Boolean):void {
	if (includeAttributesCheckBox) {
		includeAttributesCheckBox.selected = props;
	}
}

private function resetForm():void {
	searchText = "";
	setError("");
	exactMatch = false;
	includeAttributes = false;
	ontologyFilterBox.clearFilters();
	ontologyFilterBox.selectNoOntologies();
	searchTextInput.setFocus();
	previousSearchesList.selectedIndex = -1;
	lastPreviousSearch = null;

	// clear search results too
	ontologyResults.removeAll();
	conceptResults.removeAll();
	conceptResultsPanel.visible = false;
	
	// clear the last search result from the cache too
	Shared.clearLastSearchResults();
}

private function toggleFullWidth():void {
	if (mainBox.width == MAIN_BOX_WIDTH) {
		mainBox.width = Application.application.width - 16;
		useFullWidthButton.toolTip = "Go back to the default width";
		useFullWidthButton.setStyle("icon", leftIcon);
	} else {
		mainBox.width = MAIN_BOX_WIDTH;
		useFullWidthButton.toolTip = "Expand to use the full screen width";
		useFullWidthButton.setStyle("icon", rightIcon);
	}
}

////////////////////////////
// PREVIOUS SEARCHES
////////////////////////////

private function previousSearchChanged(event:Event):void {
	loadPreviousSearch();
} 

private function loadPreviousSearchKeyPressed(event:KeyboardEvent):void {
	if (event.keyCode == Keyboard.ENTER) {
		loadPreviousSearch();
	}
}

private function togglePreviousSearches(event:MouseEvent = null):void {
	if (previousSearchesDropDownBox.visible) {
		previousSearchesDropDownBox.height = 0;
		previousSearchesButton.setStyle("icon", downIcon);
		previousSearchesButton.selected = false;
		Application.application.stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownOutsidePreviousSearchesDropDown);
	} else {
		previousSearchesDropDownBox.visible = true;
		previousSearchesDropDownBox.height = 170;
		previousSearchesButton.setStyle("icon", upIcon);
		previousSearchesButton.selected = true;
		Application.application.stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownOutsidePreviousSearchesDropDown);
	}
}

// hide the previous searches drop down if the mouse is clicked outside of the box
private function mouseDownOutsidePreviousSearchesDropDown(event:MouseEvent):void {
	if (previousSearchesDropDownBox.visible) {
        if (!previousSearchesDropDownBox.hitTestPoint(event.stageX, event.stageY, true) && 
        	!previousSearchesButton.hitTestPoint(event.stageX, event.stageY, true)) {
            togglePreviousSearches(event);
        }
    }
}

private function resizePreviousSearchesFinished():void {
	if (previousSearchesDropDownBox.height == 0) {
		previousSearchesDropDownBox.visible = false;
	}
}

private function saveSearch(event:NCBOSearchEvent):void {
	saveSearchParameters(event.searchParams);
	
	// save the results too
	Shared.saveLastSearchResults(event);
}

private function saveSearchParameters(params:SearchParams):void {
	if (previousSearches.length > MAX_SAVED_SEARCHES) {
		previousSearches.removeItemAt(previousSearches.length - 1);
	}
	
	// if a search was run before the ontologies were loaded, then the ontology name isn't defined
	if ((params.ontologyIDs.length > 0) && (params.ontologyNames.length == 0)) {
		if (ontologyFilterBox.ontologiesLoaded /*ontologiesList.enabled /* ontologies are loaded */) {
			var ontologyArray:Array = getOntologiesFromIDs(params.ontologyIDsArray, false);
			params.removeAllOntologies();
			for each (var ontology:NCBOOntology in ontologyArray) {
				params.addOntology(ontology);
			}
		} else {
			// this is checked in the ontologiesLoadedHandler function, which re-calls saveSearch
			saveSearchParamsAfterOntologiesLoaded = params;
			return;
		}
	}
	
	// remove from the list, it will get added to the front of the list
	var index:int = previousSearches.getItemIndex(params);
	if (index != -1) {
		previousSearches.removeItemAt(index);
	} else {
		// check for a duplicate
		var foundIndex:int = -1;
		for (var i:int = 0; i < previousSearches.length; i++) {
			var p:SearchParams = (previousSearches[i] as SearchParams);
			if (p.equals(params)) {
				foundIndex = i;
				break;
			}
		}
		// remove the old one, we'll be adding the new one first
		if (foundIndex != -1) {
			previousSearches.removeItemAt(foundIndex);
		}
	}

	// add first
	previousSearches.addItemAt(params, 0);
	previousSearches.refresh();
	previousSearchesList.selectedIndex = 0;
	if (!previousSearchesButton.enabled) {
		previousSearchesButton.enabled = true;
	}
	
	// save to disk
	Shared.savePreviousSearches(previousSearches.source.slice());
}

private function loadPreviousSearch(params:SearchParams = null, log:Boolean = true, loadSearchTextOnly:Boolean = false):void {
	// hide the previous search
	if (previousSearchesDropDownBox.height != 0) {
		togglePreviousSearches();
	}
	
	// need to remove any of the filters
	ontologyFilterBox.clearFilters();	
	
	if (params == null) {
		params = (previousSearchesList.selectedItem as SearchParams);
	}
	if (params != null) {
		searchText = params.searchText;
		// copy all the parameters over?
		if (!loadSearchTextOnly) {
			includeAttributes = params.includeAttributes;
			exactMatch = params.exactMatch;
			var ontologyIDs:Array = params.ontologyIDsArray;
			var selOntologies:Array = getOntologiesFromIDs(ontologyIDs);
			ontologyFilterBox.selectedOntologies = selOntologies; 
			
			// scroll to the first selected ontology
			ontologyFilterBox.scrollToSelectedOntology(); 
		}
		searchButton.setFocus();
		
		// need to de-select the current item
		previousSearchesList.selectedIndex = -1;
	}
	lastPreviousSearch = params;
}

private function getOntologiesFromIDs(ids:Array, displayError:Boolean = true):Array {
	var foundOntologies:Array = new Array();
	var notFound:Array = new Array();
	if (ids.length > 0) {
		for (var i:int = 0; i < ids.length; i++) {
			var id:String = (ids[i] as String);
			var found:Boolean = false;
			var ontologies:Array = ontologyFilterBox.allOntologies;
			for (var j:int = 0; j < ontologies.length; j++) {
				var ont:NCBOOntology = NCBOOntology(ontologies[j]);
				if (ont.ontologyID == id) {
					foundOntologies.push(ont);
					found = true;
					break;
				}
			}
			if (!found) {
				notFound.push(id);
			}
		}
	}
	if (displayError) {
		if (notFound.length > 0) {
			var str:String = "The following ontolog" + (notFound.length == 1 ? "y was" : "ies were") + 
							" not found: " + notFound.join(", ");
			if (foundOntologies.length == 0) {
				str += "\nThe search will default to all ontologies.";
			} 
			errorFunction(new Error(str));
		} else {
			setError("");
		}
	}
	return foundOntologies;
}

private function clearPreviousSearches():void {
	// clear the searches
	Shared.savePreviousSearches([]);
	previousSearches.removeAll();
	previousSearches.refresh();
	previousSearchesList.selectedIndex = -1;
	togglePreviousSearches();
}

private function loadPreviousSearches():void {
	var previous:Array = Shared.loadPreviousSearches();
	previousSearches.source = previous;
	previousSearchesButton.enabled = (previous.length > 0);
	for (var i:int = 0; i < previousSearches.length; i++) {
		var params:SearchParams = (previousSearches[i] as SearchParams);
		if ((params != null) && !autoCompleteSearchTexts.contains(params.searchText)) {
			autoCompleteSearchTexts.addItem(params.searchText);
		}
	}
	previousSearches.refresh();
	previousSearchesList.selectedIndex = -1;
	autoCompleteSearchTexts.refresh();
}


private function loadLastSearch():void {
	var start:int = getTimer();
	var loaded:Boolean = false;
	// check for a previous search in the last 30 minutes
	var lastSearchEvent:NCBOSearchEvent = Shared.loadLastSearchResults(SAVE_SEARCH_RESULTS_TIME);
	if (lastSearchEvent != null) {
		if (!lastSearchEvent.isError) {
			if (lastSearchEvent.searchParams) { 
				loadPreviousSearch(lastSearchEvent.searchParams, false)
			}
			if (lastSearchEvent.concepts.length > 0) {
				loaded = true;
				searchResultsHandler(lastSearchEvent, false /* don't save results */);
				if (lastSearchEvent.searchParams) {
					var txt:String = "Loaded last search results from " + 
						dateFormatter.format(lastSearchEvent.searchParams.date);
					setError(txt, "lastSearch");
				}
			}
		} else {
			debug("Error loading last search results: " + lastSearchEvent.error);
		}
	}
	if (loaded) {
		var time:int = getTimer() - start;
		debug("Loaded last search in " + time + "ms");
	}
}

private function searchItemLogged(event:NCBOLogEvent):void {
	// save the previous searches - the search item now has an ID
	if (event.item is SearchParams) {
		var params:SearchParams = (event.item as SearchParams);
		if ((params.id > 0) && previousSearches.contains(params)) {
			Shared.savePreviousSearches(previousSearches.source.slice());
		}
	}
}


////////////////////
// ONTOLOGIES
////////////////////

private function initializeOntologyFilterBox():void {
	if (params.ontology) {
		ontologyFilterBox.initiallySelectedOntologyIDs = params.ontology.split(",");
	}
	ontologyFilterBox.addEventListener("ontologiesLoaded", ontologiesLoadedHandler);
	ontologyFilterBox.addEventListener(ItemsChangedEvent.ITEMS_CHANGED, ontologySelected);
}

private function ontologiesLoadedHandler(event:Event):void {
	// check if a search needs to be saved, it was run on creation
	// must be done AFTER the ontologies are set above
	if (saveSearchParamsAfterOntologiesLoaded != null) {
		saveSearchParameters(saveSearchParamsAfterOntologiesLoaded);
		saveSearchParamsAfterOntologiesLoaded = null;
	}
	
	// if a search wasn't performed on startup - load the last search
	if (initialSearchParams == null) {
		loadLastSearch();
	}
}

private function get selectedOntologies():Array {
	return (ontologyFilterBox ? ontologyFilterBox.selectedOntologies : []);
}

private function set selectedOntologies(sel:Array):void {
	if (ontologyFilterBox) {
		ontologyFilterBox.selectedOntologies = sel;
	}
}

private function ontologySelected(event:ItemsChangedEvent = null):void {
	// improve performance - check for one item different when a checkbox is (de-)selected
	var items:Array = ontologyFilterBox.selectedOntologies;
	var buttons:int = selectedOntologiesBorderBox.numButtons;
	var diff:int = items.length - buttons;
	var all:Boolean = ontologyFilterBox.allOntologiesSelected;
	if (all) {
		selectedOntologiesBorderBox.removeAllButtons();
		selectedOntologiesBorderBox.addLabel(ALL_ONTOLOGIES, ALL_ONTOLOGIES.name, -1, 
			"All ontologies are selected and will be searched", "allOntologies");
	} else {
		var reload:Boolean = true;
		if ((buttons > 1) && event && (event.items.length == 1) && (Math.abs(diff) == 1)) {
			var item:NCBOOntology = (event.items[0] as NCBOOntology);
			var add:Boolean = ontologyFilterBox.isOntologySelected(item);
			if (add) {
				var index:int = items.indexOf(item);
				if (index != -1) {
					selectedOntologiesBorderBox.addButton(item, item.nameAndAbbreviation, index, 
						"Click to remove this ontology", "ontologiesLinkButton", removeSelectedOntology, true);
					reload = false;
				}
			} else {
				var removed:Boolean = selectedOntologiesBorderBox.removeButtonByData(item);
				reload = !removed;
			}
		}
		if (reload) {
			selectedOntologiesBorderBox.removeAllButtons();
			selectedOntologiesBorderBox.addButtons(items, "nameAndAbbreviation", "Click to remove this ontology", 
				"ontologiesLinkButton", removeSelectedOntology, true);
		}
	}
	updateSelectOntologiesCount();
}

private function updateSelectOntologiesCount():void {
	var count:int = selectedOntologiesBorderBox.numButtons;
	var total:int = ontologyFilterBox.ontologiesUnfilteredCount; 
	var all:Boolean = ontologyFilterBox.allOntologiesSelected;
	selectedOntologiesBorderBox.title = "Selected Ontologies (" + 
		(all ? "" + total : count + "/" + total) + "):";
}


//////////////////////////////
// SELECTED ONTOLOGIES BOX
//////////////////////////////

private function removeSelectedOntology(event:Event):void {
	if (event.currentTarget is LinkButton) {
		var ontologyToRemove:NCBOOntology = (LinkButton(event.currentTarget).data as NCBOOntology);
		ontologyFilterBox.setOntologySelected(ontologyToRemove, false);
		//ontologySelected(new ItemsChangedEvent(ItemsChangedEvent.ITEMS_CHANGED, [ itemToRemove ]));
	}
}

//////////////////////
// RECENT SEARCHES
//////////////////////

private function mostPopularSearchesHandler(searches:Array):void {
	addSearches(searches, mostPopularSearchesBorderBox);
}

private function recentSearchesHandler(searches:Array):void {
	addSearches(searches, recentSearchesBorderBox);
}

private function addSearches(searches:Array, box:ScrollingButtonBox):void {
	if (searches && (searches.length > 0)) {
		box.visible = true;
		var tt:String = "Click to use this search again";
		var style:String = "recentSearchLinkButton";
		for each (var search:SearchParams in searches) {
			var linkButton:LinkButton = box.addButton(search, search.searchText, -1, tt, style, loadRecentSearch);
			linkButton.doubleClickEnabled = true;
			linkButton.addEventListener(MouseEvent.DOUBLE_CLICK, runRecentSearch);
			
			// add the most popular & recent searches to the autocomplete search texts
			if (!autoCompleteSearchTexts.contains(search.searchText)) {
				autoCompleteSearchTexts.addItem(search.searchText);
			}
		}
	}
}

private function loadRecentSearch(event:Event):void {
	if (event.currentTarget is LinkButton) {
		var search:SearchParams = ((event.currentTarget as LinkButton).data as SearchParams);
		loadPreviousSearch(search, true, true /* searchText only */);
	}
}

private function runRecentSearch(event:MouseEvent):void {
	if (event.currentTarget is LinkButton) {
		var search:SearchParams = ((event.currentTarget as LinkButton).data as SearchParams);
		loadPreviousSearch(search, true, true /* searchText only */);
		// now run the search
		searchButtonClicked();
	}
	
}

//////////////////////
// SEARCH RESULTS 
//////////////////////

private function searchResultsHandler(event:NCBOSearchEvent, saveResults:Boolean = true):void {
	progress.visible = false;
	searchButton.enabled = true;
	conceptResultsPanel.visible = true;
	CursorManager.removeBusyCursor();
	
	debug("Server time: " + event.serverTime + "ms");
	debug("XML parse time: " + event.parseTime + "ms");
	if (event.totalTime > 0) {
		searchPanel.status = "Search time: " + event.time;
	}
	
	setError((event.isError ? event.error.message : ""));  
	
	// clear previous results
	conceptResults.removeAll();
	ontologyResults.removeAll();

	var conceptResultsArray:Array = event.concepts;
	// don't sort concepts - keep the order returned from the rest services
	var conceptHits:int = conceptResultsArray.length;
	var hasResults:Boolean = (conceptHits > 0);
	if (hasResults) {
		// now add the ontologies to the buttonbox
		var ontologyResultsArray:Array = event.ontologies.slice();	// copy
		// sort ontologies by hits, most first
		ontologyResultsArray.sortOn("hits", Array.NUMERIC | Array.DESCENDING);
		// sort alphabetically
		//ontologyResultsArray.sortOn("name");
		
		// set the new ontology results
		ontologyResults.source = ontologyResultsArray;
		ontologyResults.refresh();
		// there is no point in having the ontology filter button visible if only one ontology
		var total:Number = ontologyResultsArray.length;
		//showOntologyResultsButton.visible = (total > 1);
		showOntologyResultsButton.enabled = (total > 1);
//		var str:String = total + " ontolog" + (total == 1 ? "y" : "ies"); 
//		showOntologyResultsButton.label = str; 
		
		if (saveResults) {
			saveSearch(event);
		}
	} else {
		conceptResultsArray = [ NO_CONCEPT_RESULTS ];
		NO_CONCEPT_RESULTS.searchText = event.searchText;
		showOntologyResultsButton.enabled = false;
	}
	
	conceptResultsList.enabled = hasResults;
	conceptResultsFilter.enabled = hasResults;
	exactMatchesCheckBox.enabled = hasResults;
	// hide the exact matches checkbox if the search was an exact match search
	exactMatchesCheckBox.visible = !event.searchParams.exactMatch;
	//exactMatchesSpacer.visible = exactMatchesCheckBox.visible; 
	
	// finally - set the concepts (in the correct order returned from the XML)
	conceptResults.source = conceptResultsArray;
	conceptResults.refresh();
	
	if (params.doi) {
		// load the Degree Of Interest
		this.callLater(loadConceptsDegreeOfInterest);
	}
}

///////////////////////////////////
// CONCEPT SEARCH RESULTS PANEL
///////////////////////////////////

private function viewSelectedOntology(event:ConceptLinkEvent):void {
	if (event.concept) {
		// open a new window if the user is pressing the CTRL key
		var window:String = (event.ctrlKey ? null : NavigateToBioPortal.SAME_WINDOW);
		NavigateToBioPortal.viewOntologyMetaData(event.concept.ontology, window);
	}
}

private function viewSelectedConcept(event:ConceptLinkEvent):void {
	if (event.concept) {
		// open a new window if the user is pressing the CTRL key
		var window:String = (event.ctrlKey ? null : NavigateToBioPortal.SAME_WINDOW);
		NavigateToBioPortal.viewConcept(event.concept, event.ontologyID, window);
	}
}

private function visualizeSelectedConcept(event:ConceptLinkEvent):void {
	if (event.concept != null) {
		var ontology:NCBOSearchResultOntology = event.concept.ontology;
		flexVizWindow.showConcept(event.conceptID, ontology.ontologyVersionID, 
								  event.concept.name, ontology.displayLabel, service.baseURL);
		LogService.logConceptEvent(event.concept, ontology.ontologyVersionID, "visualize concept"); 
	}
}

private function viewDetailsSelectedConcept(event:ConceptLinkEvent):void {
	if (event.concept != null) {
		CursorManager.setBusyCursor();
		var ontology:NCBOSearchResultOntology = event.concept.ontology;
		service.getConceptByID(ontology.ontologyVersionID, event.conceptID, 
			function(conceptEvent:NCBOConceptEvent):void {
				CursorManager.removeBusyCursor();
				if (conceptEvent.concept) {
					var newWindow:Boolean = event.ctrlKey;
					showConceptDetails(conceptEvent.concept, ontology.displayLabel, newWindow);
				}
			});
		LogService.logConceptEvent(event.concept, ontology.ontologyVersionID, "concept details"); 
	}
}

private function initializeConceptResults():void {
	// listen for link clicked events on the DataGrid itemRenderers
	conceptResultsList.addEventListener(ConceptLinkEvent.CONCEPT_LINK_CLICKED, viewSelectedConcept);
	conceptResultsList.addEventListener(ConceptLinkEvent.ONTOLOGY_LINK_CLICKED, viewSelectedOntology);
	conceptResultsList.addEventListener(ConceptLinkEvent.VISUALIZATION_LINK_CLICKED, visualizeSelectedConcept);
	conceptResultsList.addEventListener(ConceptLinkEvent.DETAILS_LINK_CLICKED, viewDetailsSelectedConcept);
	
	conceptResults.filterFunction = conceptResultsFilterFunction;
	conceptResultsFilter.filterList = conceptResultsList;
	conceptResults.addEventListener(CollectionEvent.COLLECTION_CHANGE, conceptResultsChanged);
	var linkRenderer:ConceptLinkItemHighlightRenderer = new ConceptLinkItemHighlightRenderer();
	linkRenderer.highlighter = conceptsTextHighlighter;
	conceptsTextHighlighter.highlightTextFunction = function():String {
		return conceptResultsFilter.text;
	};
	conceptResultsColumn.itemRenderer = linkRenderer;
	//detailsColumn.headerRenderer = new IconItemRenderer(detailsIcon, null, "Concept Details");
	//vizColumn.headerRenderer = new IconItemRenderer(vizIcon, null, "Visualization");
	
	var popUp:DOIPopUp = new DOIPopUp();
	popUp.source = DOI_RESULTS;
	popUp.addEventListener(DOIPopUp.HIGHLIGHTING_CHANGED, resultsDOIHighlightingChanged);
	popUp.addEventListener(DOIPopUp.FILTERING_CHANGED, resultsDOIFilteringChanged);
	popUp.addEventListener(DOIPopUp.SORTING_CHANGED, resultsDOISortChanged);
	resultsDOIPopUpButton.popUp = popUp;
	
	// Set up the experimental interest/landmark thresholds
	DegreeOfInterestService.setThresholds(DOI_RESULTS, 3, 20);
	if (!params.doi) {
		resultsDOIPopUpButton.visible = false;
		resultsDOIPopUpButton.width = 0;
	}
}

private function conceptResultsFilterFunction(item:Object):Boolean {
	var pass:Boolean = false;
	if (item is NCBOSearchResultConcept) {
		var concept:NCBOSearchResultConcept = NCBOSearchResultConcept(item);
		pass = true;
		
		// first check if the concept's ontology is selected
		// we only check if at least one ontology is selected, otherwise all concepts are shown
		if (!OntologyResultsFilterPopUpBox(showOntologyResultsButton.popUp).isSelected(concept.ontology)) {
			pass = false;
		}
		
		if (pass && exactMatchesCheckBox.selected) {
			pass = StringUtils.equals(concept.name, concept.searchText, true);
		}
		
		// now filter by the filter text
		if (pass && (conceptResultsFilter.text.length > 0)) {
			pass = conceptResultsFilter.filterFunction(concept);
		}
		
		// filter by degree of interest
		if (pass && DegreeOfInterestService.isFiltering(DOI_RESULTS) && resultsDOIPopUpButton.enabled) {
			pass = DegreeOfInterestService.isInteresting(concept, DOI_RESULTS);
		}
	}
	return pass;
}

private function conceptResultsChanged(event:CollectionEvent):void {
	var src:int = conceptResults.source.length;
	var filtered:int = conceptResults.length; 
	if (src == 0) {
		conceptResultsPanel.status = "";
	} else if ((src == 1) && (conceptResults.source[0] == NO_CONCEPT_RESULTS)) {
		// special case for no results
		conceptResultsPanel.status = "0 results";
	} else if (src == filtered) {
		conceptResultsPanel.status = src + " result" + (src == 1 ? "" : "s");
	} else {
		conceptResultsPanel.status = filtered + "/" + src + " results shown";
	}
}

private function exactMatchesChanged(event:Event = null):void {
	conceptResults.refresh();
	LogService.logNavigationEvent("", "", "filter results", "exact matches", (exactMatchesCheckBox.selected ? 1 : 0));
}

private function resultsDOIHighlightingChanged(event:Event):void {
	var on:Boolean = DegreeOfInterestService.isHighlighting(DOI_RESULTS);
	conceptsTextHighlighter.enabled = !on;
	repaintConceptResultRenderers();
}

private function resultsDOIFilteringChanged(event:Event):void {
	conceptResults.refresh();
}

private function resultsDOISortChanged(event:Event):void {
	var on:Boolean = DegreeOfInterestService.isSorting(DOI_RESULTS);
	var col:DataGridColumn = conceptResultsColumn;
	var sortField:SortField = null;
	if (on && (col.sortCompareFunction != DegreeOfInterestService.degreeOfInterestSortFunction)) {
		col.sortCompareFunction = DegreeOfInterestService.degreeOfInterestSortFunction;
		sortField = new SortField(col.dataField, false, false, true);
		sortField.compareFunction = col.sortCompareFunction;
	} else if (!on && (col.sortCompareFunction == DegreeOfInterestService.degreeOfInterestSortFunction)) {
		col.sortCompareFunction = compareConceptNames;
		sortField = new SortField(col.dataField, true, false, false);
		sortField.compareFunction = col.sortCompareFunction;
	}
	if (sortField) {
		var s:Sort = new Sort();
		s.fields = [ sortField ];
		conceptResults.sort = s;
        conceptResults.refresh();
	}
}

private function loadConceptsDegreeOfInterest():void {
	DegreeOfInterestService.loadDegreeOfInterest(conceptResults.source, resultsDegreeOfInterestLoaded);
	resultsDOIPopUpButton.startSpinning();
}

private function resultsDegreeOfInterestLoaded(changedResults:Array, error:String = null):void {
	DegreeOfInterestService.debugItems(changedResults);
	resultsDOIPopUpButton.stopSpinning();
	if (!error) {
		resultsDOIPopUpButton.enabled = true;
		if (DegreeOfInterestService.isHighlighting(DOI_RESULTS)) {
			repaintConceptResultRenderers();
		}
		if (DegreeOfInterestService.isFiltering(DOI_RESULTS)) {
			conceptResults.refresh();
		}
		if (DegreeOfInterestService.isSorting(DOI_RESULTS)) {
			resultsDOISortChanged(null);
		}
	}
}

private function repaintConceptResultRenderers():void {
	for each (var item:Object in conceptResults) {
		var renderer:IListItemRenderer = conceptResultsList.itemToItemRenderer(item);
		if (renderer && (renderer is UIComponent)) {
			UIComponent(renderer).invalidateDisplayList();
		}
	}
}

private function conceptResultsHeaderRelease(event:DataGridEvent):void {
	var column:DataGridColumn = DataGridColumn(conceptResultsList.columns[event.columnIndex]);
	conceptResultsList.callLater(function():void {
		LogService.logNavigationEvent("", "", "sort results", column.headerText, (column.sortDescending ? 1 : 0));
	});
}

// sort the concept names column (ignore case)
private function compareConceptNames(c1:NCBOSearchResultConcept, c2:NCBOSearchResultConcept):int {
	return StringUtils.compareObjects(c1, c2, true, "name");
}

// sort the ontology names column (ignore case)
private function compareOntologyNames(c1:NCBOSearchResultConcept, c2:NCBOSearchResultConcept):int {
	return StringUtils.compareObjects(c1, c2, true, "ontologyName");
}

private function compareOntologyVersionIDs(c1:NCBOSearchResultConcept, c2:NCBOSearchResultConcept):int {
	return StringUtils.compareObjects(c1, c2, true, "ontologyVersionID");
}

private function compareOntologyIDs(c1:NCBOSearchResultConcept, c2:NCBOSearchResultConcept):int {
	return StringUtils.compareNumbers(c1, c2, "ontologyID");
}


private function showConceptDetails(concept:NCBOConcept, ontologyName:String, newWindow:Boolean):void {
	var window:ConceptPropertyWindow;
	// check to make sure this concept isn't already being shown
	for (var i:int = 0; i < propertyWindows.length; i++) {
		window = propertyWindows[i];
		if (window && (window.concept == concept)) {
			UIUtils.bringToFront(window);
			return;
		}
	}

	if (newWindow || (propertyWindows.length == 0)) {
		window = new ConceptPropertyWindow();
		window.showCloseButton = true;
		window.titleIcon = detailsIcon;
		positionNewPropertiesWindow(window);
		Application.application.addChild(window);
	} else {
		window = (propertyWindows[0] as ConceptPropertyWindow);
		window.concept = null;	// remove the old details
		UIUtils.bringToFront(window);
	}
	window.concept = concept;
	window.title = "Details for " + concept.name + " [" + ontologyName + "]    ";
	propertyWindows.push(window);
	
	var closeHandler:Function = function(event:CloseEvent):void {
		window.removeEventListener(CloseEvent.CLOSE, closeHandler);
		if (window.parent) {
			window.parent.removeChild(window);
		}
		var index:int = propertyWindows.indexOf(window);
		if (index != -1) {
			propertyWindows.splice(index, 1);
		}
	};
	window.addEventListener(CloseEvent.CLOSE, closeHandler);
}

private function positionNewPropertiesWindow(window:UIComponent):void {
	var point:Point;
	if (propertyWindows.length > 0) {
		var rel:DisplayObject = (propertyWindows[propertyWindows.length - 1] as DisplayObject);
		var allowed:Rectangle = new Rectangle(0, 0, Application.application.width - 200, 
											  Application.application.height - 200);
		// below
		point = new Point(rel.x, rel.y + rel.height);
		// right
		if (!allowed.containsPoint(point)) {
			point.x = rel.x + rel.width;
			point.y = rel.y;
		}
		// right and below
		if (!allowed.containsPoint(point)) {
			point.y = rel.y + rel.height;
		}
		// default
		if (!allowed.containsPoint(point)) {
			point.x = 120;
			point.y = 200; 
		}
	} else {
		point = new Point(120, 200);
	}
	window.move(point.x, point.y);
}


/////////////////////////////////////
// HELP FUNCTIONS
/////////////////////////////////////

private function initHelp():void {
	for (var i:int = 1; i < helpPanel.numChildren; i += 2) {
		var child:UIComponent = (helpPanel.getChildAt(i) as UIComponent);
		if (child) {
			child.styleName = "alt";
		}
	}
}

private function toggleHelpPanel(event:Event = null):void {
	var animate:MoveResize = new MoveResize(helpPanel);
	animate.duration = 600;
	var bounds:Rectangle = helpButton.getBounds(Application.application.stage);
	if (helpPanel.visible) {
		lastHelpPanelBounds = new Rectangle(helpPanel.x, helpPanel.y, helpPanel.width, helpPanel.height);
		animate.boundsTo = bounds;
		animate.addEventListener(EffectEvent.EFFECT_END, resizeHelpPanelFinished);
	} else {
		if ((helpPanel.x != bounds.x) || (helpPanel.y != bounds.y)) {
			helpPanel.move(bounds.x, bounds.y);
			helpPanel.width = bounds.width;
			helpPanel.height = bounds.height;
		}
		helpPanel.visible = true;
		animate.boundsTo = lastHelpPanelBounds;
	}
	animate.play();
}

private function resizeHelpPanelFinished(event:EffectEvent):void {
	event.currentTarget.removeEventListener(EffectEvent.EFFECT_END, resizeHelpPanelFinished);
	helpPanel.visible = false;
}


//////////////////
// TESTING
//////////////////

private function loadTestData():void {
	var ontology:NCBOSearchResultOntology = new NCBOSearchResultOntology("39004", "1006", "Cell type");
	var concept:NCBOSearchResultConcept = new NCBOSearchResultConcept("CL:0000522", "spore", "", "", ontology, "spore");
	conceptResults.addItem(concept);
	concept = new NCBOSearchResultConcept("CL:0000596", "sexual spore", "", "", ontology, "spore");
	ontologyResults.addItem(ontology);
	conceptResults.addItem(concept);
	ontology = new NCBOSearchResultOntology("13578", "1032", "NCI Thesaurus");
	concept = new NCBOSearchResultConcept("Melanoma", "Melanoma", "", "", ontology, "melanoma");
	conceptResults.addItem(concept);
	ontologyResults.addItem(ontology);
	ontology = new NCBOSearchResultOntology("", "", "Blah");
	ontologyResults.addItem(ontology);
	ontology = new NCBOSearchResultOntology("", "", "Blah2");
	ontologyResults.addItem(ontology);
	ontology = new NCBOSearchResultOntology("", "", "Blah3");
	ontologyResults.addItem(ontology);
	ontology = new NCBOSearchResultOntology("", "", "Blah4");
	ontologyResults.addItem(ontology);
	loadTestOntologies();
}

private function loadTestOntologies():void {
	var ontologies:Array = [];
	ontologies.push(createTestOntology(32145, 1099, "African Traditional Medicine", "ATMO", [ 5058 ]));
	ontologies.push(createTestOntology(4519, 1054, "Amino Acid", "amino-acid", [ 2801 ]));
	ontologies.push(createTestOntology(39433, 1070, "Biological Process", "GO", [ 2806 ]));
	ontologies.push(createTestOntology(39002, 1104, "Biological Resource Ontology", "BRO", [ 5059 ]));
	ontologies.push(createTestOntology(29684, 1089, "BIRNLex", "birnlex", [ 5057, 2810 ]));
	ontologies.push(createTestOntology(39004, 1006, "Cell type", "CL", [ 2810 ]));
	ontologies.push(createTestOntology(39284, 1007, "Chemical entities of biological interest", "CHEBI", [ 2802 ]));
	ontologies.push(createTestOntology(4513, 1053, "FMA", "FMA", [ 2810 ]));
	ontologies.push(createTestOntology(4525, 1055, "Galen", "", [ 2801 ]));
	ontologies.push(createTestOntology(39228, 1009, "Human disease", "DOID", [ 2807 ]));
	ontologies.push(createTestOntology(29981, 1092, "Infectious disease", "IDO", [ 2807 ]));
	ontologies.push(createTestOntology(39310, 1000, "Mouse adult gross anatomy", "MA", [ 2812, 2810, 2817, 2811 ]));
	ontologies.push(createTestOntology(13578, 1032, "NCI Thesaurus", "NCI", []));
	ontologies.push(createTestOntology(3905, 1052, "Protein Ontology", "", [ 2821, 2806 ]));
	ontologies.push(createTestOntology(39394, 1051, "Zebrafish anatomy and development", "ZFA", [ 2812, 2813, 2810, 2811 ]));
	ontologiesLoadedHandler(new NCBOOntologiesEvent(ontologies));
}

private function createTestOntology(id:Number, ontologyID:Number, displayName:String, abbrev:String, categoryIDs:Array):NCBOOntology {
	var o:NCBOOntology = new NCBOOntology(id.toString(10), ontologyID.toString(), displayName, abbrev);
	o.categoryIDs = categoryIDs;
	return o;
}
