// ActionScript file for OBRSearchByConcept.mxml
import events.AnnotationLinkEvent;
import events.ConceptLinkEvent;
import events.OBSEvent;

import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.ui.Keyboard;

import flex.utils.ArrayUtils;
import flex.utils.Map;
import flex.utils.Utils;
import flex.utils.ui.ButtonBox;
import flex.utils.ui.TextHighlighter;
import flex.utils.ui.events.ItemsChangedEvent;
import flex.utils.ui.renderers.DataGridItemHighlightRenderer;

import model.Annotation;
import model.Concept;
import model.GroupedAnnotation;
import model.Ontology;
import model.Resource;

import mx.collections.ArrayCollection;
import mx.containers.Panel;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.events.CollectionEvent;
import mx.events.DragEvent;
import mx.events.FlexEvent;
import mx.managers.CursorManager;
import mx.managers.DragManager;

import org.ncbo.uvic.flex.NCBORestService;
import org.ncbo.uvic.flex.events.NCBOConceptEvent;
import org.ncbo.uvic.flex.events.NCBOOntologyEvent;
import org.ncbo.uvic.flex.events.NCBOSearchEvent;
import org.ncbo.uvic.flex.model.NCBOConcept;
import org.ncbo.uvic.flex.model.NCBOOntology;
import org.ncbo.uvic.flex.model.NCBOSearchResultConcept;
import org.ncbo.uvic.flex.model.NCBOSearchResultOntology;
import org.ncbo.uvic.flex.search.SearchParams;
import org.ncbo.uvic.flex.ui.DebugPanel;
import org.ncbo.uvic.flex.util.NavigateToBioPortal;

import service.OBSRestService;
import service.ResourceIndexParameters;


private static const ALL_ONTOLOGIES:Ontology = new Ontology("", "All Ontologies");

private var bpService:NCBORestService;
private var obService:OBSRestService;

[Bindable]
private var ontologies:ArrayCollection = new ArrayCollection( [ "Loading..." ]);
private var ontologiesLoaded:Boolean = false;

[Bindable]
private var resources:ArrayCollection = new ArrayCollection([ new Resource("", "Loading...") ]);

[Bindable]
private var conceptResults:ArrayCollection = new ArrayCollection();

[Bindable]
private var selectedConcepts:ArrayCollection = new ArrayCollection();

[Bindable]
private var annotationResults:ArrayCollection = new ArrayCollection();

[Bindable]
private var annotationConcepts:ArrayCollection = new ArrayCollection();

[Bindable]
private var annotationResources:ArrayCollection = new ArrayCollection();

private var searchParams:ResourceIndexParameters = new ResourceIndexParameters();

private var params:FlexParams;

private var conceptAnnotationsMap:Object;


private function init(event:FlexEvent):void {
	params = new FlexParams();
	NavigateToBioPortal.baseURL = params.redirectURL;
	
	resultsBox.visible = false;

	bpService = new NCBORestService(NCBORestService.APIKEY_OBS, NCBORestService.APP_ID_OBS, params.server, errorHandler, OBSRestService.EMAIL);
	//bpService.getNCBOOntologies(ontologiesLoadedHandler);
	
	obService = new OBSRestService(OBSRestService.DEFAULT_APIKEY, OBSRestService.APP_ID, params.server);
	obService.getResourceOntologies(ontologiesLoadedHandler);
	obService.getResources(resourcesLoadedHandler);
	
	
	if ((params.search != null) && (params.search.length > 0)) {
		// run an initial search
		var onts:Array = [];
		if ((params.ontology != null) && (params.ontology.length > 0)) {
			var ids:Array = params.ontology.split(",");
			for (var i:int = 0; i < ids.length; i++) {
				var ontology:Ontology = new Ontology("", "", "", 0, ids[i]);
				onts.push(ontology);
			}
		}
		conceptChooser.text = params.search;
		this.callLater(bioPortalSearch, [  params.search, onts, true ]); 
		
		// TODO - if there are exact matches, then we want to run the annotation search too!
		
	} else if ((params.concept != null) && (params.concept.length > 0) && 
			   (params.ontology != null) && (params.ontology.length > 0)) {
		
		var ontIDs:Array = params.ontology.split(",");
		var conIDs:Array = params.concept.split(",");
		if ((ontIDs.length == 1) && (conIDs.length == 1)) {
			var ontologyID:String = ontIDs[0];
			var conceptID:String = conIDs[0];
			// load the ontology first
			bpService.getNCBOOntology(ontologyID, function(event:NCBOOntologyEvent):void {
				var ontology:NCBOOntology = event.ontology;
				if (ontology != null) {
					// now load the concept
					bpService.getConceptByID(ontology.id, conceptID, function(event:NCBOConceptEvent):void {
						initialConceptLoaded(event.concept, ontology);
					});
				} else {
					trace("Error getting ontology");
					errorHandler(event.error);
					initialConceptLoaded(null, ontology);
				}
			}, true /* need to load the display label */);
		} else {
			errorHandler(new Error("Expecting one term ID and one ontology ID"));
		}
	}
}

