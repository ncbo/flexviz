// ActionScript file for OntologyFilterBox.mxml
import flash.events.ContextMenuEvent;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.ui.ContextMenu;

import flex.utils.ui.TextHighlighter;
import flex.utils.ui.events.ItemsChangedEvent;

import mx.collections.ArrayCollection;
import mx.collections.Sort;
import mx.collections.SortField;
import mx.controls.listClasses.IListItemRenderer;
import mx.core.UIComponent;
import mx.effects.Resize;
import mx.events.EffectEvent;
import mx.events.FlexEvent;
import mx.events.ResizeEvent;

import org.ncbo.uvic.flex.NCBORestService;
import org.ncbo.uvic.flex.doi.DegreeOfInterestService;
import org.ncbo.uvic.flex.events.NCBOCategoriesEvent;
import org.ncbo.uvic.flex.events.NCBOGroupsEvent;
import org.ncbo.uvic.flex.events.NCBOOntologiesEvent;
import org.ncbo.uvic.flex.model.IOntology;
import org.ncbo.uvic.flex.model.NCBOCategory;
import org.ncbo.uvic.flex.model.NCBOOntology;
import org.ncbo.uvic.flex.model.NCBOOntologyGroup;
import ui.DOIPopUp;
import renderers.OntologyCheckBoxRenderer;
import org.ncbo.uvic.flex.util.NavigateToBioPortal;

private static const ALL_CATEGORIES:NCBOCategory = new NCBOCategory("", "All Categories");
private static const ALL_GROUPS:NCBOOntologyGroup = new NCBOOntologyGroup("", "All Groups");
//private static const ALL_ONTOLOGIES:NCBOOntology = new NCBOOntology("", "", "All Ontologies");
private static const DOI_ONTOLOGIES:String = "searchOntologies";

[Embed("/assets/black_arrow_down.png")] 
public static const ICON_DOWN:Class;
[Embed("/assets/black_arrow_up.png")] 
public static const ICON_UP:Class;


private var _service:NCBORestService;
private var serviceChanged:Boolean = false;

private const categories:ArrayCollection = new ArrayCollection();
private var selectedCategory:NCBOCategory = ALL_CATEGORIES;
private var _showCategories:Boolean = true;
private var showCategoriesChanged:Boolean = false;

private const groups:ArrayCollection = new ArrayCollection();
private var selectedGroup:NCBOOntologyGroup = ALL_GROUPS;
private var _showGroups:Boolean = true;
private var showGroupsChanged:Boolean = false;

private var _showFilterBox:Boolean = true;
private var showFilterBoxChanged:Boolean = false;

private var _showDOI:Boolean = false;

[Bindable]
[Inspectable(category="Styles")]
public var ontologiesBoxVerticalScrollBarStyleName:String = null;

private const ontologies:ArrayCollection = new ArrayCollection();
private var _initiallySelectedOntologyIDs:Array = null;
private const ontologiesTextHighlighter:TextHighlighter = new TextHighlighter();
private var _ontologiesLoaded:Boolean = false;

private function created(event:FlexEvent):void {
	initializeOntologies();
}

[Bindable("serviceChanged")]
[Inspectable(category="Common")]
public function get service():NCBORestService {
	return _service;
}

public function set service(value:NCBORestService):void {
	if (value != _service) {
		_service = value;
		serviceChanged = true;
		invalidateProperties();
		dispatchEvent(new Event("serviceChanged"));
	}
}

private function topOntologiesBoxResized(event:ResizeEvent):void {
	var comboWidth:int = Math.min(400, width - 76)
	categoriesCombo.width = comboWidth;
	groupsCombo.width = comboWidth;
	groupsCombo.dropdownWidth = Math.max(comboWidth, 375);
}

