// ActionScript file for OBRSearchByElement.mxml
import events.AnnotateTextEvent;
import events.OBSEvent;
import events.TagClickedEvent;

import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TextEvent;
import flash.geom.Rectangle;
import flash.net.URLRequest;
import flash.net.URLVariables;
import flash.net.navigateToURL;
import flash.text.TextFormat;
import flash.ui.Keyboard;
import flash.utils.clearTimeout;
import flash.utils.setTimeout;

import flex.utils.ArrayUtils;
import flex.utils.Map;
import flex.utils.StringUtils;
import flex.utils.Utils;
import flex.utils.ui.ButtonBox;
import flex.utils.ui.MoveResize;
import flex.utils.ui.UIUtils;
import flex.utils.ui.events.ItemsChangedEvent;
import flex.utils.ui.validators.ErrorTipManager;

import model.Annotation;
import model.AnnotationContext;
import model.AnnotationStats;
import model.Ontology;
import model.SemanticType;

import mx.collections.ArrayCollection;
import mx.containers.FormItem;
import mx.containers.Panel;
import mx.controls.Label;
import mx.core.Application;
import mx.events.CollectionEvent;
import mx.events.EffectEvent;
import mx.events.FlexEvent;
import mx.events.ValidationResultEvent;
import mx.managers.CursorManager;
import mx.utils.StringUtil;

import org.ncbo.uvic.flex.NCBORestService;
import org.ncbo.uvic.flex.events.NCBOOntologiesEvent;
import org.ncbo.uvic.flex.model.NCBOOntology;
import org.ncbo.uvic.flex.ui.DebugPanel;
import org.ncbo.uvic.flex.util.NavigateToBioPortal;

import service.AnnotatorParameters;
import service.OBSRestService;
import service.ResourceIndexParameters;

import ui.CheckBoxWindow;
import ui.ResultFormatButton;
import ui.SearchOptions;

import util.HelpText;


/////////////////////
// VARIABLES 
/////////////////////

private static const MAX_WORDS:uint = 300;

private var restService:OBSRestService = new OBSRestService(OBSRestService.DEFAULT_APIKEY);
private var ncboService:NCBORestService = new NCBORestService(NCBORestService.APIKEY_OBS, NCBORestService.APP_ID_OBS, null, null, "obs@uvic.ca");
private var resourceIndexParams:ResourceIndexParameters = new ResourceIndexParameters();
private var annotatorParams:AnnotatorParameters = new AnnotatorParameters();

// saved copies of successful searches, in order to be able to run again with different formats an opened in a new window (post)
[Bindable]
private var lastAnnotatorParams:URLVariables = null;

[Bindable]
private var ontologyResults:ArrayCollection = new ArrayCollection();
[Bindable]
private var conceptResults:ArrayCollection = new ArrayCollection();
[Bindable]
private var annotationResults2:ArrayCollection = new ArrayCollection();

private var annotationResults:ArrayCollection = new ArrayCollection();
// maps Ontology.id to Ontology
private var _selectedOntologiesMap:Object = null;

// maps ontologyID/conceptIDs to an Array of Annotation objects
private var conceptAnnotations:Object;

// maps the conceptName to an Array of Annotation objects
private var conceptNameToAnnotations:Object;
private var htmlLinks:Object;	// maps the term names to an Array of the Annotation objects 

private var params:FlexParams;

private var lastHelpPanelBounds:Rectangle = new Rectangle(120, 105, 600, 450);
private var lastResultsHelpPanelBounds:Rectangle = new Rectangle(150, 350, 600, 250);

//private var multipleInitialOntologies:Boolean = false;
private var ontologyAbbreviations:Object = new Object();

private const ALL_ONTOLOGIES:String = "All Ontologies Selected";
[Bindable]
private var ontologiesText:String = ALL_ONTOLOGIES;

private const ALL_SEM_TYPES:String = "All Semantic Types Selected";
[Bindable]
private var semanticTypesText:String = ALL_SEM_TYPES;

/////////////////////
// EVENT HANDLERS
/////////////////////