private function created(event:FlexEvent):void {
	// Add CTRL-T support for opening new tab
	Utils.addOpenNewTabListener();
	
	conceptNameColumn.itemRenderer = new DataGridItemHighlightRenderer(new TextHighlighter(null, getSearchText));
	
	selectedConceptsGrid.addEventListener(ConceptLinkEvent.REMOVE_LINK_CLICKED, removeSelectedConcept);

	elementsDataGrid.addEventListener(AnnotationLinkEvent.ELEMENT_LINK_CLICKED, viewAnnotationDetails);
	elementsDataGrid.addEventListener(AnnotationLinkEvent.CONCEPT_LINK_CLICKED, viewSelectedConcept);
	elementsDataGrid.addEventListener(AnnotationLinkEvent.ONTOLOGY_LINK_CLICKED, viewSelectedOntology);
	
	annotationResults.filterFunction = annotationsFilterFunction;
	annotationResults.addEventListener(CollectionEvent.COLLECTION_CHANGE, function(event:CollectionEvent):void {
		updateStatus(annotationResults, elementsPanel);	
	});

	// we also want to load the ontologies, this is needed for when we get annotations
	obService.getAnnotatorOntologies(function(event:OBSEvent):void {
		//trace("Loaded annotator ontologies (" + event.items.length + ") in " + event.time);
	});
	
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
	var extraCalls:Array = obService.restCalls;
	var vers:String = (parameters.hasOwnProperty("v") ? parameters["v"] : "?");
	var dp:DebugPanel = DebugPanel.showDebugPanel(par, vers, bpService, extraCalls);
	dp.addRestURL("Annotator Base URL", obService.annotatorBaseURL);
	dp.addRestURL("Resources Base URL", obService.resourcesBaseURL);
	//dp.addRestURL("Ontology Recommended Base URL", restService.recommendedBaseURL);
}

private function errorHandler(error:Error):void {
	trace(error);
	errorMessage = error.message; 
}

private function set errorMessage(msg:String):void {
	errorLabel.text = msg;
	errorLabel.height = (msg ? NaN : 0);
}

private function initialConceptLoaded(concept:NCBOConcept, ontology:NCBOOntology):void {
	selectedConcepts.removeAll();
	if (concept != null) {
		// have to convert from NCBOConcept to NCBOSearchResultConcept objects
		var searchOntology:NCBOSearchResultOntology = new NCBOSearchResultOntology(ontology.id, ontology.ontologyID, ontology.name, 1);
		var searchConcept:NCBOSearchResultConcept = new NCBOSearchResultConcept(concept.id, concept.name, "", "", searchOntology);
		// set the source for both the search results and the selected concepts datagrids
		selectedConcepts.source = [ searchConcept ];
		setConceptResults([ searchConcept ]);
		
		// also set the search text
		conceptChooser.text = concept.name;
		if (ontologiesLoaded) {
			selectOntologyByID(ontology.id);
		}
	}
}