private function toggleFilterFields(event:MouseEvent):void {
	var resize:Resize = new Resize(filterForm);
	if (filterForm.height > 0) {
		resize.heightTo = 0;
	} else {
		resize.heightTo = filterForm.measuredHeight;
		filterForm.visible = true;
	}
	resize.addEventListener(EffectEvent.EFFECT_END, function(event:EffectEvent):void {
		resize.removeEventListener(EffectEvent.EFFECT_END, arguments.callee);
		if (resize.heightTo == 0) {
			filterForm.visible = false;
		}
		hideFilterFormButton.enabled = true;
	});
	resize.duration = 500;
	resize.play();
	hideFilterFormButton.enabled = false;
}

override protected function commitProperties():void {
	super.commitProperties();
	
	if (serviceChanged) {
		serviceChanged = false;
		if (service) {
			categories.source = [ new NCBOCategory("", "Loading...") ];
			categoriesCombo.selectedIndex = 0;
			groups.source = [ new NCBOOntologyGroup("", "Loading...") ];
			groupsCombo.selectedIndex = 0;
			ontologies.source = [ new NCBOOntology("", "", "Loading...") ];
			cursorManager.setBusyCursor();
			service.getOntologyCategories(categoriesLoadedHandler);
			service.getOntologyGroups(groupsLoadedHandler);
			service.getNCBOOntologies(ontologiesLoadedHandler);
		}	
	}
	if (showCategoriesChanged) {
		showCategoriesChanged = false;
		categoriesFormItem.visible = showCategories;
		categoriesFormItem.height = (showCategories ? NaN : 0);
	}
	if (showGroupsChanged) {
		showGroupsChanged = false;
		groupsFormItem.visible = showGroups;
		groupsFormItem.height = (showGroups ? NaN : 0);
	}
	if (showFilterBoxChanged) {
		showFilterBoxChanged = false;
		filterFormItem.visible = showFilterBox;
		filterFormItem.height = (showFilterBox ? NaN : 0);
	}
}

public function clearFilters():void {
	if (filterBox.text.length > 0) {
		filterBox.text = "";
	}
	if (selectedCategory != ALL_CATEGORIES) {
		categoriesCombo.selectedItem = ALL_CATEGORIES;
		categoryChanged(null);
	}
	if (selectedGroup != ALL_GROUPS) {
		groupsCombo.selectedItem = ALL_GROUPS;
		groupChanged(null);
	}
}

///////////////
// CATEGORIES
///////////////

public function get showCategories():Boolean {
	return _showCategories;
}

[Bindable("showCategoriesChanged")]
[Inspectable(category="Common", defaultValue="true")]
public function set showCategories(value:Boolean):void {
	if (value != _showCategories) {
		_showCategories = value;
		showCategoriesChanged = true;
		invalidateProperties();
		dispatchEvent(new Event("showCategoriesChanged"));
	}
}

private function categoriesLoadedHandler(event:NCBOCategoriesEvent):void {
	categoriesCombo.enabled = !event.isError;
	if (event.categories.length > 0) {
		var array:Array = event.categories.slice();
		array.unshift(ALL_CATEGORIES);
		categories.source = array;
	} else {
		trace("Error loading categories: " + event.error);
		var errorCat:NCBOCategory = new NCBOCategory("", "Error loading categories");
		categories.source = [ errorCat ];
	}
	categories.refresh();
	categoriesCombo.selectedIndex = 0;
}

private function categoryChanged(event:Event):void {
	var selItem:Object = categoriesCombo.selectedItem;
	if (selItem is NCBOCategory) {
		selectedCategory = NCBOCategory(categoriesCombo.selectedItem);
		categoriesCombo.toolTip = selectedCategory.name; 
		ontologies.refresh(); 
	}
}

///////////////
// GROUPS
///////////////

public function get showGroups():Boolean {
	return _showGroups;
}

[Bindable("showGroupsChanged")]
[Inspectable(category="Common", defaultValue="true", name="Show Groups")]
public function set showGroups(value:Boolean):void {
	if (value != _showGroups) {
		_showGroups = value;
		showGroupsChanged = true;
		invalidateProperties();
		dispatchEvent(new Event("showGroupsChanged"));
	}
}