private function init(event:FlexEvent):void {
	params = new FlexParams();
	NavigateToBioPortal.baseURL = params.redirectURL;
	restService.baseURL = params.server;
	ncboService.baseURL = params.server;
	resultsBox.visible = false;
	
	if (params.apikey) {
		restService.apikey = params.apikey;
		ncboService.apikey = params.apikey;
	}
	
	// move the help buttons into the titlebar
	searchPanel.addTitleBarButton(helpButton);
	tagCloudPanel.addTitleBarButton(resultsHelpButton);
	helpButton.visible = true; 
	
	ncboService.getNCBOOntologies(function(event:NCBOOntologiesEvent):void {
		if (!event.isError) {
			var versionIDs:Array = (params.ontology ? params.ontology.split(",") : []);
			var abbrevs:Array = [];
			var ontIDs:Array = [];
			for each (var ont:NCBOOntology in event.ontologies) {
				ontologyAbbreviations[ont.ontologyID] = ont.abbreviation;
				if (versionIDs.indexOf(ont.ontologyVersionID) != -1) {
					abbrevs.push(ont.hasAbbreviation ? ont.abbreviation : ont.name);
					if (ontIDs.indexOf(ont.ontologyVersionID) == -1) {
						ontIDs.push(ont.ontologyVersionID);
					}
				}
			}
			updateOntologiesInput(abbrevs.join(","));
			annotatorParams.ontologiesToKeepInResult = ontIDs.join(",");
		}
	});
}

private function created(event:FlexEvent):void {
	// Add CTRL-T support for opening new tab
	Utils.addOpenNewTabListener();
	
	annotateTextInput.setFocus();
	ErrorTipManager.registerValidator(annotateTextValidator);
	
	annotationResults.filterFunction = conceptsFilterFunction;
	annotationResults.addEventListener(CollectionEvent.COLLECTION_CHANGE, function(event:CollectionEvent):void {
		updateStatus(annotationResults, tagCloudPanel);
	});
	
	// initially position the help panels
	var app:DisplayObject = DisplayObject(Application.application);
	var screenWidth:Number = app.width;
	if (screenWidth > 1360) {
		var searchBounds:Rectangle = searchPanel.getBounds(app);
		lastHelpPanelBounds = new Rectangle(searchBounds.right + 5, searchBounds.top, 350, 680);
		UIUtils.setBounds(helpPanel, lastHelpPanelBounds);
		lastResultsHelpPanelBounds = new Rectangle(searchBounds.right + 5, searchBounds.bottom + 10, 350, 320);
		UIUtils.setBounds(resultsHelpPanel, lastResultsHelpPanelBounds);
	}
	
	if (params.ontology) {
		var ontIDs:Array = [ params.ontology ];
		var split:Array = params.ontology.split(",");
		if (split.length > 1) {
			ontIDs = [];
			for (var i:int = 0; i < split.length; i++) {
				var id:String = StringUtil.trim(split[i]);
				if (id) {
					ontIDs.push(id);
				}
			}
		}
		annotatorParams.ontologiesToKeepInResult = ontIDs.join(",");
//		if (ontIDs.length > 0) {
//			multipleInitialOntologies = (ontIDs.length > 1);
//			ontologiesText = "";
//			for each (var ontID:String in ontIDs) { 
//				restService.getAnnotatorOntology(ontID, ontologyLoaded);
//			}
//		}
	}
	if (params.semanticTypes) {
		annotatorParams.semanticTypes = params.semanticTypes;
		restService.getSemanticTypes(semanticsTypesLoaded);
	}
	if (params.search.length > 0) {
		annotateTextInput.text = params.search;
		this.callLater(performSearch);
	}
	
	addEventListener(FlexEvent.APPLICATION_COMPLETE, appComplete);
}

private function appComplete(event:FlexEvent):void {
	removeEventListener(FlexEvent.APPLICATION_COMPLETE, appComplete);
	stage.addEventListener(KeyboardEvent.KEY_DOWN, globalKeyHandler);
	// use JavaScript to focus our Flex application
	//ExternalInterface.call("focusApp");
}

private function globalKeyHandler(event:KeyboardEvent):void {
	var char:String = String.fromCharCode(event.charCode).toUpperCase();
	if (event.ctrlKey && event.shiftKey && (char == "D")) {
		event.stopImmediatePropagation();
		showDebugPanel();
	}
}

private function showDebugPanel():void {
	var par:DisplayObject = DisplayObject(this);
	var extraCalls:Array = restService.restCalls;
	var vers:String = (parameters.hasOwnProperty("v") ? parameters["v"] : "?");
	var dp:DebugPanel = DebugPanel.showDebugPanel(par, vers, null, extraCalls);
	dp.addRestURL("Annotator Base URL", restService.annotatorBaseURL);
	dp.addRestURL("Resources Base URL", restService.resourcesBaseURL);
	//dp.addRestURL("Ontology Recommended Base URL", restService.recommendedBaseURL);
}

private function resetForm():void {
	updateOntologiesInput();
	updateSemanticTypesInput();
	annotatorParams = new AnnotatorParameters();
	clearResults();
	annotateTextInput.clearHighlight();
	annotateTextInput.text = "";
	annotateTextInput.setFocus();
	ErrorTipManager.hideErrorTip(annotateTextInput, true);
}

