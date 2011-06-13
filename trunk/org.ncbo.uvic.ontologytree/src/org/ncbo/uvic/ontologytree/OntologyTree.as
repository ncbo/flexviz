package org.ncbo.uvic.ontologytree
{
	import flash.display.DisplayObject;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import flex.utils.StringUtils;
	import flex.utils.ui.Spinner;
	import flex.utils.ui.UIUtils;
	import flex.utils.ui.URLLinkButton;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ICollectionView;
	import mx.containers.ApplicationControlBar;
	import mx.containers.Canvas;
	import mx.containers.HBox;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.controls.PopUpButton;
	import mx.controls.Tree;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.core.IDataRenderer;
	import mx.core.IFactory;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.events.CollectionEvent;
	import mx.events.DropdownEvent;
	import mx.events.FlexEvent;
	import mx.events.ListEvent;
	import mx.events.ResizeEvent;
	import mx.events.TreeEvent;
	import mx.utils.StringUtil;
	
	import org.ncbo.uvic.flex.IRestService;
	import org.ncbo.uvic.flex.OntologyConstants;
	import org.ncbo.uvic.flex.events.NCBOOntologyEvent;
	import org.ncbo.uvic.flex.model.NCBOConcept;
	import org.ncbo.uvic.flex.model.NCBOOntology;
	import org.ncbo.uvic.flex.ui.AutoCompleteSearchBox;
	import org.ncbo.uvic.flex.ui.OntologyList;
	import org.ncbo.uvic.flex.util.NavigateToBioPortal;
	import org.ncbo.uvic.ontologytree.events.JumpToConceptEvent;
	import org.ncbo.uvic.ontologytree.events.TreeOntologyChangedEvent;
	import org.ncbo.uvic.ontologytree.events.TreeRootChangedEvent;

	[Event(name="ontologyChanged", type="org.ncbo.uvic.ontologytree.events.TreeOntologyChangedEvent")]
	[Event(name="jumpToConcept", type="org.ncbo.uvic.ontologytree.events.JumpToConceptEvent")]
	[Event(name="treeRootChanged", type="org.ncbo.uvic.ontologytree.events.TreeRootChangedEvent")]
	[Event(name="treeRootRestored", type="org.ncbo.uvic.ontologytree.events.TreeRootChangedEvent")]
	[Event(name="change", type="mx.events.ListEvent")]
	[Event(name="doubleClick", type="flash.events.MouseEvent")]
	[Event(name="itemOpen", type="mx.events.TreeEvent")]
	[Event(name="itemOpening", type="mx.events.TreeEvent")]
	[Event(name="itemClose", type="mx.events.TreeEvent")]

	/**
	 * Displays a single ontology in a Flex Tree control.
	 * Also has a top control bar which has a search/jump to textbox.
	 * 
	 * @author Chris Callendar
	 * @date April 28th, 2009
	 */
	public class OntologyTree extends Canvas
	{

		[Embed(source='/assets/class.gif')]
		private static const CLASS_ICON:Class;
		[Embed(source="/assets/collapse_all.gif")]
		private static const COLLAPSE_ICON:Class;
		[Embed(source="/assets/black_arrow_down.png")]
		private static const OPEN_ICON:Class;
		[Embed(source="/assets/black_arrow_up.png")]
		private static const CLOSE_ICON:Class;
		[Embed(source='/assets/stop.gif')]
      	public static const STOP_ICON:Class;

		private var _service:IRestService;
		private var _ontology:NCBOOntology;
		private var _tree:CustomTree;
		private var _busyComponent:UIComponent;
		private var busySpinner:Spinner;
		private var stopButton:Button;
		private var _topBar:ApplicationControlBar;
		private var _ontologyLink:URLLinkButton;
		private var _searchBar:ApplicationControlBar;
		private var _autoCompleteBox:AutoCompleteSearchBox;
		private var _jumpToButton:Button;
		private var _openButton:PopUpButton;
		private var ontologiesPopUp:OntologyList;
		protected var dataDescriptor:OntologyDataDescriptor;

		private var _canChangeRoot:Boolean;
		private var changeRootMenuItem:ContextMenuItem;
		private var restoreDefaultRootMenuItem:ContextMenuItem;
		private var _canChangeOntology:Boolean;
		
		private var _treeStyleName:String = "tree";
		private var _busyStyleName:String = "busySpinner";
		private var _busyComponentStyleName:String = "busyComponent";
		private var _topBarStyleName:String = "topBar";
		private var _searchBarStyleName:String = "searchBar";
		private var _ontologyLinkStyleName:String = "ontologyLink";
		
		public function OntologyTree() {
			super();
			this.dataDescriptor = new OntologyDataDescriptor();
			doubleClickEnabled = true;
			this.ontologiesPopUp = new OntologyList();
			this._canChangeRoot = true;
			this._canChangeOntology = true;
			this.changeRootMenuItem = new ContextMenuItem("Use Selected Node As Root", true, true, false);
			this.restoreDefaultRootMenuItem = new ContextMenuItem("Restore Original Root", false, true, false);
			
			addEventListener(ResizeEvent.RESIZE, resized);
		}
		
		override protected function createChildren():void {
			super.createChildren();
			addChild(topBar);
			addChild(searchBar);
			addChild(tree);
			addChild(busyComponent);
		}
		
		public function get topBar():ApplicationControlBar {
			if (_topBar == null) {
				_topBar = new ApplicationControlBar();
				_topBar.styleName = topBarStyleName;
				_topBar.height = 26;
				_topBar.addChild(ontologyLink);
				if (canChangeOntology) {
					_topBar.addChild(openButton);
				}
				_topBar.addChild(UIUtils.createIconButton(COLLAPSE_ICON, collapseTree, "Collapse All", 20, 20));
				_topBar.enabled = (service != null);
			}
			return _topBar;
		}
		
		public function get ontologyLink():URLLinkButton {
			if (_ontologyLink == null) {
				_ontologyLink = new URLLinkButton();
				_ontologyLink.styleName = ontologyLinkStyleName;
				_ontologyLink.toolTip = "Click to open the ontology in BioPortal";
				if (ontology != null) {
					_ontologyLink.label = ontology.name;
				}
			}
			return _ontologyLink;
		}
		
		public function get openButton():PopUpButton {
			if (_openButton == null) {
				_openButton = new PopUpButton();
				_openButton.styleName = "openButton";
				//_openButton.setStyle("arrowButtonWidth", 20);
				_openButton.width = 20;
				_openButton.height = 20;
				_openButton.popUp = ontologiesPopUp;
				ontologiesPopUp.popUpButton = _openButton;
				_openButton.toolTip = "Click to load a different ontology";
				_openButton.addEventListener(DropdownEvent.OPEN, function(event:DropdownEvent):void {
					openButton.setStyle("popUpIcon", CLOSE_ICON);
					if (ontology) {
						ontologiesPopUp.selectedOntology = ontology;
					}
				});
				_openButton.addEventListener(DropdownEvent.CLOSE, function(event:DropdownEvent):void {
					openButton.setStyle("popUpIcon", OPEN_ICON);
					setNewOntology(ontologiesPopUp.selectedOntology);
				});
			}
			return _openButton;
		}
		
		public function get searchBar():ApplicationControlBar {
			if (_searchBar == null) {
				_searchBar = new ApplicationControlBar();
				_searchBar.height = 26;
				_searchBar.styleName = searchBarStyleName;
				_searchBar.horizontalScrollPolicy = ScrollPolicy.OFF;				
				_searchBar.verticalScrollPolicy = ScrollPolicy.OFF;
				_searchBar.addChild(UIUtils.createLabel("Find:"));
				_searchBar.addChild(autoCompleteBox);
				_searchBar.addChild(jumpToButton);
			}
			return _searchBar;
		}
		
		public function get autoCompleteBox():AutoCompleteSearchBox {
			if (_autoCompleteBox == null) {
				_autoCompleteBox = new AutoCompleteSearchBox();
				_autoCompleteBox.spinner.styleName = busyStyleName;
				_autoCompleteBox.percentWidth = 100;
				_autoCompleteBox.enabled = false;
				_autoCompleteBox.addEventListener(AutoCompleteSearchBox.ENTER_PRESSED, jumpToConceptHandler);
			}
			return _autoCompleteBox;
		}
		
		public function get jumpToButton():Button {
			if (_jumpToButton == null) {
				_jumpToButton = UIUtils.createTextButton("Go", jumpToConceptHandler, 
						"Find the concept in the tree below", 32, 22, false);
				_jumpToButton.styleName = "jumpToButton";
			}
			return _jumpToButton;
		}
		
		public function get tree():Tree {
			if (_tree == null) {
				_tree = new CustomTree();
				_tree.styleName = treeStyleName;
				_tree.labelField = "shortName";
				_tree.showDataTips = true;
				_tree.dataTipFunction = conceptToolTip;
				//_tree.dataTipField = "name";
				_tree.showRoot = true;
				_tree.allowDragSelection = false;
				_tree.allowMultipleSelection = false;
				_tree.editable = false;
				_tree.enabled = false;
				_tree.doubleClickEnabled = true;
				// remove folder/leaf icons
				changeIcons(false);
				_tree.dataDescriptor = dataDescriptor;
				_tree.itemRenderer = new OntologyTreeItemRenderer("busySpinner");
				//_tree.addEventListener(Event.CHANGE, treeSelectedItemChanged);
				
				_tree.contextMenu = new ContextMenu();
				_tree.contextMenu.hideBuiltInItems();
				initializeTreeContextMenu(_tree.contextMenu);
				
				_tree.addEventListener(ListEvent.CHANGE, treeSelectionChanged);
				_tree.addEventListener(MouseEvent.DOUBLE_CLICK, treeDoubleClicked);
				_tree.addEventListener(TreeEvent.ITEM_OPEN, treeNodeExpanded);
				_tree.addEventListener(TreeEvent.ITEM_OPENING, treeNodeExpanding);
				_tree.addEventListener(TreeEvent.ITEM_CLOSE, treeNodeCollapsed);
			}
			return _tree;
		}
		
		public function get busyComponent():UIComponent {
			if (_busyComponent == null) {
				_busyComponent = new HBox();
				_busyComponent.styleName = "busyComponent";
				_busyComponent.visible = false;
				busySpinner = new Spinner();
				busySpinner.styleName = "busySpinner";
				busySpinner.setActualSize(16, 16);
				_busyComponent.addChild(busySpinner);
				busySpinner.running = false;
				var label:Label = new Label();
				label.text = "Building tree...";
				_busyComponent.addChild(label);
				stopButton = UIUtils.createIconButton(STOP_ICON, stopButtonClicked, "Stop", 17, 17);
				stopButton.setStyle("cornerRadius", 0);
				_busyComponent.addChild(stopButton);
			}
			return _busyComponent;
		}
		
		[Inspectable]
		public function get canChangeRoot():Boolean {
			return _canChangeRoot;
		}
		
		public function set canChangeRoot(value:Boolean):void {
			if (value != _canChangeRoot) {
				_canChangeRoot = value;
				if (!value) {
					changeRootMenuItem.visible = false;
					restoreDefaultRootMenuItem.visible = false;
				}
			}
		}

		[Inspectable]
		public function get canChangeOntology():Boolean {
			return _canChangeOntology;
		}
		
		public function set canChangeOntology(value:Boolean):void {
			if (value != _canChangeOntology) {
				_canChangeOntology = value;
				if (value) {
					showOpenButton();
				} else {
					hideOpenButton();
				}
			}
		}
		
		[Inspectable]
		public function get treeStyleName():String {
			return _treeStyleName;
		}
		
		public function set treeStyleName(name:String):void {
			_treeStyleName = name;
			if (_tree) {
				_tree.styleName = name;
			}
		}
		
		[Inspectable]
		public function get busyStyleName():String { 
			return _busyComponentStyleName;
		}
		
		public function set busyStyleName(name:String):void {
			_busyComponentStyleName = name;
			if (_busyComponent) {
				_busyComponent.styleName = name;
			}
		}
		
		[Inspectable]
		public function get topBarStyleName():String { 
			return _topBarStyleName;
		}
		
		public function set topBarStyleName(name:String):void {
			_topBarStyleName = name;
			if (_topBar) {
				_topBar.styleName = name;
			}
		}
		
		[Inspectable]
		public function get searchBarStyleName():String {
			return _searchBarStyleName;
		}
		
		public function set searchBarStyleName(name:String):void {
			_searchBarStyleName = name;
			if (_searchBar) {
				_searchBar.styleName = name;
			}
		}
		
		[Inspectable]
		public function get ontologyLinkStyleName():String { 
			return _ontologyLinkStyleName;
		}
		
		public function set ontologyLinkStyleName(name:String):void {
			_ontologyLinkStyleName = name;
			if (_ontologyLink) {
				_ontologyLink.styleName = name;
			}
		}

		public function get service():IRestService {
			return _service;
		}
		
		public function set service(s:IRestService):void {
			if (s) {
				_service = s;
				dataDescriptor.service = s;
				ontologiesPopUp.service = s;
				autoCompleteBox.service = s;
				topBar.enabled = true;
				if (ontology && !dataDescriptor.rootsLoaded) {
					loadRoots();
				}
			}
		}
		
	    public function set itemRenderer(value:IFactory):void {
	        tree.itemRenderer = value;
	    }

		public function get itemRenderer():IFactory {
			return tree.itemRenderer;
		}
		
		public function get ontologyID():String {
			return (_ontology ? _ontology.ontologyID : null);
		}
		
		public function set ontologyID(value:String):void {
			if (value) {
				service.getOntologyByVirtualID(value, ontologyLoaded);
			} else {
				this.ontology = null;
			}
		}
		
		public function get ontologyVersionID():String {
			return (_ontology ? _ontology.ontologyVersionID : null);	
		}
		
		public function set ontologyVersionID(value:String):void {
			if (value) {
				service.getNCBOOntology(value, ontologyLoaded, true);
			} else {
				this.ontology = null;
			}
		}
		
		private function ontologyLoaded(event:NCBOOntologyEvent):void {
			if (event.ontology) {
				this.ontology = event.ontology;
			}
		}
		
		public function get ontology():NCBOOntology {
			return _ontology;
		} 
		
		[Bindable("ontologyChanged")]
		public function set ontology(ont:NCBOOntology):void {
			if (ont != _ontology) {
				var ok:Boolean = (ont != null);
				ontologyLink.enabled = (ont != null);
				ontologyLink.label = (ont ? ont.name : "No ontology loaded");
				tree.enabled = ok;
				autoCompleteBox.enabled = ok;
				autoCompleteBox.ontology = ont;
				jumpToButton.enabled = ok;
				if (ok) {
					if (ont != _ontology) {
						this._ontology = ont;
						ontologyLink.url = NavigateToBioPortal.getBioPortalOntologyMetaDataURL(ont.id);
						dataDescriptor.ontologyVersionID = ont.id;
						dataDescriptor.ontologyVirtualID = ont.ontologyID;
						// for the is_a/part_of icons
						changeIcons(ontology.isOWL);
						if (service && !dataDescriptor.rootsLoaded) {
							loadRoots();
						}
					}
				} else {
					_ontology = null;
					ontologyLink.url = null;
					// clear the tree
					dataDescriptor.ontologyVersionID = "";
					dataDescriptor.ontologyVirtualID = "";
					tree.dataProvider = new ArrayCollection();
				}
				dispatchEvent(new TreeOntologyChangedEvent(TreeOntologyChangedEvent.ONTOLOGY_CHANGED, ont));
			}
		}
		
		/**
		 * Loads the ontology and possible sets the concept to use as the root of the tree.
		 */
		public function loadOntology(ont:NCBOOntology, root:NCBOConcept = null):void {
			this.rootConcept = root;
			this.ontology = ont;
		}
		
		/**
		 * Returns the root concept of the tree if it has been set.
		 * It will be null by default if the roots of the ontology are used.
		 */
		public function get rootConcept():NCBOConcept {
			return dataDescriptor.rootConcept;
		}
		
		/**
		 * Sets the optional concept to use as the root of the tree.
		 * By default the top level nodes of the ontology are used as the roots of the tree.
		 * The tree will be re-loaded only if the roots have already been loaded.
		 * If the canChangeRoot property is false then this function does nothing.
		 */
		public function set rootConcept(root:NCBOConcept):void {
			if (canChangeRoot && (root != dataDescriptor.rootConcept)) {
				var reload:Boolean = dataDescriptor.rootsLoaded;
				dataDescriptor.rootConcept = root;
				if (reload) {
					tree.openItems = {}; 
					loadRoots();
				}
				restoreDefaultRootMenuItem.visible = (root != null); 
			}
		}
		
		public function get selectedNode():TreeNode {
			return (tree.selectedItem as TreeNode);
		}
		
		public function set selectedNode(node:TreeNode):void {
			if (node) {
				var selected:Boolean = selectNode(node);
				// if the concept isn't in the tree - then load it from the rest service
				if (!selected) {
					loadConcept(node.concept);
				}
			} else {
				selectNode(null);
			}
		}
		
		protected function selectNode(node:TreeNode):Boolean {
			var selected:Boolean = false;
			if (tree.dataProvider) {
				if (node != tree.selectedItem) {
					tree.selectedItem = node;
					// check to see if the selection worked
					// it will fail if the item is hidden (but has previously been shown)
					// of if the node isn't in the tree yet
					if ((node != null) && (tree.selectedItem == null)) {
						// selection failed - make sure children are loaded for each, then
						// expand parent node and try selecting again
						var hierarchy:Array = getParentHierarchy(node, true);
						var callback:Function = function():void {
							// now expand the parent hierarchy and then select the node
							for each (var parentNode:TreeNode in hierarchy) {
								tree.expandItem(parentNode, true, false);
							}
							tree.selectedItem = node;
							// scroll to the selected item, and fire the change event
							if (tree.selectedItem != null) {
								tree.dispatchEvent(new ListEvent(ListEvent.CHANGE));
								// scroll to the selected item, have to wait maxVerticalScrollPosition to update
								callLater(function():void {
									tree.scrollToIndex(tree.getItemIndex(node));
								});
							}
						}
						// calls dataDescriptor.getChildren() for each parent in sequence
						// waiting until the children have been loaded
						dataDescriptor.loadChildrenForHierarchy(hierarchy, 0, callback);
					}
					
					// if the node to select is null, OR if the node was selected, then scroll
					// to the node and fire a change event
					if ((node == null) || (tree.selectedItem != null)) {
						selected = true;
						tree.dispatchEvent(new ListEvent(ListEvent.CHANGE));
						if (node != null) {
							tree.scrollToIndex(tree.getItemIndex(node));
						}
					}
				} else if (node != null) {
					tree.scrollToIndex(tree.getItemIndex(node));
				}
			}
			return selected;
		}
		
		/**
		 * Returns the parent hierarchy of TreeNodes.
		 * Doesn't include the given node.
		 * @param topDown if true then the root node will be first in the array, 
		 * 	otherwise the root will be last.
		 */
		private function getParentHierarchy(node:TreeNode, topDown:Boolean = false):Array {
			var hierarchy:Array = [];
			if (node) {
				var parent:TreeNode = node.parentTreeNode;
				while (parent) {
					if (topDown) {
						hierarchy.unshift(parent);	// add first
					} else {
						hierarchy.push(parent);		// add last
					}
					parent = parent.parentTreeNode;
				}
			}
			return hierarchy;
		}
		
		/**
		 * Expands the root nodes.
		 */
		public function expandRoots(animate:Boolean = false, fireEvent:Boolean = false):void {
			if (!ontology || !dataDescriptor.ontologyVersionID) {
				return;
			}
			
			var roots:ICollectionView = dataDescriptor.roots;
			if ((roots.length == 0) || ((roots.length == 1) && 
					(roots[0] == OntologyDataDescriptor.LOADING))) {
				var handler:Function = function(event:CollectionEvent):void {
					if (roots.length > 0) {
						for each (var obj:Object in roots) {
							tree.expandItem(obj, true, animate, fireEvent);
						}
					}
				};
				roots.addEventListener(CollectionEvent.COLLECTION_CHANGE, handler);
			} else {
				for each (var item:Object in roots) {
					tree.expandItem(item, true, animate, fireEvent);
				}
			}
		}
		
		/**
		 * Expands the root nodes.
		 */
		public function expandFirstRoot(animate:Boolean = false, fireEvent:Boolean = false):void {
			if (!ontology || !dataDescriptor.ontologyVersionID) {
				return;
			}
			
			var roots:ICollectionView = dataDescriptor.roots;
			if ((roots.length == 0) || ((roots.length == 1) && 
				(roots[0] == OntologyDataDescriptor.LOADING))) {
				var handler:Function = function(event:CollectionEvent):void {
					if (roots.length > 0) {
						tree.expandItem(roots[0], true, animate, fireEvent);
					}
				};
				roots.addEventListener(CollectionEvent.COLLECTION_CHANGE, handler);
			} else {
				tree.expandItem(roots[0], true, animate, fireEvent);
			}
		}
		
		public function conceptToNodes(concept:NCBOConcept):Array {
			return dataDescriptor.conceptToNodes(concept);
		}
		
		private function stopButtonClicked(event:Event):void {
			dataDescriptor.stopCurrentOperation();
			setBusy(false);
		}
		
		protected function forwardEvent(event:Event):void {
			dispatchEvent(event.clone());
		}
		
		protected function treeSelectionChanged(event:ListEvent):void {
			forwardEvent(event);
			
			if (canChangeRoot) {
				changeRootMenuItem.visible = (selectedNode && selectedNode.concept);
				changeRootMenuItem.enabled = changeRootMenuItem.visible && 
											 (selectedNode.concept != rootConcept);
			}
		}
		
		protected function treeDoubleClicked(event:MouseEvent):void {
			forwardEvent(event);
		}
		
		protected function treeNodeExpanded(event:TreeEvent):void {
			forwardEvent(event);
		}

		protected function treeNodeExpanding(event:TreeEvent):void {
			forwardEvent(event);
		}
		
		protected function treeNodeCollapsed(event:TreeEvent):void {
			forwardEvent(event);
		}
		
		private function changeTreeRootHandler(event:ContextMenuEvent):void {
			var treeNode:TreeNode = selectedNode;
			if (treeNode && treeNode.concept) {
				rootConcept = treeNode.concept;
				dispatchEvent(new TreeRootChangedEvent(TreeRootChangedEvent.TREE_ROOT_CHANGED, rootConcept));
			}
		}
		
		private function restoreTreeRootHandler(event:ContextMenuEvent):void {
			restoreTreeRoot();
		}
		
		private function restoreTreeRoot(nodeToSelect:TreeNode = null, pathToRoot:Array = null,
										 expand:Boolean = false, collapse:Boolean = false):void {
			if (rootConcept != null) {
				// fire the event before the concept is set to null
				dispatchEvent(new TreeRootChangedEvent(TreeRootChangedEvent.TREE_ROOT_RESTORED, rootConcept));
				// need to do the selection after the roots have finished loading
				if (nodeToSelect || pathToRoot) {
					var listener:Function = function(event:Event):void {
						dataDescriptor.removeEventListener(OntologyDataDescriptor.ROOTS_LOADED, listener);
						tree.validateNow();
						if (nodeToSelect) {
							selectNode(nodeToSelect);
						} else if (pathToRoot) {
							pathToRootLoaded(pathToRoot, expand, collapse);
						}
					};
					dataDescriptor.addEventListener(OntologyDataDescriptor.ROOTS_LOADED, listener);
				}
				rootConcept = null;
			}
		}
						
		public function setBusy(busy:Boolean):void {
			if (busy != busyComponent.visible) {
				tree.enabled = !busy;
				busyComponent.visible = busy;
				busySpinner.running = busy;
				if (busy) {
					// center horizontally at the top
					var cx:Number = (width - busyComponent.width) / 2;
					busyComponent.move(cx, tree.y + 10);
				}
			}
		}
		
		public function showTopBar():void {
			if (topBar.parent == null) {
				addChildAt(topBar, 0);
				resizeControls();
			}
		}
		
		public function hideTopBar():void {
			if (_topBar && (_topBar.parent == this)) {
				this.removeChild(_topBar);
				resizeControls();
			}
		}
		
		public function showSearchBar():void {
			if (searchBar.parent == null) {
				var index:int = 1;
				if (_topBar && (_topBar.parent == null)) {
					index = 0
				}
				addChildAt(searchBar, index);
				resizeControls();
			}
		}
		
		public function hideSearchBar():void {
			if (_searchBar && (_searchBar.parent == this)) {
				this.removeChild(_searchBar);
				resizeControls();
			}
		}
		
		public function showOpenButton():void {
			if (openButton.parent == null) {
				topBar.addChildAt(openButton, 1);
				resizeControls();
			}
		}
		
		public function hideOpenButton():void {
			if (_openButton && (_openButton.parent == topBar)) {
				topBar.removeChild(_openButton);
				resizeControls();
			}
		}
		
		private function resized(event:ResizeEvent):void {
			resizeControls();
		}
		
		protected function resizeControls():void {
			var topBarHeight:Number = 0;
			var searchBarY:Number = 0;
			var searchBarHeight:Number = 0;
			if (topBar.parent) {
				topBar.width = width;
				topBarHeight = topBar.height;
				searchBarY = topBar.y + topBarHeight;
			}
			if (searchBar.parent) {
				searchBar.y = searchBarY;
				searchBar.width = width;
				searchBarHeight = searchBar.height;
			}
			tree.y = searchBarY + searchBarHeight;
			tree.width = width;
			tree.height = height - searchBarHeight - searchBarY;
			
			if (topBar.parent) {
				var hGap:uint = topBar.getStyle("horizontalGap");
				var pLeft:uint = topBar.getStyle("paddingLeft");
				var pRight:uint = topBar.getStyle("paddingRight");
				var buttonWidths:Number = 0;
				for (var i:int = 0; i < topBar.numChildren; i++) {
					var child:DisplayObject = topBar.getChildAt(i);
					if (child != ontologyLink) {
						buttonWidths += child.width;
					}
				}
				var lblWidth:Number = Math.max(0, width - pLeft - pRight - buttonWidths - (topBar.numChildren * hGap));
				ontologyLink.width = lblWidth;
				ontologyLink.maxWidth = lblWidth;
			} 
		}
		
		private function changeIcons(isOWL:Boolean):void {
			tree.setStyle("folderClosedIcon", (isOWL ? CLASS_ICON : null));
			tree.setStyle("folderOpenIcon", (isOWL ? CLASS_ICON : null));
			tree.setStyle("defaultLeafIcon", (isOWL ? CLASS_ICON : null));
		}
		
		/**
		 * Loads the roots of the ontology tree IF they haven't been loaded already.
		 */
		public function loadRoots():void {
			tree.dataProvider = dataDescriptor.roots;
			tree.validateNow();
		}
		
		/**
		 * Loads and selects the first TreeNode for the concept id.
		 */
		public function loadConceptByID(conceptID:String):void {
			if (!dataDescriptor.rootsLoaded) {
				loadRoots();
			}
			setBusy(true);
			dataDescriptor.loadPathToRootByID(conceptID, pathToRootLoaded);
		}
		
		/**
		 * Loads and selects the first TreeNode for the concept by name.
		 */
		public function loadConceptByName(conceptName:String):void {
			if ((conceptName != null) && (StringUtil.trim(conceptName).length > 0)) {
				// save time - check if already selected
				if (selectedNode && StringUtils.equals(selectedNode.name, conceptName, true)) {
					return;
				}
				
				// now try to find a node that is already showing in the tree with the same name
				var node:TreeNode = dataDescriptor.findNodeByName(conceptName, true);
				if (node != null) {
					var selected:Boolean = selectNode(node);
					if (selected) {
						saveSearch(conceptName);
					} else if (rootConcept) {
						// couldn't select the concept - must be filtered out
						promptToRestoreRoot(node);
					}
					return;
				}
				
				if (!dataDescriptor.rootsLoaded) {
					loadRoots();
				}
				// now try to load it from the rest service
				setBusy(true);
				var wrapper:Function = function(pathToRoot:Array, expand:Boolean = false, collapse:Boolean = false):void {
					if (rootConcept && (pathToRoot.length > 0) && !isInPath(rootConcept.id, pathToRoot)) {
						// The root concept is not contained in the path to root - so we can't show this concept
						promptToRestoreRoot(null, pathToRoot, expand, collapse);
					} else {
						pathToRootLoaded(pathToRoot, expand, collapse);
					}
					if (pathToRoot.length > 0) {
						saveSearch(conceptName);
					}
				}
				dataDescriptor.loadPathToRootByName(conceptName, ontology, wrapper);
			}
		}
		
		/**
		 * Prompts the user to restore the original root(s).
		 */
		private function promptToRestoreRoot(node:TreeNode, pathToRoot:Array = null, 
											 expand:Boolean = false, collapse:Boolean = false):void {
			var alert:Alert;
			var msg:String = "The search term is not present\nin the subset of this ontology.";
			if (canChangeRoot) {
				msg += "\nDo you want to show the whole ontology?";
				var closeHandler:Function = function(event:CloseEvent):void {
					if (event.detail == Alert.YES) {
						restoreTreeRoot(node, pathToRoot, expand, collapse);
					} else {
						setBusy(false);
					}
				};
				alert = Alert.show(msg, "Show Entire Ontology", Alert.YES | Alert.NO, 
											 searchBar, closeHandler, null, Alert.YES);
			} else {
				alert = Alert.show(msg, "Error", Alert.OK, searchBar, null, null, Alert.OK);
				setBusy(false);
			}
			alert.addEventListener(FlexEvent.CREATION_COMPLETE, function(event:FlexEvent):void {
				alert.y += searchBar.height;	// position just below the search bar
			});
		}
		
		/**
		 * Loads and selects the first TreeNode the represents the concept.
		 * It can also expand or collapse the tree node after it has been loaded.
		 */
		public function loadConcept(concept:NCBOConcept, expand:Boolean = false, collapse:Boolean = false):void {
			if (selectedNode && (selectedNode.concept == concept)) {
				// already selected, don't bother loading
				if (expand) {
					tree.expandItem(selectedNode, true);
				} else if (collapse) {
					tree.expandItem(selectedNode, false);
				}
				return;
			}
			
			if (!dataDescriptor.rootsLoaded) {
				loadRoots();
			}
			setBusy(true);
			dataDescriptor.loadPathToRoot(concept, pathToRootLoaded, expand, collapse);
		}
		
		private function pathToRootLoaded(pathToRoot:Array, expand:Boolean = false, collapse:Boolean = false, 
										  allowRetry:Boolean = true):void {
			if (pathToRoot.length > 0) {
				// invert the path to root so that we can expand each node from the root down
				// not needed anymore - the new path to root service returns the path from root down
				//var inverted:Array = ArrayUtils.invert(pathToRoot);
				for (var i:int = 0; i < pathToRoot.length; i++) {
					var node:TreeNode = pathToRoot[i];
					// select the last concept
					if (i == (pathToRoot.length - 1)) {
						selectNode(node);
						if (expand) {
							tree.expandItem(node, true);
						} else if (collapse) {
							tree.expandItem(node, false);
						}
					} else {
						// Make sure the node is visible, otherwise it can't be expanded
						// this seems to happen when changing the root concept, or restoring it
						// allow one retry to wait for the next frame 
						var isVisible:Boolean = tree.isItemVisible(node);
						if (!isVisible && allowRetry) {
							callLater(pathToRootLoaded, [ pathToRoot, expand, collapse, false ]);
							return;
						}
						tree.expandItem(node, true);
					}
				}
			}
			setBusy(false);
		}
		
		private function isInPath(nodeID:String, path:Array):Boolean {
			for each (var node:TreeNode in path) {
				if (nodeID == node.id) {
					return true;
				}
			}
			return false;
		}
		
		/**
		 * Returns all the loaded TreeNodes in the tree with the given id.
		 */
		public function findTreeNodesByID(id:String):Array {
			return dataDescriptor.findNodesByID(id);
		}
		
		/**
		 * Finds all the loaded TreeNodes in the tree with the given name.
		 */
		public function findTreeNodesByName(name:String, ignoreCase:Boolean = true):Array {
			return dataDescriptor.findNodesByName(name, ignoreCase);
		}
		
//		/**
//		 * Returns the concepts that are loaded in the tree that have the given id.
//		 */
//		public function findConceptsByID(conceptID:String):Array {
//			var found:Array = findTreeNodesByID(conceptID);
//			// convert the TreeNodes into Concepts (what about duplicates?!?)
//			var concepts:Array = ArrayUtils.toArrayByProperty(found, "concept");
//			return found;
//		}
				
		private function jumpToConceptHandler(event:Event):void {
			var conceptName:String = StringUtil.trim(autoCompleteBox.text);
			jumpToConceptName(conceptName);
		}
		
		protected function jumpToConceptName(conceptName:String):void {
			if (conceptName.length > 0) {
				// cancel autocomplete search in progress
				autoCompleteBox.cancelAutoComplete();
				
				loadConceptByName(conceptName);
				dispatchEvent(new JumpToConceptEvent(conceptName));
			}
		}
				
		protected function saveSearch(txt:String):void {
			/*
			if (!previousSearches.contains(txt)) {
				previousSearches.addItem(txt);
				if (previousSearches.length > 10) {
					previousSearches.removeItemAt(0);
				}
			}
			*/	
		}	
		
		protected function initializeTreeContextMenu(menu:ContextMenu):void {
			menu.addEventListener(ContextMenuEvent.MENU_SELECT, function(event:ContextMenuEvent):void {
				// ensure that the tree node that was right clicked is selected
				if (event.mouseTarget is IDataRenderer) {
					var renderer:IDataRenderer = (event.mouseTarget as IDataRenderer);
					var treeNode:TreeNode = (renderer.data as TreeNode)
					if (treeNode && (treeNode != selectedNode)) {
						selectedNode = treeNode;
					}
				}
			});
			
			var collapseItem:ContextMenuItem = new ContextMenuItem("Collapse All", true);
			collapseItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, collapseTree);
			menu.customItems.push(collapseItem);
			
			// initialized in the constructor
			changeRootMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, changeTreeRootHandler);
			menu.customItems.push(changeRootMenuItem);
			restoreDefaultRootMenuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, restoreTreeRootHandler);
			menu.customItems.push(restoreDefaultRootMenuItem);
		}
		
		public function collapseTree(event:Event = null):void {
			if (dataDescriptor.rootsLoaded) {
				var roots:ICollectionView = dataDescriptor.roots;
				for (var i:int = 0; i < roots.length; i++) {
					var root:Object = roots[i];
					tree.expandChildrenOf(root, false);
					tree.expandItem(root, false);
				}
			}
		}
		