private function groupsLoadedHandler(event:NCBOGroupsEvent):void {
	groupsCombo.enabled = !event.isError;
	if (event.groups.length > 0) {
		var array:Array = event.groups.slice();
		array.unshift(ALL_GROUPS);
		groups.source = array;
	} else {
		groups.source = [ new NCBOOntologyGroup("", "Error loading groups") ];
	}
	groups.refresh();
	groupsCombo.selectedIndex = 0;
}

private function groupChanged(event:Event):void {
	var selItem:NCBOOntologyGroup = (groupsCombo.selectedItem as NCBOOntologyGroup);
	if (selItem) {
		selectedGroup = selItem;
		if (groupsCombo.width < 350) {
			groupsCombo.text = (selectedGroup.hasAcronym ? selectedGroup.acronym : selectedGroup.name);
		}
		groupsCombo.toolTip = selectedGroup.nameAndAcronym; 
		ontologies.refresh();
	}
}


/////////////////
// FILTER BOX
/////////////////

public function get showFilterBox():Boolean {
	return _showFilterBox;
}

[Bindable("showFilterBoxChanged")]
[Inspectable(category="Common", defaultValue="true")]
public function set showFilterBox(value:Boolean):void {
	if (value != _showFilterBox) {
		_showFilterBox = value;
		showFilterBoxChanged = true;
		invalidateProperties();
		dispatchEvent(new Event("showFilterBoxChanged"));
	}
}

/////////////////////////
// ONTOLOGIES
/////////////////////////

public function get initiallySelectedOntologyIDs():Array {
	return _initiallySelectedOntologyIDs;
}

[Inspectable(category="Common")]
public function set initiallySelectedOntologyIDs(value:Array):void {
	_initiallySelectedOntologyIDs = value;
}

public function get ontologiesLoaded():Boolean {
	return _ontologiesLoaded;
}

public function get currentOntologies():ArrayCollection {
	return ontologies;
}

public function get allOntologies():Array {
	return ontologies.source;
}

public function get ontologiesCount():uint {
	return ontologies.length;
}

public function get ontologiesUnfilteredCount():uint {
	return allOntologies.length;
}

private function initializeOntologies():void {
	filterBox.filterList = ontologiesList;
	ontologiesTextHighlighter.highlightTextFunction = function():String {
		return filterBox.text;
	};
	var itemRenderer:OntologyCheckBoxRenderer = new OntologyCheckBoxRenderer();
	itemRenderer.highlighter = ontologiesTextHighlighter;
	ontologiesList.itemRenderer = itemRenderer; 
	ontologiesList.contextMenu = createOntologiesContextMenu();
	ontologies.filterFunction = ontologiesFilterFunction;
	
	var popUp:DOIPopUp = new DOIPopUp();
	popUp.source = DOI_ONTOLOGIES;
	popUp.addEventListener(DOIPopUp.HIGHLIGHTING_CHANGED, ontologiesDOIHighlightingChanged);
	popUp.addEventListener(DOIPopUp.FILTERING_CHANGED, ontologiesDOIFilteringChanged);
	popUp.addEventListener(DOIPopUp.SORTING_CHANGED, ontologiesDOISortingChanged);
	ontologiesDOIPopUpButton.popUp = popUp;
	
	// set up the experimental thresholds for the ontologies
	DegreeOfInterestService.setThresholds(DOI_ONTOLOGIES, 50, 200);
}