private function clearResults():void {
	resultsBox.visible = false;
	ontologyResults = new ArrayCollection();
	conceptResults = new ArrayCollection();
	annotationResults = new ArrayCollection();
	annotationStatsBox.removeAllChildren();
	lastAnnotatorParams = null;
	
	// have to re-set the filter functions
	annotationResults.filterFunction = conceptsFilterFunction;
}

private function clearErrorMessage():void {
	errorLabel.text = "";
	errorLabel.height = 0;
}
	
private function errorMessage(msg:String, isHtml:Boolean = false, addLinkColoring:Boolean = true):void {
	if (isHtml) {
		errorLabel.htmlText = (addLinkColoring ? StringUtils.addLinkStyle(msg, HelpText.LINK_COLOR) : msg);
	} else {
		errorLabel.text = msg;
	}
	errorLabel.height = NaN;	// autosize
}

private function debug(msg:String):void {
	if (params.debug) {
		trace(msg);
	}
}

//private function ontologyLoaded(event:OBSEvent):void {
//	if (event.isError) {
//		if (multipleInitialOntologies && ontologiesText) {
//			trace(event.errorMessage);
//		} else {
//			updateOntologiesInput(event.errorMessage, true, false);
//		}
//	} else {
//		var ont:Ontology = event.items[0];
//		if (ont) {
//			var name:String = getOntologyAbbreviation(ont);
//			if (multipleInitialOntologies && ontologiesText) {
//				name = ontologiesText + ", " + name;
//			}
//			updateOntologiesInput(name);
//		}
//	}
//}

private function getOntologyAbbreviation(ont:Ontology):String {
	var str:String = null;
	if (ont) {
		if (ont.abbreviation) {
			str = ont.abbreviation;
		} else if (ontologyAbbreviations.hasOwnProperty(ont.ontologyID)) {
			str = ontologyAbbreviations[ont.ontologyID];
		} else {
			str = ont.name;
		}
	}
	return str;
}

private function updateOntologiesInput(message:String = "", error:Boolean = false, changeButtonEnablement:Boolean = true):void {
	ontologiesInput.styleName = (error ? "error" : (message ? "borderLabel" : "borderLabelNoInput"));
	ontologiesText = (message ? message : ALL_ONTOLOGIES);
	if (changeButtonEnablement) {
		chooseOntologiesButton.enabled = !error;
	}
}

private function semanticsTypesLoaded(event:OBSEvent):void {
	var selectedTypes:Array = [];
	if (!event.isError) {
		var initialTypes:Array = params.semanticTypes.split(",");
		var semTypes:Array = event.items;
		for each (var semanticType:SemanticType in semTypes) {
			var index:int = initialTypes.indexOf(semanticType.id); 
			if (index != -1) {
				selectedTypes.push(semanticType);
				initialTypes.splice(index, 1);
				if (initialTypes.length == 0) {
					break;
				}
			}
		}
	}
	semanticTypesChosen(selectedTypes);
}

private function updateSemanticTypesInput(message:String = "", error:Boolean = false):void {
	semanticTypesInput.styleName = (error ? "error" : (message ? "borderLabel" : "borderLabelNoInput"));
	semanticTypesText = (message ? message : ALL_SEM_TYPES);
	chooseSemanticTypesButton.enabled = !error;
}

private function annotateText_KeyDown(event:KeyboardEvent):void {
	if (event.ctrlKey && (event.keyCode == Keyboard.ENTER)) {
		performSearch();
		event.preventDefault();
	}
}

private function searchButtonClicked(event:MouseEvent):void {
	performSearch();
}

private function chooseOntologies(event:MouseEvent):void {
	var resultHandler:Function = function(event:OBSEvent):void {
		//trace("Loaded " + (isAnnotateState ? "Annotator " : " Resource ") + " ontologies: " + event.items.length);
		CursorManager.removeBusyCursor();
		if (!event.isError) {
			var ontologyIDs:Array = annotatorParams.ontologiesToKeepInResult.split(",");
			var selectedItems:Array = new Array();
			var ontologies:Array = event.items;
			for each (var ontology:Ontology in ontologies) {
				if (ontologyAbbreviations.hasOwnProperty(ontology.ontologyID)) {
					ontology.abbreviation = ontologyAbbreviations[ontology.ontologyID];
				}
				if (ontologyIDs.indexOf(ontology.id) != -1) {
					selectedItems.push(ontology);
				}
			}
			// sort alphabetically (bug #1399)
			ontologies.sortOn("name", Array.CASEINSENSITIVE);
			CheckBoxWindow.showWindow("Choose Ontologies", searchForm, ontologies, selectedItems, ontologiesChosen, true);
		} else {
			updateOntologiesInput("Error loading ontologies: " + event.errorMessage, true);
		}
	};
	// different ontologies
	CursorManager.setBusyCursor();
	restService.getAnnotatorOntologies(resultHandler);
}