private function ontologiesLoadedHandler(event:OBSEvent/*NCBOOntologiesEvent*/):void {
	trace("Resource ontologies loaded in " + event.totalTime);
	ontologiesCombo.enabled = true;
	if (event.isError) {
		//errorHandler(event.error);
		trace("Error loading resource ontologies: " + event.errorMessage);
		errorMessage = event.errorMessage;
		ontologies.source = [ event.errorMessage, "Retry" ];
		ontologies.refresh();
		ontologiesCombo.styleName = "error";
		findButton.enabled = false;
	} else {
		//trace("Loaded " + event.items.length + " resource ontologies in " + event.serverTime + "ms");
		ontologiesCombo.styleName = null;
		var source:Array = event.items.slice();
		source.sortOn("name", Array.CASEINSENSITIVE);
		source.unshift(ALL_ONTOLOGIES);
		ontologies.source = source;
		ontologies.refresh();
		ontologiesLoaded = true;
		findButton.enabled = true;
		if ((params.ontology != null) && (params.ontology.length > 0)) {
			var id:String = params.ontology.split(",")[0];
			selectOntologyByID(id);
		} else {
			ontologiesCombo.selectedIndex = 0;
		}
	}
}

private function ontologiesSelectionChange(event:Event):void {
	if (ontologiesCombo.selectedItem == "Retry") {
		obService.getResourceOntologies(ontologiesLoadedHandler);
		ontologiesCombo.enabled = false;
	}
}

private function selectOntologyByID(id:String):void {
	var index:int = 0;
	if ((id != null) && (id.length > 0)) {
		for (var i:int = 0; i < ontologies.length; i++) {
			var ont:Ontology = (ontologies[i] as Ontology);
			if ((ont.ontologyID == id) || (ont.ontologyVersionID == id)) {
				index = i;
				break;
			} 
		} 
	}
	ontologiesCombo.selectedIndex = index;
}

private function resourcesLoadedHandler(event:OBSEvent):void {
	resourcesPopUpButton.enabled = !event.isError;
	if (event.isError) {
		var msg:String = event.errorMessage;
		if (msg == "Request timed out") {
			msg = "Resources are not available at this time";
		}
		//resources.source = [ new Resource("", msg) ];
		resourcesPopUpButton.label = msg;
		resourcesPopUpButton.styleName = "error";
	} else {
		var source:Array = event.items.slice();
		source.sortOn("name", Array.CASEINSENSITIVE);
		resourcesPopUpButton.styleName = null;
		resources.source = source;
		resourcesList.selectedIndex = 0;
	}
}

// needs to be a function so that it can be used in the highlighter
private function getSearchText():String {
	return conceptChooser.text;
}

private function get unionSearchResults():Boolean {
	return unionRadioButton.selected;
}

private function conceptChooserKeyDownHandler(event:KeyboardEvent):void {
	if (event.keyCode == Keyboard.ENTER) {
		findConcepts(event);
	}
}

private function findConcepts(event:Event = null):void {
	errorMessage = "";

	conceptResults.removeAll();
	var selectedOntology:Ontology = (ontologiesCombo.selectedItem as Ontology);
	var onts:Array = null;
	if (selectedOntology) {
		onts = [ selectedOntology ]; 
	}
	// first try an exact match search
	bioPortalSearch(getSearchText(), onts, true);
}

private function bioPortalSearch(text:String, ontologies:Array = null, exactMatch:Boolean = false, pageSize:int = -1):void {
	var searchParams:SearchParams = new SearchParams(text);
	if ((ontologies != null) && (ontologies.length > 0)) {
		for (var i:int = 0; i < ontologies.length; i++) {
			if (ontologies[i] != ALL_ONTOLOGIES) {
				searchParams.addOntology(ontologies[i]);
			}
		}
	}
	searchParams.exactMatch = exactMatch;
	if (pageSize > 0) {
		searchParams.pageSize = pageSize;
	}
	if (searchParams.isValid) {
		CursorManager.setBusyCursor();
		bpService.search(searchParams, findConceptsResultsHandler, false);
	} else if (conceptChooser) {
		conceptChooser.setFocus();
	}
}

private function findConceptsResultsHandler(event:NCBOSearchEvent):void {
	CursorManager.removeBusyCursor();
	if (event.isError) {
		errorHandler(event.error);
	} else {
		var allConcepts:Array = event.concepts;
		// make sure that the concepts are in ontologies that are indexed in OBS!
		// Bug #1766
		var validOntologies:Map = ArrayUtils.toMap(ontologies.source, "ontologyID");
		var concepts:Array = allConcepts.filter(function(concept:NCBOSearchResultConcept, i:int, a:Array):Boolean {
			if (concept && concept.ontologyID) {
				return validOntologies.containsKey(concept.ontologyID);
			}
			return false;
		});
		
		if (concepts.length > 0) {
			setConceptResults(concepts, false);
		} else {
			if (event.searchParams.exactMatch) {
				// re-run the search, using contains, and limit to 5 or 10 concepts?
				event.searchParams.exactMatch = false;
				event.pageSize = 10;	// Is 10 a good number?
				//trace("Re-running search, using contains this time");
				bpService.search(event.searchParams, findConceptsResultsHandler, false);
			} else {
				// show no results found
				concepts.push(new NCBOSearchResultConcept("", "No results found"));
				setConceptResults(concepts, true);
			}
		}
	}
}

