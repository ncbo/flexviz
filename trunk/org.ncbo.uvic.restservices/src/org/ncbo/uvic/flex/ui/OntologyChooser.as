package org.ncbo.uvic.flex.ui
{
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	
	import flex.utils.ui.ContentWindow;
	import flex.utils.ui.FilterBox;
	import flex.utils.ui.TextHighlighter;
	import flex.utils.ui.UIUtils;
	import flex.utils.ui.renderers.DataGridItemHighlightRenderer;
	
	import mx.collections.ArrayCollection;
	import mx.containers.HBox;
	import mx.containers.VBox;
	import mx.controls.Alert;
	import mx.controls.ComboBox;
	import mx.controls.DataGrid;
	import mx.controls.Label;
	import mx.core.IFactory;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.events.ListEvent;
	import mx.managers.PopUpManager;
	
	import org.ncbo.uvic.flex.IRestService;
	import org.ncbo.uvic.flex.NCBORestService;
	import org.ncbo.uvic.flex.events.NCBOCategoriesEvent;
	import org.ncbo.uvic.flex.events.NCBOGroupsEvent;
	import org.ncbo.uvic.flex.events.NCBOOntologiesEvent;
	import org.ncbo.uvic.flex.model.NCBOCategory;
	import org.ncbo.uvic.flex.model.NCBOOntology;
	import org.ncbo.uvic.flex.model.NCBOOntologyGroup;

	/**
	 * Displays all the latest versions of the BioPortal ontologies in a sortable DataGrid.
	 * The ontologies can also be filtered by typing in a filter text box (filters all the columns),
	 * or by choosing one ontology category from the category filter combobox.
	 * 
	 * This component can also display all the versions for a single ontology. 
	 * 
	 * Also contains an OK and Cancel button which both fire a CloseEvent.
	 * 
	 * @author Chris Callendar
	 * @date September 18th, 2008
	 */
	public class OntologyChooser extends ContentWindow
	{
		private static const COLUMNS:Array = [
			  { name: "Name", field: "nameAndAbbreviation", width: 240, number: false }, 
			  { name: "ID", field: "id", width: 60, number: true },
			  { name: "Ontology ID", field: "ontologyID", width: 85, number: true },
			  { name: "Format", field: "format", width: 70, number: false },
			  { name: "Version", field: "version", width: 125, number: false } 
			];

		private var ontologies:ArrayCollection;
		private var _selectedOntology:NCBOOntology;
		private var oldSelectedOntology:NCBOOntology;
		private var showVersions:Boolean;
		private var service:IRestService;
		private var filterText:String;
		
		private var categories:ArrayCollection;
		private const ALL_CATEGORIES:NCBOCategory = new NCBOCategory("", "All Categories");
		private var selectedCategory:NCBOCategory;
		
		private var groups:ArrayCollection = new ArrayCollection([ALL_GROUPS]);
		private const ALL_GROUPS:NCBOOntologyGroup = new NCBOOntologyGroup("", "All Groups");
		private var selectedGroup:NCBOOntologyGroup;

		
		private var highlighter:TextHighlighter;
		private var renderer:DataGridItemHighlightRenderer;
		
		private var _datagrid:DataGrid;
		private var _filterBox:FilterBox;
		private var _categoriesCombo:ComboBox;
		private var _groupsCombo:ComboBox;
		private var _selectedOntologyLabel:Label;
		
		public static function show(parent:DisplayObject, callback:Function, service:IRestService, 
					initialOntology:NCBOOntology = null, showVersions:Boolean = false):OntologyChooser {
			var chooser:OntologyChooser = new OntologyChooser(service, initialOntology, showVersions);
			chooser.addEventListener(CloseEvent.CLOSE, function(event:CloseEvent):void {
				PopUpManager.removePopUp(chooser);
				callback((event.detail == ContentWindow.OK ? chooser.selectedOntology : null));
			});
			PopUpManager.addPopUp(chooser, parent, true);
			PopUpManager.centerPopUp(chooser);
			chooser.setFocus();
			return chooser;
		}  
		
		public function OntologyChooser(restService:IRestService, initialOntology:NCBOOntology = null, 
										showVersions:Boolean = false) {
			super(ContentWindow.OK | ContentWindow.CANCEL);
			this.service = (restService == null ? new NCBORestService(NCBORestService.APIKEY_FLEXVIZ) : restService);
			this.resizable = true;
			this.showVersions = showVersions && initialOntology && initialOntology.ontologyID;
			this.ontologies = new ArrayCollection([ new NCBOOntology("", "", "Loading...") ]);
			this.selectedOntology = initialOntology;
			this.oldSelectedOntology = null;
			this.categories = new ArrayCollection();
			this.selectedCategory = ALL_CATEGORIES;
			this.groups = new ArrayCollection();
			this.selectedGroup = ALL_GROUPS;
			this.filterText = "";
			
			// this filter function filters first on the selected category, and second on the filter text
			this.ontologies.filterFunction = filterFunction;
			
			// the highlighter and renderer will bold the text that matches the filter text
			highlighter = new TextHighlighter(null, getFilterText);
			renderer = new DataGridItemHighlightRenderer(highlighter);
			
			this.addEventListener(FlexEvent.CREATION_COMPLETE, created);
		}
		
		private function created(event:FlexEvent):void {
			this.title = "Choose an ontology" + (showVersions ? " version" : "");
			this.width = 600;
			this.height = 400;
			if (!showVersions) {
				this.status = "(Remote ontologies are hidden)";
			}
			okButton.enabled = false;
			dataGrid.enabled = false;

			if (showVersions && selectedOntology) {
				// load the versions for the selected ontology
				service.getOntologyVersions(selectedOntology.ontologyID, ontologiesLoadedHandler);
			} else {
				// load the ontologies and categories
				categoriesComboBox.enabled = false;
				groupsComboBox.enabled = false;
				service.getNCBOOntologies(ontologiesLoadedHandler);
				service.getOntologyCategories(categoriesLoadedHandler);
				service.getOntologyGroups(groupsLoadedHandler);			
			}
		}
		
		private function ontologiesLoadedHandler(event:NCBOOntologiesEvent):void {
			if (event.isError || (event.ontologies == null)) {
				var errorMsg:String = (event.isError ? event.error.message : "No ontologies were loaded");
				var error:NCBOOntology = new NCBOOntology("", "", errorMsg);
				ontologies.source = [ error ];
			} else {
				callLater(loadOntologiesIntoDataGrid, [ event.ontologies ]);
			}  
		}
		
		private function loadOntologiesIntoDataGrid(sourceOntologies:Array):void {
			ontologies.source = sourceOntologies; 
			dataGrid.enabled = true;
			
			var initialOntology:NCBOOntology = selectedOntology;
			if (initialOntology != null) {
				var index:int = ontologies.source.indexOf(initialOntology);
				if (index != -1) {
					dataGrid.selectedIndex = index;
					// need to validate before we can scroll to the selected item
					dataGrid.validateNow();
					dataGrid.scrollToIndex(index);
					// sets the label and updates the ok button
					selectedOntology = initialOntology;
				}
			}

			dataGrid.addEventListener(ListEvent.CHANGE, listSelectionChanged);
			dataGrid.addEventListener(FlexEvent.UPDATE_COMPLETE, dataGridUpdateComplete);
		}
		
		private function categoriesLoadedHandler(event:NCBOCategoriesEvent):void {
			if (event.categories != null) {
				var array:Array = event.categories.slice();
				// add this one first
				array.unshift(ALL_CATEGORIES);
				categories.source = array;
				categoriesComboBox.dataProvider = categories;
				categoriesComboBox.enabled = true;
				categoriesComboBox.selectedItem = ALL_CATEGORIES;
				categoriesComboBox.addEventListener(ListEvent.CHANGE, function(event:ListEvent):void {
					if (categoriesComboBox.selectedItem is NCBOCategory) {
						selectedCategory = NCBOCategory(categoriesComboBox.selectedItem);
						ontologies.refresh();	// updates the filter
					}
				});
			} else if (event.isError) {
				Alert.show("Error loading ontology categories:\n" + event.error, "Error");
			}
		}
		
		private function groupsLoadedHandler(event:NCBOGroupsEvent):void {
			groupsComboBox.enabled = !event.isError;
			if (event.groups.length > 0) {
				var array:Array = event.groups.slice();
				array.unshift(ALL_GROUPS);
				groups.source = array;
			} else {
				groups.source = [ new NCBOOntologyGroup("", "Error loading groups") ];
			}
			groupsComboBox.dataProvider = groups;
			groupsComboBox.rowCount = Math.min(20, groups.length);
			groups.refresh();
			groupsComboBox.selectedIndex = 0;
			groupsComboBox.addEventListener(ListEvent.CHANGE, function(event:ListEvent):void {
				if (groupsComboBox.selectedItem is NCBOOntologyGroup) {
					selectedGroup = NCBOOntologyGroup(groupsComboBox.selectedItem);
					ontologies.refresh();	// updates the filter
				}
			});
		}
		
		override public function setFocus():void {
			super.setFocus();
			dataGrid.setFocus();
		}
		
		override protected function createChildren():void {
			super.createChildren();
			
			var vbox:VBox = new VBox();
			vbox.setStyle("verticalGap", 0);
			
			if (!showVersions) {
				var categoriesBox:HBox = createHBox();
				var lbl:Label = createLabel("Filter by category:");
				categoriesBox.addChild(lbl);
				categoriesBox.addChild(categoriesComboBox);
				vbox.addChild(categoriesBox);
				
				var groupsBox:HBox = createHBox();
				lbl = createLabel("Filter by group:");
				groupsBox.addChild(lbl);
				groupsBox.addChild(groupsComboBox);
				vbox.addChild(groupsBox);
			}
			
			var filterBox:HBox = createHBox();
			lbl = createLabel("Filter by text:");
			filterBox.addChild(lbl);
			filterBox.addChild(filterTextBox);
			vbox.addChild(filterBox);
			
			var bottomBox:HBox = createHBox();
			lbl = createLabel("Selected ontology:");
			bottomBox.addChild(lbl);
			bottomBox.addChild(selectedOntologyLabel);

			container.addChild(vbox);
			container.addChild(dataGrid);
			container.addChild(bottomBox);
		}
		
		private function createLabel(txt:String, w:Number = 120):Label {
			var lbl:Label = UIUtils.createLabel(txt);
			lbl.width = w;
			return lbl;
		}
		
		private function createHBox():HBox {
			var hbox:HBox = new HBox();
			hbox.percentWidth = 100;
			hbox.setStyle("verticalAlign", "middle");
			hbox.setStyle("horizontalGap", 2);
			hbox.setStyle("borderColor", 0xdddddd);
			hbox.setStyle("borderStyle", "solid");
			hbox.setStyle("borderThickness", 1);
			hbox.setStyle("paddingLeft", 2);
			hbox.setStyle("paddingTop", 2);
			hbox.setStyle("paddingRight", 2);
			hbox.setStyle("paddingBottom", 2);
			return hbox;
		}
		
		private function get selectedOntologyLabel():Label {
			if (_selectedOntologyLabel == null) {
				_selectedOntologyLabel = new Label();
				_selectedOntologyLabel.setStyle("fontSize", 12);
				_selectedOntologyLabel.setStyle("fontWeight", "bold");
				_selectedOntologyLabel.setStyle("color", 0x336699);
			}
			return _selectedOntologyLabel;
		}
		
		private function get categoriesComboBox():ComboBox {
			if (_categoriesCombo == null) {
				_categoriesCombo = new ComboBox();
				_categoriesCombo.toolTip = "Change the category to filter the ontologies";
				//_categoriesCombo.setStyle("color", 0x336699);
				_categoriesCombo.rowCount = 12;
				_categoriesCombo.dataProvider = new ArrayCollection([ new NCBOCategory("", "Loading categories...") ]);
			}
			return _categoriesCombo;
		}
		
		private function get groupsComboBox():ComboBox {
			if (_groupsCombo == null) {
				_groupsCombo = new ComboBox();
				_groupsCombo.toolTip = "Change the group to filter the ontologies";
				//_groupsCombo.setStyle("color", 0x336699);
				_groupsCombo.dataProvider = new ArrayCollection([ new NCBOOntologyGroup("", "Loading groups...") ]);
			}
			return _groupsCombo;
		}
		
		
		private function get dataGrid():DataGrid {
			if (_datagrid == null) {
				_datagrid = new DataGrid();
				_datagrid.editable = false;
				_datagrid.resizableColumns = true;
				_datagrid.sortableColumns = true;
				_datagrid.showDataTips = true;
				_datagrid.allowMultipleSelection = false;
				_datagrid.doubleClickEnabled = true;

				var columns:Array = new Array();
				for (var i:int = 0; i < COLUMNS.length; i++) {
					var col:Object = COLUMNS[i];
					var rend:IFactory = (i == 0 ? renderer : null);
					columns.push(UIUtils.createDataGridColumn(col.name, col.field, col.width, renderer, col.number));
				}
				_datagrid.columns = columns;

				// looks better with the radio button item renderer
				//_datagrid.setStyle("selectionColor", 0xffffff);
	
				// must do this after setting the columns, otherwise the columns are auto-generated from the data
				_datagrid.dataProvider = ontologies;
				_datagrid.percentWidth = 100;
				_datagrid.percentHeight = 100;
			
				_datagrid.addEventListener(MouseEvent.DOUBLE_CLICK, function(event:MouseEvent):void {
					close(OK);
				});
			}
			return _datagrid;
		}
		
		private function get filterTextBox():FilterBox {
			if (_filterBox == null) {
				_filterBox = new FilterBox();
				// set the filter to work on all the fields in the DataGrid
				_filterBox.filterFields = [ "nameAndAbbreviation", "id", "ontologyID", "format", "version" ];
				_filterBox.filterList = dataGrid;
				// clear the initial text
				_filterBox.text = "";
				_filterBox.addEventListener(FilterBox.FILTER_TEXT_CHANGED, function(event:TextEvent):void {
					filterText = event.text;
				});
			}
			return _filterBox;
		}
		
		private function listSelectionChanged(event:ListEvent):void {
			if (dataGrid.selectedItem is NCBOOntology) {
				selectedOntology = NCBOOntology(dataGrid.selectedItem);
			} else {
				selectedOntology = null;
			}
		}
		
		private function dataGridUpdateComplete(event:FlexEvent):void {
			var index:int;
			if (selectedOntology != null) {
				index = ontologies.getItemIndex(selectedOntology);
				if (index == -1) {
					oldSelectedOntology = selectedOntology;
					selectedOntology = null;
				}
			}
			// restore the selection if no ontology is selected
			else if (oldSelectedOntology != null) {
				if (dataGrid.selectedItem == null) {
					index = ontologies.getItemIndex(oldSelectedOntology);
					if (index != -1) {
						selectedOntology = oldSelectedOntology;
						dataGrid.selectedItem = selectedOntology;
						dataGrid.scrollToIndex(index);
						oldSelectedOntology = null;
					}
				} else {
					// a new item has been selected, so we don't need this anymore
					oldSelectedOntology = null;
				}
			}
		}
		
		private function filterFunction(item:Object):Boolean {
			var pass:Boolean = false;
			if (item is NCBOOntology) {
				var ontology:NCBOOntology = NCBOOntology(item);
				pass = true;
				
				if (!showVersions) {
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
				}
				
				// then filter by the filter textbox
				if (pass) {
					pass = filterTextBox.filterFunction(ontology);
				}
			}
			return pass;
		}
		
		public function getFilterText():String {
			return filterText;
		}		
		
		public function get selectedOntology():NCBOOntology {
			return _selectedOntology;
		}
		
		public function set selectedOntology(ontology:NCBOOntology):void {
			_selectedOntology = ontology;
			if (ontology) {
				selectedOntologyLabel.text = ontology.name + 
					(showVersions ? " (" + ontology.version + ")" : "");
			} else {
				selectedOntologyLabel.text = "";
			}
			if (okButton) {
				okButton.enabled = (ontology != null);
			}
		}
		
	}

}