private function ontologiesChosen(ontologies:Array, allSelected:Boolean = false):void {
	if (ontologies != null) {
		var str:String = "";
		annotatorParams.ontologiesToKeepInResult = "";
		if ((ontologies.length > 0) && !allSelected) {
			annotatorParams.ontologiesToKeepInResult = ArrayUtils.arrayToString(ontologies, ",", -1, "id");
			str = ArrayUtils.arrayToString(ontologies, ",", -1, "abbreviationOrName");
		}
		updateOntologiesInput(str);
	}
}

private function chooseSemanticTypes(event:MouseEvent):void {
	// semantic types are the same in the new annotator service and the old dev service
	restService.getSemanticTypes(function(event:OBSEvent):void {	
		if (!event.isError) {
			var semanticTypeIDs:Array = annotatorParams.getSemanticTypeIDs();
			var selectedItems:Array = new Array();
			var semanticTypes:Array = event.items.slice();
			for each (var type:SemanticType in semanticTypes) {
				if (semanticTypeIDs.indexOf(type.id) != -1) {
					selectedItems.push(type);
				}
			} 
			CheckBoxWindow.showWindow("Choose Semantic Types", searchForm, semanticTypes, selectedItems, semanticTypesChosen);
		} else {
			updateSemanticTypesInput("Error loading semantic types: " + event.errorMessage, true);
		}
	});
}

private function semanticTypesChosen(types:Array, allSelected:Boolean = false):void {
	if (types != null) {
		annotatorParams.setSemanticTypes(types);
		if ((types.length > 0) && !allSelected) {
			updateSemanticTypesInput(types.join(", "));
		} else {
			updateSemanticTypesInput();
		}
	}
}

private function chooseOptions(event:MouseEvent):void {
	SearchOptions.showWindow(searchForm, restService, resourceIndexParams, annotatorParams, true);
}

////////////////////////
// PRIVATE FUNCTIONS
////////////////////////

private function validateAnnotatorForm():Boolean {
	annotatorParams.textToAnnotate = StringUtil.trim(annotateTextInput.text);
	// copy annotated text back into textinput to remove trimmed characters (esp. at the start)
	annotateTextInput.text = annotatorParams.textToAnnotate;
	annotateTextValidator.source = annotateTextInput; 
	var result:ValidationResultEvent = annotateTextValidator.validate();
	return (result.type == ValidationResultEvent.VALID);
}

private function performSearch():void {
	clearErrorMessage();
	clearResults();
	if (validateAnnotatorForm()) {
		annotateTextInput.clearHighlight();
		progress.label = "Annotating...";
		progress.visible = true;
		searchButton.enabled = false;
		// set to true for OBA calls
		annotatorParams.withDefaultStopWords = true;
		restService.annotateText(annotatorParams, annotateTextCallback);
	}
}