//		protected function chooseOntology(event:Event = null):void {
//			var me:OntologyTree = this;
//			service.getNCBOOntologies(function(event:NCBOOntologiesEvent):void {
//				if (event.ontologies.length > 0) {
//					var chooser:OntologyChooser = new OntologyChooser(service, ontology);
//					chooser.addEventListener(CloseEvent.CLOSE, function(event:CloseEvent):void {
//						PopUpManager.removePopUp(chooser);
//						if (event.detail == ContentWindow.OK) {
//							setNewOntology(chooser.selectedOntology);
//						}
//					});
//					PopUpManager.addPopUp(chooser, me, true);
//					PopUpManager.centerPopUp(chooser);
//					chooser.setFocus();
//				}
//			});
//		}
		
		protected function setNewOntology(newOntology:NCBOOntology):void {
			if ((newOntology != null) && ((ontology == null) || (newOntology.id != ontology.id))) {
				ontology = newOntology;
			}
		}
		
		/** Expands or collapses the tree node(s) for the given concept. */
		public function expandCollapseConcept(concept:NCBOConcept, expand:Boolean, load:Boolean = true):void {
			var treeNodes:Array = conceptToNodes(concept);
			if (treeNodes.length == 0) {
				if (load) {
					loadConcept(concept, expand, !expand);
				}
			} else {
				var animate:Boolean = (treeNodes.length == 1);
				for each (var treeNode:TreeNode in treeNodes) {
					tree.expandItem(treeNode, expand, animate);
				}
			}
		}
		
		private function conceptToolTip(item:Object):String {
			var tt:String = "";
			if (item is TreeNode) {
				var concept:NCBOConcept = (item as TreeNode).concept;
				if (concept.hasProperty(OntologyConstants.DEFINITION)) {
					var definition:String = concept.getStringProperty(OntologyConstants.DEFINITION);
					tt = definition;
				}
				if (!tt) {
					tt = concept.name;
				}
			}
			return tt;
		}
		
		public function get firstVisibleItemIndex():int {
			return (tree as CustomTree).firstVisibleItemIndex;
		}
			
	    public function getCustomItemIndex(item:Object, startIndex:int = 0):int {
	    	return (tree as CustomTree).getCustomItemIndex(item, startIndex);
	    }
	    
	    public function getItemIndex(item:Object):int {
	    	return tree.getItemIndex(item);
	    }
	    
	    public function indexToItemRenderer(index:int):IListItemRenderer {
	    	return tree.indexToItemRenderer(index);
	    }
	    
	    public function itemToItemRenderer(item:Object):IListItemRenderer {
	    	return tree.itemToItemRenderer(item);
	    }
	    
	}
}