private function setConceptResults(concepts:Array, error:Boolean = false):void {
	conceptResults.source = concepts;
	conceptResultsList.enabled = !error;			
	conceptResultsList.selectedIndex = (error ? -1 : 0);
}

private function addConceptsClicked(event:Event):void {
	var selectedItems:Array = conceptResultsList.selectedItems;
	for each (var item:Object in selectedItems) {
		if (!selectedConcepts.contains(item)) {
			selectedConcepts.addItem(item);
		}
	}
	selectedConcepts.refresh();
} 

private function resourcesSelected(event:ItemsChangedEvent):void {
	//var resourcesList:ButtonBox = (resourcesPopUpButton.popUp as ButtonBox);
	var count:int = resourcesList.selectedItemsCount;
	resourcesPopUpButton.label = "Resources (" + count + ")";
	if (count > 0) {
		var sel:Array = resourcesList.selectedItems;
		var abbrevs:String = ArrayUtils.join(sel, ", ", "id", 100);
		resourcesPopUpButton.label += ":\n" + abbrevs;
	}
	searchButton.enabled = (count > 0) && (selectedConcepts.length > 0);
	if (count == 0) {
		resourcesPopUpButton.styleName = "error";
	} else if (resourcesPopUpButton.styleName) {
		resourcesPopUpButton.styleName = null;
	}
}

private function andOrChanged(event:Event):void {
	// repaint the items in the grid
	selectedConcepts.refresh();
}

private function conceptDragOver(event:DragEvent):void {
	var containsAll:Boolean = true;
	var selItems:Array = conceptResultsList.selectedItems;
	for each (var item:Object in selItems) {
		if (!selectedConcepts.contains(item)) {
			containsAll = false;
			break;
		}
	}
	if (containsAll) {
		event.action = DragManager.NONE;
		DragManager.showFeedback(DragManager.NONE);
	}
}

private function conceptDragDrop(event:DragEvent):void {
	addConceptsClicked(event);
	// don't bother, we already added the concepts above
	event.action = DragManager.NONE;
}

private function andOrColumnLabelFunction(item:Object, column:DataGridColumn = null):String { 
	var index:int = selectedConcepts.getItemIndex(item);
	return (index > 0 ? (unionSearchResults ? "OR" : "AND") : "");
}


private function viewSelectedOntology(event:ConceptLinkEvent):void {
	var ontologyID:String = event.ontologyVersionID;
	var window:String = (event.ctrlKey ? null : NavigateToBioPortal.SAME_WINDOW);
	NavigateToBioPortal.viewOntologyMetaDataByID(ontologyID, window);
}

private function viewSelectedConcept(event:ConceptLinkEvent):void {
	var ontologyID:String = event.ontologyVersionID;
	var window:String = (event.ctrlKey ? null : NavigateToBioPortal.SAME_WINDOW);
	NavigateToBioPortal.viewConcept(event.concept, ontologyID, window);
}

private function removeSelectedConcept(event:ConceptLinkEvent):void {
	var index:int = selectedConcepts.getItemIndex(event.concept);
	if (index != -1) {
		selectedConcepts.removeItemAt(index);
	}
}