private function annotateTextCallback(event:AnnotateTextEvent):void {
	debug("Annotate text callback: " + event.items.length + ", " + event.ontologies.length);
	trace("Annotation took " + event.serverTime + "ms, parsing took " + event.parseTime + "ms");
	if (!event.isError) {
		// save a copy of these parameters in order to be able to run it again (with a different output format)
		this.lastAnnotatorParams = Utils.objectToURLVariables(annotatorParams);
		// special case for mapping types
		if (annotatorParams.mappingTypes == null) {
			delete lastAnnotatorParams["mappingTypes"];
		}
		
		// need to collect the annotations by conceptID
		// also collect the mgrep context sentences
		var inputText:String = event.annotatorParams.textToAnnotate;
		
		// collect the concepts with the same name
		var conceptNames:Array = [];
		conceptNameToAnnotations = {};
		
		var singleConceptAnnotations:Array = [];
		conceptAnnotations = new Object();
		for each (var annotation:Annotation in event.annotations) {
			var key:String = annotation.ontologyAndConceptID;
			if (!conceptAnnotations.hasOwnProperty(key)) {
				conceptAnnotations[key] = new Array();
				singleConceptAnnotations.push(annotation);
			} else {
				// Collect the extra contexts, needed for stats purposes
				var existing:Annotation = null;
				for each (var ann:Annotation in singleConceptAnnotations) {
					if (ann.ontologyAndConceptID == key) {
						existing = ann;
						break;
					}
				}
				if (existing != null) {
					existing.allContexts.push(annotation.context);
				}
			}
			var array:Array = (conceptAnnotations[key] as Array);
			array.push(annotation);

			var lcName:String = annotation.conceptName.toLowerCase();
			if (!conceptNameToAnnotations.hasOwnProperty(lcName)) {
				conceptNameToAnnotations[lcName] = [ annotation ];
				conceptNames.push(StringUtils.capitalize(annotation.conceptName));
			} else {
				(conceptNameToAnnotations[lcName] as Array).push(annotation);
			}
			
			if (annotation.context && (annotation.context.offsetStart != -1)) {
				// the start index needs to be changed from one-base to zero-base
				var start:int = annotation.context.offsetStart - 1;
				// need to include the last character too, so don't take off one here
				var end:int = annotation.context.offsetEnd;
				if ((start >= 0) && (end > start) && (end <= inputText.length)) {
					annotation.context.sentence = StringUtils.extractSentence(inputText, start, end);
					annotation.context.sentenceOffset = inputText.indexOf(annotation.context.sentence);
				}
			}
		}
		//trace("Single: " + singleConceptAnnotations.length + ", all: " + event.annotations.length);
		
		conceptNames.sort(Array.CASEINSENSITIVE);
		conceptResults.source = conceptNames;
		annotationResults2 = new ArrayCollection();
		
		// must set the ontologies first for the filter to work
		loadOntologies(event.ontologies);
		// we only want to show one annotation per concept in the tag cloud
		loadTagCloud(singleConceptAnnotations);
		loadAnnotationStats(event.annotationStats);
		// because we've combined all the same named concepts we need to 
		// re-calculate the statistics
		calculateFilteredAnnotationStats();
		
		// do we want to use event.annotations or singleConceptAnnotations here?
		highlightAnnotateInputText(annotationResults);
		
		conceptsBox.callLater(function():void {
			if (conceptResults.length > 10) {
				conceptsBox.selectedItems = conceptResults.source.slice(0, 10);
			} else {
				conceptsBox.selectAll();
			}
		});
	} else {
		this.lastAnnotatorParams = null;

		var msg:String = event.errorMessage;
		// special error message when a timeout occurs
		if ((event.fault != null) && (event.fault.faultCode == "Client.Error.RequestTimeout")) {
			msg = "The NCBO Annotator user interface is limited for usability purposes. Please use the <a href=\"event:http://bioontology.org/wiki/index.php/Annotator_Web_service\">NCBO Annotator web service</a> for more powerful possibilities.";
		}
		errorMessage(msg, true);
	}
	resultsBox.visible = true;
	progress.visible = false;
	searchButton.enabled = true;
}

// not used
//private function annotationStatisticsCallback(event:OBSEvent):void {
//	if (!event.isError) {
//		var stats:Array = event.items;
//		loadAnnotationStats(stats);
//	} else {
//		var errorLbl:Label = new Label();
//		errorLbl.styleName = "error";
//		errorLbl.text = event.errorMessage;
//		annotationStatsBox.removeAllChildren();
//		annotationStatsBox.addChild(errorLbl);
//	}
//}