private function ontologiesLoadedHandler(event:NCBOOntologiesEvent):void {
	var selectedOntology:NCBOOntology = null;
	var updateListener:Function = function(event:FlexEvent):void {
		ontologiesList.removeEventListener(FlexEvent.UPDATE_COMPLETE, updateListener);
		if (_initiallySelectedOntologyIDs && (_initiallySelectedOntologyIDs.length > 0)) {
			var selOntologies:Array = [];
			for (var i:int = 0; i < ontologies.length; i++) {
				var o:NCBOOntology = ontologies[i];
				if (_initiallySelectedOntologyIDs.indexOf(o.ontologyID) != -1) {
					selOntologies.push(o);
				}
			}
			if (selOntologies.length > 0) {
				ontologiesList.selectedItems = selOntologies;
				ontologiesList.scrollToItem(selOntologies[0]);
			}
		} else {
			ontologySelected(new ItemsChangedEvent(ItemsChangedEvent.ITEMS_CHANGED));
		}
		ontologiesList.invalidateDisplayList();
	};
	ontologiesList.addEventListener(FlexEvent.UPDATE_COMPLETE, updateListener);
	
	if (!event.isError) {
		ontologies.source = event.ontologies;
	} else {
		ontologies.source = [ new NCBOOntology("", "", "Error loading ontologies") ];
	}
	ontologies.refresh();
	cursorManager.removeBusyCursor();
	
	_ontologiesLoaded = true;
	dispatchEvent(new Event("ontologiesLoaded"));
	
	if (showDOI) {
		loadOntologiesDegreeOfInterest();
	}
}

private function ontologiesFilterFunction(item:Object):Boolean {
	var pass:Boolean = false;
	if (item is NCBOOntology) {
		var ontology:NCBOOntology = NCBOOntology(item);
		pass = true;
		 
		// filter by category
		if (selectedCategory != ALL_CATEGORIES) {
			if (!ontology.hasCategory(selectedCategory.id)) {
				pass = false;
			}
		}
		
		// filter by group
		if (pass && (selectedGroup != ALL_GROUPS)) {
			if (!ontology.hasGroup(selectedGroup.id)) {
				pass = false;
			}
		}
		
		// now filter by the filter text
		if (pass && (filterBox.text.length > 0)) {
			pass = filterBox.filterFunction(ontology);
		}

		// filter by Degree of interest
		if (pass && DegreeOfInterestService.isFiltering(DOI_ONTOLOGIES) && ontologiesDOIPopUpButton.enabled) {
			pass = DegreeOfInterestService.isInteresting(ontology, DOI_ONTOLOGIES);
		} 
	}
	return pass;
}

public function get selectedOntologies():Array {
	return (ontologiesList && ontologiesList.enabled ? ontologiesList.selectedItems : []);
}

public function set selectedOntologies(sel:Array):void {
	if (ontologiesList && ontologiesList.enabled) {
		ontologiesList.selectedItems = sel;
	}
}

public function get selectedOntologiesCount():uint {
	return (ontologiesList && ontologiesList.enabled ? ontologiesList.selectedItemsCount : 0);
}

/**
 * Returns true if no ontologies are checked, or if all ontologies are checked (ignores filtering).
 */
public function get allOntologiesSelected():Boolean {
	var count:uint = selectedOntologiesCount;
	return (count == 0 ? true : (count == ontologiesUnfilteredCount));
}

public function selectAllOntologies(event:Event = null):void {
	if (ontologiesList && ontologiesList.enabled) {
		ontologiesList.selectAll();
	}
}

public function selectNoOntologies(event:Event = null):void {
	if (ontologiesList && ontologiesList.enabled) {
		ontologiesList.selectNone();
	}
}

public function setOntologySelected(ontology:NCBOOntology, selected:Boolean):void {
	if (ontologiesList) {
		ontologiesList.selectItem(ontology, selected);
	}
}

public function isOntologySelected(ontology:NCBOOntology):Boolean {
	return (ontologiesList ? ontologiesList.isSelected(ontology) : false);
}

public function scrollToSelectedOntology():void {
	var selOntologies:Array = selectedOntologies;
	if (selOntologies.length >= 1) {
		var index:int = ontologies.getItemIndex(selOntologies[0]);
		if ((index != -1) && ontologiesList.enabled) {
			ontologiesList.scrollToIndex(index);
		}
	}
}

public function scrollToOntology(ontology:NCBOOntology):void {
	if (ontology && ontologiesList) {
		var index:int = ontologies.getItemIndex(ontology);
		if ((index != -1) && ontologiesList.enabled) {
			ontologiesList.scrollToIndex(index);
		}
	}
}

private function ontologySelected(event:ItemsChangedEvent):void {
	dispatchEvent(event.clone());
}