private function searchButtonClicked(event:MouseEvent = null):void {
	errorMessage = "";
	
	if (validateForm()) {
		searchButton.enabled = false;
		// clear existing results
		resultsBox.visible = false;
		annotationConcepts.removeAll();
		conceptAnnotationsMap = new Object();
		annotationResources.removeAll();
		annotationResults.removeAll();
		
		var selectedResources:Array = resourcesList.selectedItems;
		var callback:Function = annotationsForConceptsHandler;
		
		if (selectedResources.length >= 1) {
			// Ther service now supports a comma-separated list of resource ids
			searchParams.resourceids = ArrayUtils.arrayToString(selectedResources, ",", -1, "id");
			progress.label = "Searching resources...";

//			// we have to make one call for every resource selected (OLD WAY)
//			// this is done in sequence
//			if (selectedResources.length > 1) {
//				var annotations:Array = [];
//				var currentIndex:int = 0;
//				callback = function(event:OBSEvent):void {
//					ArrayUtils.combine(annotations, event.items);
//					currentIndex++;
//					if (currentIndex < selectedResources.length) {
//						resource = (selectedResources[currentIndex] as Resource);
//						searchParams.resourceid = resource.id;
//						progress.label = "Searching " + resource.id + "...";
//						obService.getAnnotationsForConcepts(callback, searchParams);
//					} else {
//						progress.label = "Finished";
//						annotationsForConceptsHandler(new OBSEvent(OBSEvent.ANNOTATIONS_FOR_CONCEPTS, annotations));
//					}
//				};
//			}
			progress.visible = true;
			obService.getAnnotationsForConcepts(callback, searchParams);
		}
	}
}

private function validateForm():Boolean {
	var conceptIDs:String = "";
	for each (var concept:NCBOSearchResultConcept in selectedConcepts) {
		if (conceptIDs.length > 0) {
			conceptIDs += ",";
		}
		// use the ontology ID (not version ID)
		conceptIDs += concept.ontology.ontologyID + "/" + concept.id;
	}

	searchParams.conceptids = conceptIDs;
	searchParams.isVirtualOntologyId = true;	// see above - using virtual id
	// not needed anymore?
	searchParams.ontologiesToKeepInResult = ""; //ArrayUtils.arrayToString(selectedConcepts.source, ",", -1, "ontologyID");
	searchParams.elementid = "";
	
	searchParams.mode = (unionRadioButton.selected ? ResourceIndexParameters.MODE_UNION : ResourceIndexParameters.MODE_INTERSECTION);
	searchParams.limit = Math.max(searchParams.offset, maxResultsSlider.value);
	searchParams.resourceids = "";	// this is set later 
	return searchParams.isValid();
}

private function annotationsForConceptsHandler(event:OBSEvent):void {
	resultsBox.visible = true;
	progress.visible = false;
	searchButton.enabled = true;
	if (event.isError) {
		errorHandler(new Error(event.errorMessage));
	} else {
		var annotations:Array = event.items;
		
		// load the concepts into the ButtonBox first
		loadAnnotationConcepts(annotations);
		
		// load the resources into the ButtonBox next 
		loadAnnotationResources(annotations);

		// Combine any duplicate resource elements
		// this will happen when AND is used, the score will be the sum of the elements
		if ((searchParams.mode == ResourceIndexParameters.MODE_INTERSECTION) &&
			(searchParams.conceptids.length > 1)) {
			annotations = combineSameElements(annotations);
		}
		
		// sort by score, highest first
		annotations.sortOn("score", Array.NUMERIC | Array.DESCENDING);
		
		//trace("Got " + annotations.length + " annotations");
		annotationResults.source = annotations;
	}
}

/**
 * Combines annotations into GroupedAnnotations that have the same
 * elementID and resourceID.
 */
private function combineSameElements(annotations:Array):Array {
	var combined:Map = new Map();
	for each (var annotation:Annotation in annotations) {
		var key:String = annotation.elementID + "_" + annotation.resourceID;
		if (!combined.containsKey(key)) {
			combined.put(key, annotation);
		} else {
			var value:Object = combined.getValue(key);
			if (value is GroupedAnnotation) {
				(value as GroupedAnnotation).addAnnotation(annotation);
			} else {
				var grouped:GroupedAnnotation = new GroupedAnnotation([ value, annotation ]);
				combined.put(key, grouped);
			}
		}
	}
	return combined.values;
}

