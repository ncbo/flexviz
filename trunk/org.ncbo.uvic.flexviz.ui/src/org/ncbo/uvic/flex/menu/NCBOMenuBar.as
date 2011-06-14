package org.ncbo.uvic.flex.menu
{
	import ca.uvic.cs.chisel.flexviz.ExtendedFlexGraph;
	import ca.uvic.cs.chisel.flexviz.IGraph;
	import ca.uvic.cs.chisel.flexviz.events.GraphArcLabelsEvent;
	import ca.uvic.cs.chisel.flexviz.events.SelectedNodesChangedEvent;
	import ca.uvic.cs.chisel.flexviz.layouts.Layouts;
	import ca.uvic.cs.chisel.flexviz.layouts.algorithms.ILayoutAlgorithm;
	
	import flash.display.DisplayObject;
	
	import flex.utils.ArrayUtils;
	import flex.utils.ui.menu.Menu;
	import flex.utils.ui.menu.MenuBar;
	import flex.utils.ui.menu.MenuItem;
	
	import mx.managers.PopUpManager;
	
	import org.ncbo.uvic.flex.NCBOToolTipProperties;
	import org.ncbo.uvic.flex.NCBOVersion;
	import org.ncbo.uvic.flex.Shared;
	import org.ncbo.uvic.flex.events.NCBOToolTipChangedEvent;
	import org.ncbo.uvic.flex.events.OntologyChangedEvent;
	import org.ncbo.uvic.flex.events.OntologyTreeVisibilityChanged;
	import org.ncbo.uvic.flex.model.NCBOOntology;
	import org.ncbo.uvic.flex.search.NCBOSearchProvider;
	import org.ncbo.uvic.flex.search.SearchShowOption;
	import org.ncbo.uvic.flex.ui.TooltipPropertyChooser;
	
	/**
	 * Extends ArrayCollection to hold NCBOMenuItem objects.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBOMenuBar extends flex.utils.ui.menu.MenuBar
	{
		
		[Embed(source='/assets/neighborhood.gif')]
      	private var neighborhoodIcon:Class;
		[Embed(source='/assets/hierarchy_to_root.gif')]
      	private var hierarchyIcon:Class;
		[Embed(source='/assets/parents.gif')]
      	private var parentsIcon:Class;
		[Embed(source='/assets/children.gif')]
      	private var childrenIcon:Class;
		[Embed(source='/assets/show_roots.png')]
      	private var rootsIcon:Class;
		[Embed(source='/assets/help.gif')]
      	private var helpIcon:Class;
		[Embed(source='/assets/error.gif')]
      	private var errorIcon:Class;
		[Embed(source='/assets/email.gif')]
      	private var emailIcon:Class;
		[Embed(source='/assets/bug.gif')]
      	private var bugIcon:Class;
		[Embed(source='/assets/group.png')]
      	private var groupIcon:Class;
		[Embed(source='/assets/tree.gif')]
      	private var treeIcon:Class;
      	[Embed(source='/assets/download.png')]
      	private var downloadIcon:Class;
      	[Embed(source='/assets/folder_table.png')]
      	private var openIcon:Class;
      	[Embed(source='/assets/table_gear.png')]
      	private var metricsIcon:Class;
      	[Embed(source='/assets/versions.png')]
      	private var versionsIcon:Class;
      	[Embed(source='/assets/folder_versions.png')]
      	private var folderVersionsIcon:Class;
		[Embed(source='/assets/export.gif')]
      	private var exportIcon:Class;
		
		private var graph:IGraph;
		private var searchProvider:NCBOSearchProvider;
		
		private var _ontologyMenu:Menu;
		private var _layoutsMenu:Menu;
		private var _nodesMenu:Menu;
		private var nodeShowMenu:Menu;
		private var nodeFocusMenu:Menu;
		private var nodeHideMenu:Menu;
		private var _arcsMenu:Menu;
		private var _helpMenu:Menu;		
		private var recentOntologiesMenu:Menu;
		
		private var groupItem:MenuItem;
		private var showArcLabelsItem:MenuItem;
		private var rotateArcLabelsItem:MenuItem;
		
		private var canChangeOntology:Boolean = true;
		
		public function NCBOMenuBar(canChangeOntology:Boolean = true) {
			super();
			this.canChangeOntology = canChangeOntology;
		}
		
		public function createMenus(graph:IGraph, searchProvider:NCBOSearchProvider):void {
			this.graph = graph;
			this.searchProvider = searchProvider;

			removeAll();
			
			// ONTOLOGY
			addMenu(ontologyMenu);
			
			// LAYOUTS
			addMenu(layoutsMenu);
			
			// NODES
			addMenu(nodesMenu);
			
			// ARCS
			addMenu(arcsMenu);
		
			// HELP
			addMenu(helpMenu);
			
			graph.addEventListener(SelectedNodesChangedEvent.SELECTED_NODES_CHANGED, selectedNodesChanged);
			graph.addEventListener(GraphArcLabelsEvent.GRAPH_ARC_LABELS, arcLabelsChanged);
			//graph.addEventListener(GraphLayoutEvent.LAYOUT_STARTING, layoutStarting);
			searchProvider.addEventListener(OntologyChangedEvent.ONTOLOGY_CHANGED, ontologyChanged);			
		}
		
		private function get ontologyMenu():Menu {
			if (_ontologyMenu == null) {
				_ontologyMenu = new Menu("Ontology");
				
				if (canChangeOntology) {
					var chooseOntologyItem:MenuItem = new MenuItem("Change ontology", openIcon, changeOntologyHandler);
					_ontologyMenu.addChild(chooseOntologyItem);

					var openVersionItem:MenuItem = new MenuItem("Change ontology version", 
																versionsIcon, changeOntologyVersion);
					openVersionItem.enabled = false;
					_ontologyMenu.addChild(openVersionItem);

					searchProvider.addEventListener(OntologyChangedEvent.ONTOLOGY_CHANGED, function(event:OntologyChangedEvent):void {
						openVersionItem.enabled = (searchProvider.ontologyID != null);
					});
				}
				
				var downloadItem:MenuItem = new MenuItem("Download Ontology", downloadIcon, downloadHandler);
				_ontologyMenu.addChild(downloadItem);
				
				var metricsItem:MenuItem = new MenuItem("Ontology Metrics", metricsIcon, metricsHandler);
				_ontologyMenu.addChild(metricsItem);

				// Recent ontologies
				recentOntologiesMenu = new Menu("Recent Ontologies", folderVersionsIcon);
				recentOntologiesMenu.enabled = false;
				_ontologyMenu.addChild(recentOntologiesMenu, true);
				loadRecentOntologies();

				var showRootsItem:MenuItem = new MenuItem("Show Roots", rootsIcon, showRootsHandler);
				_ontologyMenu.addChild(showRootsItem, true); 
				
				var showOntologyTreeItem:MenuItem = new MenuItem("Hide Ontology Tree", treeIcon, toggleOntologyTree);
				_ontologyMenu.addChild(showOntologyTreeItem);

				// no dependency on uvic servers
				//var exportGraphItem:MenuItem = new MenuItem("Export Graph", exportIcon, exportHandler);
				//_ontologyMenu.addChild(exportGraphItem);
				
				// listen for changes to the ontology tree visibility
				graph.addEventListener(OntologyTreeVisibilityChanged.ONTOLOGY_TREE_VISIBILITY_CHANGED, 
					function(event:OntologyTreeVisibilityChanged):void {
						showOntologyTreeItem.label = (event.treeVisible ? "Hide" : "Show") + " Ontology Tree";
						refresh();
					});
				
			}
			return _ontologyMenu;
		}
		
		private function get layoutsMenu():Menu {
			if (_layoutsMenu == null) {
				_layoutsMenu = new Menu("Layouts");
				var layouts:Array = Layouts.getInstance().layouts;
				for (var i:int = 0; i < layouts.length; i++) {
					var layout:ILayoutAlgorithm = ILayoutAlgorithm(layouts[i]);
					var layoutItem:MenuItem = new MenuItem(layout.name, layout.icon, layoutItemClicked);
					_layoutsMenu.addChild(layoutItem); 
				}
			}
			return _layoutsMenu;
		}
		
		private function get nodesMenu():Menu {
			if (_nodesMenu == null) {
				_nodesMenu = new Menu("Nodes");
				
				groupItem = new MenuItem("Group Subgraph", groupIcon, groupSubgraph);
				_nodesMenu.addChild(groupItem);
				
				// these menus are enabled based on node selection
				nodeFocusMenu = new Menu("Focus On...");
				nodeFocusMenu.enabled = false;	
				nodeFocusMenu.addChild(new MenuItem("Neighborhood of the selected node(s)", neighborhoodIcon, focusOnNeighborhood));
				nodeFocusMenu.addChild(new MenuItem("Hierarchy to root of the selected node(s)", hierarchyIcon, focusOnHierarchyToRoot));
				_nodesMenu.addChild(nodeFocusMenu, true);
				
				nodeShowMenu = new Menu("Show...");
				nodeShowMenu.enabled = false;
				nodeShowMenu.addChild(new MenuItem("Neighborhood of the selected node(s)", neighborhoodIcon, showNeighborhood));
				nodeShowMenu.addChild(new MenuItem("Hierarchy to root of the selected node(s)", hierarchyIcon, showHierarchyToRoot));
				nodeShowMenu.addChild(new MenuItem("Parent(s) of the selected node(s)", parentsIcon, showParents));
				nodeShowMenu.addChild(new MenuItem("Children of the selected node(s)", childrenIcon, showChildren));
				_nodesMenu.addChild(nodeShowMenu);
				
				nodeHideMenu = new Menu("Hide...");
				nodeHideMenu.enabled = false;
				nodeHideMenu.addChild(new MenuItem("Selected node(s)", null, removeSelectedNodes));
				nodeHideMenu.addChild(new MenuItem("Parent(s) of the selected node(s)", parentsIcon, removeParents));
				nodeHideMenu.addChild(new MenuItem("Children of the selected node(s)", childrenIcon, removeChildren));
				_nodesMenu.addChild(nodeHideMenu);
				
				_nodesMenu.addChild(MenuItem.SEPARATOR);
				
				_nodesMenu.addChild(new MenuItem("Configure Node Tooltips", null, configureNodeTooltips));
				_nodesMenu.addChild(new MenuItem("Configure Node Labels", null, configureNodeLabels));
				
				var flexoviz:FlexoVizComponent = FlexoVizComponent(graph);
				var showNodeProperties:MenuItem = new MenuItem("Show Node Properties", null, 
					function(item:MenuItem):void {
						flexoviz.showProperties = !flexoviz.showProperties;
					}, MenuItem.TYPE_CHECK);
				showNodeProperties.selected = flexoviz.showProperties;
				_nodesMenu.addChild(showNodeProperties);
			}
			return _nodesMenu;
		}
		
		private function get arcsMenu():Menu {
			if (_arcsMenu == null) {
				_arcsMenu = new Menu("Arcs");

				showArcLabelsItem = new MenuItem("Arc Labels", null, function(item:MenuItem):void {
					graph.showArcLabels = !graph.showArcLabels;
				}, MenuItem.TYPE_CHECK);
				showArcLabelsItem.selected = graph.showArcLabels;
				_arcsMenu.addChild(showArcLabelsItem);

				rotateArcLabelsItem = new MenuItem("Rotate Labels", null, function(item:MenuItem):void {
					graph.rotateArcLabels = !graph.rotateArcLabels;
				}, MenuItem.TYPE_CHECK);
				rotateArcLabelsItem.selected = graph.rotateArcLabels;
				rotateArcLabelsItem.enabled = graph.showArcLabels;
				_arcsMenu.addChild(rotateArcLabelsItem);
				
				_arcsMenu.addChild(new MenuItem("Configure Arc Tooltips", null, configureArcTooltips));
			}
			return _arcsMenu;
		} 
		
		private function get helpMenu():Menu {
			if (_helpMenu == null) {
				_helpMenu = new Menu("Help");
				var helpItem:MenuItem = new MenuItem("Show/Hide Help", helpIcon, showHideHelp);
				_helpMenu.addChild(helpItem);
				var errorItem:MenuItem = new MenuItem("Show/Hide Errors", errorIcon, showHideErrors);
				_helpMenu.addChild(errorItem);
				var emailItem:MenuItem = new MenuItem("Send us an email", emailIcon, emailHandler);
				_helpMenu.addChild(emailItem);
				var bugItem:MenuItem = new MenuItem("Submit a bug report", bugIcon, bugHandler);
				_helpMenu.addChild(bugItem);
				var historyItem:MenuItem = new MenuItem("Version History", null, historyHandler);
				_helpMenu.addChild(historyItem, true);
				
				if (graph.DEBUG) {
					var debugItem:MenuItem = new MenuItem("Show Debug Window", null, function(item:MenuItem):void {
						searchProvider.showDebugPanel();
					});
					_helpMenu.addChild(debugItem, true);
				}
			}
			return _helpMenu;
		} 
		
		
		///////////////////////////
		// Graph Event Handlers
		///////////////////////////
		
		public function selectedNodesChanged(event:SelectedNodesChangedEvent):void {
			var enabled:Boolean = (event.selectedNodes.length > 0);
			nodeFocusMenu.enabled = enabled;
			nodeShowMenu.enabled = enabled;
			nodeHideMenu.enabled = enabled;
			groupItem.enabled = (event.selectedNodes.length == 1);
			refresh();
		}
		
		public function arcLabelsChanged(event:GraphArcLabelsEvent):void {
			showArcLabelsItem.selected = graph.showArcLabels;
			rotateArcLabelsItem.selected = graph.rotateArcLabels;
			rotateArcLabelsItem.enabled = graph.showArcLabels;
			refresh();
		}
		
		public function layoutItemClicked(item:MenuItem):void {
			var layout:ILayoutAlgorithm = Layouts.getInstance().getLayout(item.label);
			if (layout != null) {
				graph.runLayout(layout);
			}
		}
		
		private function groupSubgraph(item:MenuItem):void {
			searchProvider.groupSubgraph(graph.selectedNode, false, true);
		}
				
		private function focusOnNeighborhood(item:MenuItem):void {
			searchProvider.showNeighborsOfSelected(SearchShowOption.NEIGHBORHOOD, true);
		}
		
		private function focusOnHierarchyToRoot(item:MenuItem):void {
			searchProvider.showNeighborsOfSelected(SearchShowOption.HIERARCHY_TO_ROOT, true);			
		}
		
		private function showNeighborhood(item:MenuItem):void {
			searchProvider.showNeighborsOfSelected(SearchShowOption.NEIGHBORHOOD, false);
		}
		
		private function showHierarchyToRoot(item:MenuItem):void {
			searchProvider.showNeighborsOfSelected(SearchShowOption.HIERARCHY_TO_ROOT, false);
		}
		
		private function showParents(item:MenuItem):void {
			searchProvider.showNeighborsOfSelected(SearchShowOption.PARENTS, false);
		}
		
		private function showChildren(item:MenuItem):void {
			searchProvider.showNeighborsOfSelected(SearchShowOption.CHILDREN, false);			
		}
		
		private function removeSelectedNodes(item:MenuItem):void {
			searchProvider.removeSelected();
		}
		
		private function removeParents(item:MenuItem):void {
			searchProvider.removeParentsOfSelected();
		}
		
		private function removeChildren(item:MenuItem):void {
			searchProvider.removeChildrenOfSelected();
		}
		
		private function configureNodeLabels(item:MenuItem):void {
			searchProvider.chooseLabelField();
		}
		
		private function configureNodeTooltips(item:MenuItem):void {
			var props:NCBOToolTipProperties = NCBOToolTipProperties.getInstance();
			var hiddenProps:Array = props.hiddenNodeProperties;
			var defProps:Array = props.defaultHiddenNodeProperties;
			
			// load all the available tooltip properties from cached concepts in the ontology
			var allProps:Array = new Array();
			var ontology:NCBOOntology = searchProvider.getOntology();
			if (ontology != null) {
				allProps = ontology.collectConceptProperties();
				// add the predefined properties to the front of the array
				allProps.unshift(NCBOToolTipProperties.PARENT_COUNT);
				allProps.unshift(NCBOToolTipProperties.CHILD_COUNT);
				allProps.unshift(NCBOToolTipProperties.TYPE);
				allProps.unshift(NCBOToolTipProperties.NAME);
				allProps.unshift(NCBOToolTipProperties.ID);
			}
			
			var title:String = "Node Tooltip Properties";
			var msg:String = "Choose which properties you want to display in node tooltips:";
			var tooltipChooser:TooltipPropertyChooser = new TooltipPropertyChooser(title, msg, allProps, hiddenProps, defProps);
			
			// this gets called after the window closes
			tooltipChooser.closeFunction = function(okClicked:Boolean = false):void {
				var unselectedProps:Array = tooltipChooser.unselectedPropertyNames;
				if (okClicked && !ArrayUtils.equals(hiddenProps, unselectedProps)) {
					// update which tooltips are shown/hidden
					allProps.forEach(function(item:String, i:int, a:Array):void {
						props.setNodePropertyHidden(item, ArrayUtils.contains(unselectedProps, item));
					});
					graph.dispatchEvent(new NCBOToolTipChangedEvent(NCBOToolTipChangedEvent.NODE_TOOLTIP_CHANGED, props));
				}
				PopUpManager.removePopUp(tooltipChooser);
			}
			
			PopUpManager.addPopUp(tooltipChooser, DisplayObject(graph), true);
			PopUpManager.centerPopUp(tooltipChooser);
		}
		
		private function configureArcTooltips(item:MenuItem):void {
			var props:NCBOToolTipProperties = NCBOToolTipProperties.getInstance();
			var hiddenProps:Array = props.hiddenArcProperties;
			var defProps:Array = props.defaultHiddenArcProperties;
			var allProps:Array = props.allArcProperties;
			
			var title:String = "Arc Tooltip Properties";
			var msg:String = "Choose which properties you want to display in arc tooltips:";
			var tooltipChooser:TooltipPropertyChooser = new TooltipPropertyChooser(title, msg, allProps, hiddenProps, defProps);
			
			// this function is called after the tooltip chooser window closes
			tooltipChooser.closeFunction = function(okClicked:Boolean = false):void {
				var unselectedProps:Array = tooltipChooser.unselectedPropertyNames;
				if (okClicked && !ArrayUtils.equals(hiddenProps, unselectedProps)) {
					// update which tooltips are shown/hidden
					allProps.forEach(function(item:String, i:int, a:Array):void {
						props.setArcPropertyHidden(item, ArrayUtils.contains(unselectedProps, item));
					});
					graph.dispatchEvent(new NCBOToolTipChangedEvent(NCBOToolTipChangedEvent.ARC_TOOLTIP_CHANGED, props));
				}
				PopUpManager.removePopUp(tooltipChooser);
			}
			PopUpManager.addPopUp(tooltipChooser, DisplayObject(graph), true);
			PopUpManager.centerPopUp(tooltipChooser);
		}
		
		private function showHideHelp(item:MenuItem):void {
			if (graph is ExtendedFlexGraph) {
				ExtendedFlexGraph(graph).showHideHelpPanel(null);
			}
		}
		
		private function showHideErrors(item:MenuItem):void {
			if (graph is ExtendedFlexGraph) {
				ExtendedFlexGraph(graph).showHideErrorPane();
			}
		}
		
		private function emailHandler(item:MenuItem):void {
			graph.emailHandler(null);
		}
		
		private function bugHandler(item:MenuItem):void {
			graph.bugHandler(null);
		}
		
		private function historyHandler(item:MenuItem):void {
			NCBOVersion.openHistoryWindow();
		}
		
		private function showRootsHandler(item:MenuItem):void {
			searchProvider.showRoots();
		}
		
		private function changeOntologyHandler(item:MenuItem):void {
			searchProvider.chooseOntology();
		}
		
		private function changeOntologyVersion(item:MenuItem):void {
			searchProvider.chooseOntologyVersion();
		}
		
		private function toggleOntologyTree(item:MenuItem):void {
			var app:FlexoViz = (graph.parent as FlexoViz);
			if (app) {
				if (app.ontologyTreeShowing) {
					item.label = "Hide Ontology Tree";
					app.hideOntologyTree();
				} else {
					item.label = "Show Ontology Tree";
					app.showOntologyTree();
				}
			}
		}
		
		private function downloadHandler(item:MenuItem):void {
			searchProvider.downloadOntology();
		}
		
		private function metricsHandler(item:MenuItem):void {
			searchProvider.showOntologyMetrics();
		}
		
		private function exportHandler(item:MenuItem):void {
			ExtendedFlexGraph(searchProvider.graph).showExportWindow();
		}
		
		public function loadRecentOntologies():void {
			var recent:Array = Shared.loadRecentOntologies();
			if (recent.length > 0) {
				recentOntologiesMenu.enabled = true;
				recentOntologiesMenu.removeAllChildren();
				for each (var ontology:Object in recent) {
					var item:MenuItem = new MenuItem(ontology.name, null, loadRecentOntologyHandler);
					item.data = ontology;
					recentOntologiesMenu.addChild(item);
				}
			} else {
				recentOntologiesMenu.enabled = false;
			}
			refresh();
		}
		
		private function loadRecentOntologyHandler(item:MenuItem):void {
			var ontology:Object = item.data;
			var id:String = ontology.id;
			searchProvider.changeOntology(id); 
		}
		
		private function ontologyChanged(event:OntologyChangedEvent):void {
			loadRecentOntologies();
		}
		
	}
}