private function highlightAnnotateInputText(annotations:ArrayCollection):void {
	annotateTextInput.clearHighlight();
	if (annotations.length == 0) {
		return;
	}
	
	var hf:TextFormat = annotateTextInput.highlightTextFormat;
	var format:TextFormat = new TextFormat(hf.font, hf.size, 0x70A3C8, true, hf.italic, true/*hf.underline*/);
	var txt:String = annotateTextInput.text;
	if (!txt) {
		txt = "";
	}
	var seen:Object = new Object();	
	var terms:Map = new Map();
	htmlLinks = new Object();
	var start:int, end:int, word:String, key:String;
	for each (var annotation:Annotation in annotations) {
		var context:AnnotationContext = annotation.firstMgrepContext;
		if (context != null) {
			// the start index needs to be changed from one-base to zero-base
			start = context.offsetStart - 1;
			// need to include the last character too, so don't take off one here
			end = context.offsetEnd;
			
			// no point in highlighting the same text locations over and over
			// old way
//			var key:String = start + "_" + end;
//			if (!seen.hasOwnProperty(key) && (start >= 0) && (end > start) && (end <= searchTextInput.text.length)) {
//				seen[key] = true;
//				searchTextInput.highlightPortion(format, start, end, false);
//			}

			// new way - create links for terms
			key = start.toString();
			var array:Array;
			if (!seen.hasOwnProperty(key) && (start >= 0) && (end > start) && (end <= txt.length)) {
				array = [ annotation ];
				word = txt.substring(start, end);
				var space:int = word.indexOf(" ");
				if (space != -1) {
					word = word.substr(0, space);
				}
				seen[key] = array;
				htmlLinks[word] = array;
				terms[key] = word;
			} else if (seen.hasOwnProperty(key)) {
				array = (seen[key] as Array);
				array.push(annotation);
			} else {
				trace("Couldn't find: " + start + ", " + end + ", " + txt.length);
			}
		}
	}

	// add links for each 
	var html:String = ""; 
	
	// sort the indices lowest first
	var keys:Array = terms.keys;
	keys.sort(Array.NUMERIC);
	var last:int = 0;
	for each (key in keys) {
		word = String(terms[key]);
		start = int(key);
		if (start < last) {
			// overlapping words - skip
			continue;
		}
		end = start + word.length;
		if (start > last) {
			html = html + txt.substring(last, start);
		}
		html = html + "<a href=\"event:" + word + "\">" + word + "</a>";
		last = end; 
	}
	if (last < txt.length) {
		html = html + txt.substring(last);
	}
	if (html) {
		html = StringUtils.addLinkStyle(html, 0x70A3C8, true, true);
		annotateTextInput.htmlText = html;
		annotateTextInput.validateNow();
	} else if (annotateTextInput.htmlText) {
		annotateTextInput.text = "";
	}
	
	seen = null;
	terms = null;
	
	// remove the highlighting when the user changes the text
	annotateTextInput.addEventListener(Event.CHANGE, annotateTextChanged);
}

private function annotateTextChanged(event:Event):void {
	annotateTextInput.clearHighlight();
	annotateTextInput.removeEventListener(Event.CHANGE, annotateTextChanged);
	htmlLinks = null;
	// clear the htmlText
	if (annotateTextInput.htmlText) {
		var txt:String = annotateTextInput.text;
		annotateTextInput.text = "";
		annotateTextInput.text = txt;
	}
}

private function annotateTextInputLinkClicked(event:TextEvent):void {
	var txt:String = event.text;
	if (resultsBox.selectedIndex != 0) {
		resultsBox.selectedIndex = 0;
	}
	if (txt && htmlLinks && htmlLinks.hasOwnProperty(txt)) {
		// de-select any concepts?
		if (conceptsBox && conceptsBox.selectedItemsCount > 0) {
			conceptsBox.selectNone(true);
		}
		
		var array:Array = (htmlLinks[txt] as Array);
		//trace("There are " + array.length + " annotations for '" + txt + "'");
		annotationResults2.source = array;
		
		annotationResultsPanel.title = "Annotations for '" + txt + "'";
	}
}

private function  downloadResults(event:MouseEvent):void {
	var target:ResultFormatButton = (event.currentTarget as ResultFormatButton);
	var format:String = target.format;
	lastAnnotatorParams.format = format;
	restService.annotateTextInNewWindow(lastAnnotatorParams, "AnnotatorWindow_" + format);
}

private var moveTimeout:uint = 0;
private function annotateTextMouseMove(event:MouseEvent):void {
	 if (moveTimeout > 0) {
	 	clearTimeout(moveTimeout);
	 }
	 if (htmlLinks && (annotateTextInput.text.length > 0)) {
	 	moveTimeout = setTimeout(updateAnnotateTextToolTip, 500);
	 }
}

private function updateAnnotateTextToolTip():void {
	clearTimeout(moveTimeout);
	var url:String = annotateTextInput.mouseOverLinkURL;
	var tt:String = null;
	if (url && (url.length > 6) && htmlLinks) {
		var term:String = url.substr(6);
		if (htmlLinks.hasOwnProperty(term)) {
			var array:Array = (htmlLinks[term] as Array);
			tt = "Click to view the " + array.length + " annotation" + 
					(array.length == 1 ? "" : "s") + " for " + term;
		}
	}
	if (tt != annotateTextInput.toolTip) {
		// destroy the old one
		if (tt) {
			annotateTextInput.toolTip = null;
		}
		annotateTextInput.toolTip = tt;
	}
}