private function loadAnnotationConcepts(annotations:Array):void {
	annotationConcepts.removeAll();
	var concepts:Array = [];
	var seen:Object = new Object();
	conceptAnnotationsMap = new Object();
	var fullID:String;
	// first add all the annotated concepts (and count the annotations)
	for each (var annotation:Annotation in annotations) {
		var concept:Concept = annotation.concept;
		if (concept != null) {
			fullID = concept.ontologyID + "/" + concept.id; 
			if (!seen.hasOwnProperty(fullID)) {
				seen[fullID] = concept;
				conceptAnnotationsMap[fullID] = [ annotation ];
				concepts.push(concept);
				concept.numAnnotations = 1;
			} else {
				// add one to the annotation count
				var c:Concept = (seen[fullID] as Concept); 
				c.numAnnotations = c.numAnnotations + 1;
				var contexts:Array = (conceptAnnotationsMap[fullID] as Array);
				contexts.push(annotation);
			}
		}
	}
	// now add the concepts that have no annotations
	if (selectedConcepts.length > concepts.length) {
		for each (var bpConcept:NCBOSearchResultConcept in selectedConcepts) {
			// TODO - this won't work because of the virtual ids - the ontology version ids will be different
			fullID = bpConcept.ontologyVersionID + "/" + bpConcept.id;
			if (!seen.hasOwnProperty(fullID)) {
				var obrConcept:Concept = new Concept(bpConcept.id, bpConcept.name, false, bpConcept.ontologyVersionID);
				obrConcept.numAnnotations = 0;
				seen[fullID] = obrConcept;
				concepts.push(obrConcept);
			}
		}
	}
	
	annotationConcepts.source = concepts;
	updateStatus(annotationConcepts, annotationConceptResultsPanel);
	annotationConceptsBox.selectAll();
}


private function loadAnnotationResources(annotations:Array):void {
	annotationResources.removeAll();
	var resources:Array = [];
	var seen:Object = new Object();
	// first add all the annotated concepts (and count the annotations)
	for each (var annotation:Annotation in annotations) {
		var resource:Resource = annotation.resource;
		if (resource != null) {
			if (!seen.hasOwnProperty(resource.id)) {
				seen[resource.id] = resource;
				resource.numAnnotations = 1;
				resources.push(resource);
			} else {
				// add one to the annotation count
				var r:Resource = (seen[resource.id] as Resource); 
				r.numAnnotations = r.numAnnotations + 1;
			}
		}
	}
	// now add the resources that have no annotations
	//var resourcesList:ButtonBox = (resourcesPopUpButton.popUp as ButtonBox);
	var selectedResources:Array = resourcesList.selectedItems;
	for each (var res:Resource in selectedResources) {
		if (!seen.hasOwnProperty(res.id)) {
			res.numAnnotations = 0;
			seen[res.id] = res;
			resources.push(res);
		}
	}
	
	annotationResources.source = resources;
	updateStatus(annotationResources, resourcesResultsPanel);
	resourceResultsBox.selectAll();
}

private function annotationConceptsChanged(event:ItemsChangedEvent):void {
	annotationResults.refresh();
	if (event.currentTarget == annotationConceptsBox) {
		updateSelectedStatus(annotationConceptsBox, annotationConceptResultsPanel, annotationConcepts.source.length);
	}
	if (event.currentTarget == resourceResultsBox) {
		updateSelectedStatus(resourceResultsBox, resourcesResultsPanel, annotationResources.source.length);
	}
}

private function annotationsFilterFunction(annotation:Annotation):Boolean {
	var pass:Boolean = true;
	
	// first check if the annotation concept is selected in the checkbox list
	if (annotation is GroupedAnnotation) {
		// for grouped annotations - we update the score based on which concepts are selected
		var grouped:GroupedAnnotation = (annotation as GroupedAnnotation);
		var allSelected:Boolean = annotationConceptsBox.allSelected();
		pass = grouped.filterAnnotationsByConcept(annotationConceptsBox.selectedItems, allSelected);
	} else {
		pass = annotationConceptsBox.isSelected(annotation.concept);
	}
	
	// next check if the resource is selected
	if (pass) {
		pass = resourceResultsBox.isSelected(annotation.resource);
	}
	
	// now check the filterbox text
	if (pass) {
		pass = elementsFilterBox.filterFunction(annotation);
	}
	return pass;
}

private function viewAnnotationDetails(event:AnnotationLinkEvent):void {
	if (detailsPanel.restService == null) {
		detailsPanel.restService = obService;
	}
	var annotation:Annotation = event.annotation;
	detailsPanel.annotation = annotation;
	if (conceptAnnotationsMap.hasOwnProperty(annotation.conceptID)) {
		var annotations:Array = (conceptAnnotationsMap[annotation.conceptID] as Array);
		detailsPanel.setAnnotationContexts(annotations);
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