private function createOntologiesContextMenu():ContextMenu {
	var contextMenu:ContextMenu = new ContextMenu();
	contextMenu.hideBuiltInItems();

	var openInBPItem:ContextMenuItem = new ContextMenuItem("View Ontology in BioPortal");
	openInBPItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(event:ContextMenuEvent):void {
		var renderer:IListItemRenderer = (event.mouseTarget as IListItemRenderer);
		if (renderer) {
			var ontology:IOntology = (ontologiesList.itemRendererToItem(renderer) as IOntology);
			NavigateToBioPortal.viewOntologyMetaData(ontology, NavigateToBioPortal.NEW_WINDOW);
		}
	});
	contextMenu.customItems.push(openInBPItem);
	
	contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, function(event:ContextMenuEvent):void {
		var ontology:IOntology = null;
		var renderer:IListItemRenderer = (event.mouseTarget as IListItemRenderer);
		if (renderer) {
			ontology = (ontologiesList.itemRendererToItem(renderer) as IOntology);
		}
		openInBPItem.visible = (ontology != null);
	});
	return contextMenu;
}


////////////
// DOI 
////////////


public function get showDOI():Boolean {
	return _showDOI;
}

[Bindable("showDOIChanged")]
[Inspectable(category="Common", defaultValue="false")]
public function set showDOI(value:Boolean):void {
	if (value != _showDOI) {
		_showDOI = value;
		invalidateProperties();
		dispatchEvent(new Event("showDOIChanged"));
	}
}

public function loadOntologiesDegreeOfInterest():void {
	DegreeOfInterestService.loadDegreeOfInterest(ontologies.source, ontologiesDegreeOfInterestLoaded);
	ontologiesDOIPopUpButton.startSpinning();
}

private function ontologiesDegreeOfInterestLoaded(changedResults:Array, error:String = null):void {
	ontologiesDOIPopUpButton.stopSpinning();
	if (!error) {
		ontologiesDOIPopUpButton.enabled = true;
		if (DegreeOfInterestService.isHighlighting(DOI_ONTOLOGIES)) {
			repaintOntologyRenderers();
		}
		if (DegreeOfInterestService.isFiltering(DOI_ONTOLOGIES)) {
			ontologies.refresh();
		}
		if (DegreeOfInterestService.isSorting(DOI_ONTOLOGIES)) {
			ontologiesDOISortingChanged(null);
		}
	}
}


private function ontologiesDOIHighlightingChanged(event:Event):void {
	var on:Boolean = DegreeOfInterestService.isHighlighting(DOI_ONTOLOGIES);
	ontologiesTextHighlighter.enabled = !on;
	repaintOntologyRenderers();
}

private function ontologiesDOIFilteringChanged(event:Event):void {
	ontologies.refresh();
}

private function ontologiesDOISortingChanged(event:Event):void {
	var on:Boolean = DegreeOfInterestService.isSorting(DOI_ONTOLOGIES);
	var sortField:SortField = new SortField(ontologiesList.dataField);;
	if (on) {
		sortField.numeric = true; 
		sortField.compareFunction = DegreeOfInterestService.degreeOfInterestSortFunction;
	} else if (!on) {
		sortField.caseInsensitive = true;
	}

	var oldSort:Sort = ontologies.sort;
	var oldSortField:SortField = (oldSort && (oldSort.fields.length > 0) ? oldSort.fields[0] : null);
	if (!oldSortField || (oldSortField && (oldSortField.numeric != sortField.numeric) && 
			(oldSortField.caseInsensitive != sortField.caseInsensitive) &&  
			(oldSortField.compareFunction != sortField.compareFunction))) {
		var s:Sort = new Sort();
		s.fields = [ sortField ];
		ontologies.sort = s;
        ontologies.refresh();
	}
}

private function repaintOntologyRenderers():void {
	for each (var item:Object in ontologies) {
		var renderer:IListItemRenderer = ontologiesList.itemToItemRenderer(item);
		if (renderer && (renderer is UIComponent)) {
			UIComponent(renderer).invalidateDisplayList();
		}
	}
}