private function loadAnnotationStats(stats:Array):void {
	statsBox.visible = true;
	annotationStatsBox.removeAllChildren();
	stats.sortOn("name", Array.DESCENDING);
	for (var i:int = 0; i < stats.length; i++) {
		var stat:AnnotationStats = stats[i];
		var formItem:FormItem = new FormItem();
		// customize the labels to make them nicer
		var lbl:String = null; ///stat.name;
		if (StringUtils.contains(stat.name, "MGREP", true)) {
			lbl = "Direct annotations generated from term recognition on the given text (MGREP):";
		} else if (StringUtils.contains(stat.name, "MAPPING", true)) {
			lbl = "Expanded annotations generated from mappings (MAPPING):";
		} else if (StringUtils.contains(stat.name, "CLOSURE", true)) {
			lbl = "Expanded annotations generated from the is_a transitive closure (CLOSURE):";
		}
		if (lbl) {
			formItem.label = lbl;
			formItem.addChild(UIUtils.createLabel(stat.annotationCount.toString(10)));
			annotationStatsBox.addChild(formItem);
		} else {
			trace("Unexpected annoation stats: " + stat.name + " (" + stat.annotationCount + ")");
		}
	}
}

private function calculateFilteredAnnotationStats():void {
	var mgrep:uint = 0;
	var mapping:uint = 0;
	var isa:uint = 0;
	var direct:uint = 0;
	for each (var result:Annotation in annotationResults) {
		mgrep += result.mgrepContextCount;
		mapping += result.mappingContextCount;
		isa += result.isaContextCount;
		direct += result.directContextCount;
	}
	for (var i:int = 0; i < annotationStatsBox.numChildren; i++) {
		var formItem:FormItem = (annotationStatsBox.getChildAt(i) as FormItem);
		var str:String = formItem.label;
		var label:Label = (formItem.getChildAt(0) as Label);
		if (StringUtils.contains(str, "mgrep", true)) {
			label.text = mgrep.toString(10);
		} else if (StringUtils.contains(str, "mapping", true)) {
			label.text = mapping.toString(10);
		} else if (StringUtils.contains(str, "closure", true)) {
			label.text = isa.toString(10);
		} else {
			label.text = direct.toString(10);
		}
	}
}

private function loadOntologies(ontologies:Array):void {
	// sort the ontologies alphabetically (bug #1399)
	ontologies.sortOn("name", Array.CASEINSENSITIVE);
	ontologyResults.source = ontologies;
	ontologiesBox.selectAll();
	updateStatus(ontologyResults, ontologyResultsPanel);	 
}

private function conceptLabelFunction(item:Object):String {
	var label:String = (item as String);
	var key:String = (item as String).toLowerCase();
	if (conceptNameToAnnotations && conceptNameToAnnotations.hasOwnProperty(key)) {
		var annotations:Array = conceptNameToAnnotations[key];
		if (annotations.length > 0) {
			label = label + " (" + annotations.length + ")";
		}
	} 
	return label; 
}

private function conceptClicked(event:ItemsChangedEvent):void {
	if (conceptNameToAnnotations) {
		var annotations:Array = [];
		
		var selectedItems:Array = conceptsBox.selectedItems; //[ null /* breaks */]; 
		for each (var item:String in selectedItems) {
			var key:String = item.toLowerCase();
			if (conceptNameToAnnotations.hasOwnProperty(key)) {
				var moreAnnotations:Array = (conceptNameToAnnotations[key] as Array);
				annotations = annotations.concat(moreAnnotations);
			}
		}
		annotationResults2.source = annotations;
		annotationResultsPanel.title = "Annotations";
	}
}

private function loadTagCloud(annotations:Array):void {
	annotationResults.source = annotations;
	tagCloud.load(annotationResults);
}


private function ontologyClicked(event:ItemsChangedEvent):void {
	// update the filtered concepts tag cloud
	_selectedOntologiesMap = null;
	annotationResults.refresh();
	updateSelectedStatus(ontologiesBox, ontologyResultsPanel, ontologyResults.source.length);
	
	// also update the annotation statistics
	calculateFilteredAnnotationStats();
	
	// update the highlighting - the annotationResults will have the filtered annotations
	if (annotationResults.source.length > 0) {
		highlightAnnotateInputText(annotationResults);
	}	 
}

private function updateOntologies():void {
	ontologyResults.refresh();
	updateSelectedStatus(ontologiesBox, ontologyResultsPanel, ontologyResults.source.length);	 
	_selectedOntologiesMap = null;
	ontologiesBox.selectAll();
	annotationResults.refresh();
}

private function conceptsFilterFunction(annotation:Annotation):Boolean {
	if (annotation) {
		var map:Object = selectedOntologiesMap;
		if (map.hasOwnProperty(annotation.concept.ontologyID)) {
			return true;
		}
	}
	return false;
}

private function get selectedOntologiesMap():Object {
	if (_selectedOntologiesMap == null) {
		_selectedOntologiesMap = new Object();
		var ontologies:Array = ontologiesBox.selectedItems;
		for (var i:int = 0; i < ontologies.length; i++) {
			var ontology:Ontology = (ontologies[i] as Ontology);
			// make sure the ontology isn't filtered out
			if (ontologiesBox.isVisible(ontology)) {
				_selectedOntologiesMap[ontology.id] = ontology;
			}
		}
	}
	return _selectedOntologiesMap;
}

