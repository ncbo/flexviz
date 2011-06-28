// ActionScript file for OBARecommender.mxml

import events.OBSEvent;
import events.TagClickedEvent;

import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TextEvent;
import flash.net.URLRequest;
import flash.net.navigateToURL;

import flex.utils.ui.EscapeWindow;

import model.Ontology;

import mx.collections.ArrayCollection;
import mx.core.Application;
import mx.events.CloseEvent;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.utils.StringUtil;

import org.ncbo.uvic.flex.util.NavigateToBioPortal;

import service.OBSRestService;
import service.RecommenderParameters;

import util.HelpText;

private static const APIKEY_RECOMMENDER:String= "5ced8872-df64-4887-a38e-7c8e76395c80";


private var obService:OBSRestService;

private var ontologyResults:ArrayCollection = new ArrayCollection();

private var clickedOntology:Ontology;

private function created(event:FlexEvent):void {
	obService = new OBSRestService(APIKEY_RECOMMENDER);
	
	detailsWindow.parent.removeChild(detailsWindow);
	
	searchInput.setFocus();
	Application.application.defaultButton = searchButton;
}

private function resetForm(event:Event):void {
	hideDetailsWindow();
	errorLabel.text = "";
	searchButton.enabled = true;
	searchPanel.status = "";
	tagCloudPanel.status = "";
	tagCloudPanel.visible = false;
	ontologyResults.removeAll();
	clickedOntology = null;
	corpusRadioButton.selected = true;
	normalizeCheckBox.selected = false;
	allRadioButton.selected = true;
	searchInput.text = "";
	searchInput.setFocus();
}

private function searchClicked(event:Event):void {
	var txt:String = StringUtil.trim(searchInput.text);
	if (txt.length > 0) {
		searchButton.enabled = false;
		hideDetailsWindow();
		clickedOntology = null;
		var params:RecommenderParameters = new RecommenderParameters(txt);
		params.repository = (allRadioButton.selected ? RecommenderParameters.REPOSITORY_ALL :  
								(umlsRadioButton.selected ? RecommenderParameters.REPOSITORY_UMLS : 
									RecommenderParameters.REPOSITORY_NCBO));
		params.method = (corpusRadioButton.selected ? RecommenderParameters.METHOD_CORPUS : 
							RecommenderParameters.METHOD_KEYWORDS);
		params.output = (normalizeCheckBox.selected ? RecommenderParameters.OUTPUT_SCORE_NORM : 
							RecommenderParameters.OUTPUT_SCORE); 
		obService.getOntologyRecommendations(searchResultHandler, params);
	} else {
		searchInput.setFocus();
	}
}

private function searchResultHandler(event:OBSEvent):void {
	searchPanel.status = "Search time: " + event.time;
	if (event.isError) {
		errorLabel.text = event.errorMessage;
	} else {
		errorLabel.text = "";
		ontologyResults.source = event.items;
		tagCloud.normalized = normalizeCheckBox.selected;
		tagCloud.load(ontologyResults);
		tagCloudPanel.visible = true;
		tagCloudPanel.status = "(" + ontologyResults.source.length + ")";
	}
	searchButton.enabled = true;
}

private function tagClicked(event:TagClickedEvent):void {
	if (event.item is Ontology) {
		clickedOntology = (event.item as Ontology);
		
		detailsWindow.title = clickedOntology.name;
		detailsOntologyNameLink.label = clickedOntology.nameAndID;
		detailsOntologyNameLink.enabled = clickedOntology.isBioPortal;
		detailsOntologyNameLink.setStyle("textDecoration", (clickedOntology.isBioPortal ? "underline" : "none"));
		detailsScoreLabel.text = clickedOntology.score.toString(10);
		detailsNormalizedLabel.text = clickedOntology.normalizedScore.toFixed(7);
		detailsOverlapLabel.text = clickedOntology.overlap.toFixed(4);
		detailsNumAnnotatingConceptsLabel.text = clickedOntology.numAnnotatingConcepts.toString(10);
		
		if (!detailsWindow.visible) {
			detailsWindow.visible = true;
		}
		if (detailsWindow.parent == null) {
			PopUpManager.addPopUp(detailsWindow, DisplayObject(Application.application));
			PopUpManager.centerPopUp(detailsWindow);
		}
//		if (ontology.isBioPortal) {
//		} else {
//			Alert.show("UMLS ontologies are not stored in BioPortal at this time.", "Error");
//		}
	}
}

private function hideDetailsWindow(event:CloseEvent = null):void {
	if (detailsWindow.parent != null) {
		PopUpManager.removePopUp(detailsWindow);
	}
}

private function ontologyLinkClicked(event:MouseEvent):void {
	if (clickedOntology) {
		var window:String = (event.ctrlKey ? null : NavigateToBioPortal.SAME_WINDOW);
		NavigateToBioPortal.viewOntologyMetaData(clickedOntology, window);
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

private var isCtrl:Boolean = false;
private var isEnter:Boolean = false;
private function searchText_KeyDown(event:KeyboardEvent):void {
	isEnter = (event.keyCode == Keyboard.ENTER);
	isCtrl = event.ctrlKey;
}

private function searchText_TextInput(event:TextEvent):void {
	if (isEnter && isCtrl) {
		searchClicked(event);
		event.preventDefault();
	}
}