private function tagClicked(event:TagClickedEvent):void {
	if (detailsPanel.restService == null) {
		detailsPanel.restService = restService;
	}
	var annotation:Annotation = (event.item as Annotation);
	detailsPanel.annotation = annotation;
	detailsPanel.annotateText = true;
	// special case - load the contexts separately
	if (detailsPanel.annotateText) {
		var key:String = annotation.ontologyAndConceptID;
		if (conceptAnnotations && conceptAnnotations.hasOwnProperty(key)) {
			var annotationsForConcept:Array = (conceptAnnotations[key] as Array);
			detailsPanel.setAnnotationContexts(annotationsForConcept);
		} else {
			trace("Warning - couldn't get contexts for annotation: " + annotation);
		}
	}
	if (!detailsPanel.visible) {
		detailsPanel.visible = true;
	}
}


private function updateStatus(ac:ArrayCollection, panel:Panel):void {
	var filtered:int = ac.length;
	var total:int = ac.source.length
	if (total == 0) {
		panel.status = "No results";
		panel.setStyle("statusStyleName", "error");
	} else {
		panel.setStyle("statusStyleName", "panelStatus");
		if (filtered < total) {
			panel.status = "(" + filtered + "/" + total + ")"; 
		} else {
			panel.status = "(" + total + ")";
		}
	}
}

private function updateSelectedStatus(box:ButtonBox, panel:Panel, total:int):void {
	var selected:int = box.selectedItems.length;
	if (total == 0) {
		panel.status = "No results";
		panel.setStyle("statusStyleName", "error");
	} else {
		panel.setStyle("statusStyleName", "panelStatus");
		if (selected < total) {
			panel.status = "(" + selected + "/" + total + ")"; 
		} else {
			panel.status = "(" + total + ")";
		}
	}
}

//////////////////////////
// HELP FUNCTIONS
//////////////////////////

private function toggleHelp(event:Event):void {
	var animate:MoveResize = new MoveResize(helpPanel);
	animate.duration = 700;
	var bounds:Rectangle;
	if (!helpPanel.visible) {
		bounds = lastHelpPanelBounds;
		helpPanel.visible = true;
	} else {
		bounds = helpButton.getBounds(Application.application.stage);
		lastHelpPanelBounds = helpPanel.getBounds(Application.application.stage);
		animate.addEventListener(EffectEvent.EFFECT_END, resizeHelpPanelFinished);
	}
	animate.xTo = bounds.x;
	animate.yTo = bounds.y;
	animate.widthTo = bounds.width;
	animate.heightTo = bounds.height;
	animate.play();
}

private function resizeHelpPanelFinished(event:EffectEvent):void {
	event.currentTarget.removeEventListener(EffectEvent.EFFECT_END, resizeHelpPanelFinished);
	helpPanel.visible = false;
}

private function toggleResultsHelp(event:Event):void {
	var animate:MoveResize = new MoveResize(resultsHelpPanel);
	animate.duration = 700;
	var bounds:Rectangle;
	if (!resultsHelpPanel.visible) {
		bounds = lastResultsHelpPanelBounds;
		resultsHelpPanel.visible = true;
	} else {
		bounds = resultsHelpButton.getBounds(Application.application.stage);
		lastResultsHelpPanelBounds = resultsHelpPanel.getBounds(Application.application.stage);
		animate.addEventListener(EffectEvent.EFFECT_END, resizeResultsHelpPanelFinished);
	}
	animate.xTo = bounds.x;
	animate.yTo = bounds.y;
	animate.widthTo = bounds.width;
	animate.heightTo = bounds.height;
	animate.play();
}

private function resizeResultsHelpPanelFinished(event:EffectEvent):void {
	event.currentTarget.removeEventListener(EffectEvent.EFFECT_END, resizeResultsHelpPanelFinished);
	resultsHelpPanel.visible = false;
}

private function htmlLinkClicked(event:TextEvent):void {
	var url:String = event.text;
	if ((url != null) && (url.length > 4) && (url.toLowerCase().substr(0, 4) == "http")) {
		var helpText:HelpText = (event.currentTarget as HelpText);
		var newWindow:Boolean = true;
		// check for the CTRL key on the last mouse event
		if (helpText && helpText.lastTextMouseDownEvent) {
			newWindow = helpText.lastTextMouseDownEvent.ctrlKey;
		} 
		navigateToURL(new URLRequest(url), (newWindow ? "_blank" : null));
	}
}

