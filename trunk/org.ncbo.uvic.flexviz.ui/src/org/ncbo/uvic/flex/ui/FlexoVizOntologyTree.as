package org.ncbo.uvic.flex.ui
{
	import ca.uvic.cs.chisel.flexviz.events.SelectedNodesChangedEvent;
	import ca.uvic.cs.chisel.flexviz.model.GroupedNode;
	import ca.uvic.cs.chisel.flexviz.model.IGraphNode;
	
	import flash.events.MouseEvent;
	
	import flex.utils.ui.UIUtils;
	
	import mx.controls.Button;
	import mx.events.ListEvent;
	import mx.events.TreeEvent;
	
	import org.ncbo.uvic.flex.events.ConceptsExpandCollapseEvent;
	import org.ncbo.uvic.flex.events.NCBOOntologyEvent;
	import org.ncbo.uvic.flex.events.OntologyChangedEvent;
	import org.ncbo.uvic.flex.logging.FlexVizLogger;
	import org.ncbo.uvic.flex.model.NCBOConcept;
	import org.ncbo.uvic.ontologytree.OntologyTree;
	import org.ncbo.uvic.ontologytree.TreeNode;
	import org.ncbo.uvic.ontologytree.events.TreeOntologyChangedEvent;

	/**
	 * FlexoViz version of the OntologyTree - links the two views, listens for 
	 * selection events, and connects the two search boxes.
	 * 
	 * @author Chris Callendar
	 * @date April 28th, 2009
	 */
	public class FlexoVizOntologyTree extends OntologyTree
	{
		
		[Embed(source="/assets/close.gif")]
		private static const CLOSE_ICON:Class;
		[Embed(source="/assets/link_views.gif")]
		private static const LINK_ICON:Class;
		
		private var flexoviz:FlexoVizComponent;
		
		private var linkViews:Boolean;
		
		public function FlexoVizOntologyTree() {
			super();
			linkViews = true;
			// don't clear the rest service cache, it is already handled by the search provider
			dataDescriptor.clearServiceCache = false;
		}
		
		override protected function createChildren():void {
			super.createChildren();
			
			topBar.addChild(UIUtils.createToggleIconButton(LINK_ICON, linkViewsClicked, 
				"Link the tree view and the visualization", true, 20, 20));
			topBar.addChild(UIUtils.createIconButton(CLOSE_ICON, closeOntologyTree, 
				"Hide the tree view", 20, 20));
		}
		
		override protected function saveSearch(txt:String):void {
			flexoviz.searchProvider.saveSearch(txt);
		}
		
		override protected function jumpToConceptName(conceptName:String):void {
			super.jumpToConceptName(conceptName);
			if (conceptName.length > 0) {
				FlexVizLogger.logTreeSearch(conceptName, dataDescriptor.ontologyVersionID, dataDescriptor.ontologyVirtualID);
			}
		}
		
		public function init(flexoviz:FlexoVizComponent):void {
			this.flexoviz = flexoviz;

			super.service = flexoviz.searchProvider.service; 
			// listen for when the ontology changes
			flexoviz.searchProvider.addEventListener(OntologyChangedEvent.ONTOLOGY_CHANGED, graphOntologyChanged);
			// listen for when the user selects a node in the graph
			flexoviz.addEventListener(SelectedNodesChangedEvent.SELECTED_NODES_CHANGED, graphSelectionChanged);
			
			// listen for expand/collapse events in the graph
			flexoviz.searchProvider.addEventListener(ConceptsExpandCollapseEvent.CONCEPTS_EXPANDED, graphNodeExpanded);
			flexoviz.searchProvider.addEventListener(ConceptsExpandCollapseEvent.CONCEPTS_COLLAPSED, graphNodeCollapsed);
			// listen for expand/collapse events in the tree
			// when we call tree.expandItem by default it doesn't fire these two events (no infinite loop)
			tree.addEventListener(TreeEvent.ITEM_OPEN, treeNodeExpanded);
			tree.addEventListener(TreeEvent.ITEM_CLOSE, treeNodeCollapsed);

			addEventListener(TreeOntologyChangedEvent.ONTOLOGY_CHANGED, treeOntologyChanged);

			// link the previous searches - not used anymore (autocomplete is done by searching now)
			//previousSearches = flexoviz.searchProvider.previousSearches;
			//jumpToChooser.dataProvider = previousSearches;
		}
		
		
		//////////////////////////////
		// FLEXVIZ GRAPH EVENTS
		//////////////////////////////
		
		private function graphOntologyChanged(event:OntologyChangedEvent):void {
			if (dataDescriptor.ontologyVersionID != event.versionID) {
				// set the ontology ID on the data descriptor first
				dataDescriptor.ontologyVersionID = event.versionID;
				dataDescriptor.ontologyVirtualID = event.virtualID;
				// now load the extra ontology information - but don't display any rest service errors?
				service.getNCBOOntology(event.versionID, ontologyLoaded, true, false);
			}
		}
		
		private function ontologyLoaded(event:NCBOOntologyEvent):void {
			if (event.isError) {
				trace("Error loading ontology: " + event.error);
			}
			ontology = event.ontology;
			if (event.ontology) {
				dataDescriptor.ontologyVirtualID = event.ontology.ontologyID;
			}
		}
		
		private function graphNodeExpanded(event:ConceptsExpandCollapseEvent):void {
			FlexVizLogger.logConceptEvents(false);
			expandCollapseTreeNode(event.concepts, true);
			FlexVizLogger.logConceptEvents(true);
		}

		private function graphNodeCollapsed(event:ConceptsExpandCollapseEvent):void {
			FlexVizLogger.logConceptEvents(false);
			expandCollapseTreeNode(event.concepts, false);
			FlexVizLogger.logConceptEvents(true);
		}
		
		private function graphSelectionChanged(event:SelectedNodesChangedEvent):void {
			if (linkViews && (tree.width >= 10) && tree.visible) {
				var graphNodes:Array = event.selectedNodes;
				// find the first non-grouped node in the list (recurses on grouped nodes)
				var graphNode:IGraphNode = getFirstNonGroupedNode(graphNodes);
				if (graphNode) {
					var selectedTreeNode:TreeNode = selectedNode;
					// Check if the node is already selected
					if (selectedTreeNode && (selectedTreeNode.id == graphNode.id)) {
						return;
					}
					
					var concept:NCBOConcept = flexoviz.searchProvider.getConcept(graphNode.id);
					// get the tree nodes - will be more than one if the concept has multiple parents 
					var nodes:Array = conceptToNodes(concept);
					if (nodes.length == 0) {
						loadConcept(concept);
					} else {
						FlexVizLogger.logConceptEvents(false); // skip the next log concept event from the tree selection
						// select the first node
						super.selectedNode = (nodes.length > 0 ? nodes[0] : null);
						FlexVizLogger.logConceptEvents(true);
					}
				} else {
					FlexVizLogger.logConceptEvents(false); // skip the next log concept event from the tree selection
					super.selectedNode = null;
					FlexVizLogger.logConceptEvents(true);					
				}
			}
		}
		
		//////////////////////////////
		// ONTOLOGY TREE EVENTS
		//////////////////////////////
		
		private function treeOntologyChanged(event:TreeOntologyChangedEvent):void {
			if (flexoviz.searchProvider.ontologyVersionID != event.ontology.ontologyVersionID) {
				flexoviz.loadOntology(event.ontology.ontologyVersionID);
			}
		}

		override protected function treeDoubleClicked(event:MouseEvent):void {
			super.treeDoubleClicked(event);
			
			var treeNode:TreeNode = super.selectedNode;
			if (treeNode) {
				FlexVizLogger.logTreeDoubleClick(treeNode.concept, dataDescriptor.ontologyVirtualID);
				FlexVizLogger.logConceptEvents(false); // skip the next log concept event from the graph
				if (!linkViews) {
					selectNodeInFlexViz(treeNode);
				}
				FlexVizLogger.logConceptEvents(true);
			}
		}
		
		override protected function treeSelectionChanged(event:ListEvent):void {
			super.treeSelectionChanged(event);
			
			var treeNode:TreeNode = super.selectedNode;
			if (treeNode) {
				FlexVizLogger.logSelection(treeNode.concept, dataDescriptor.ontologyVirtualID, false);
				FlexVizLogger.logConceptEvents(false); // skip the next log concept event from the graph
				if (linkViews) {
					selectNodeInFlexViz(treeNode);
				}
				FlexVizLogger.logConceptEvents(true);
			}
		}
		
		override protected function treeNodeExpanded(event:TreeEvent):void {
			super.treeNodeExpanded(event);
			
			var treeNode:TreeNode = TreeNode(event.item);
			FlexVizLogger.logExpandCollapse(treeNode.concept, dataDescriptor.ontologyVirtualID, true, false);
			FlexVizLogger.logConceptEvents(false); // skip the next log concept event from the graph
			expandCollapseGraphNode(treeNode, true);	
			FlexVizLogger.logConceptEvents(true);
		}
		
		override protected function treeNodeCollapsed(event:TreeEvent):void {
			super.treeNodeCollapsed(event);
			
			var treeNode:TreeNode = TreeNode(event.item);
			FlexVizLogger.logExpandCollapse(treeNode.concept, dataDescriptor.ontologyVirtualID, false, false);
			FlexVizLogger.logConceptEvents(false); // skip the next log concept event from the graph
			expandCollapseGraphNode(TreeNode(event.item), false);	
			FlexVizLogger.logConceptEvents(true);
		}
		
		private function linkViewsClicked(event:MouseEvent):void {
			linkViews = (event.currentTarget as Button).selected;
			FlexVizLogger.logTreeLinkViews(linkViews, dataDescriptor.ontologyVersionID, dataDescriptor.ontologyVirtualID);
			// copy the select from the graph to the tree (this is how Eclipse does it)
			var graphNode:IGraphNode = flexoviz.selectedNode;
			var nodes:Array = (graphNode ? [ graphNode ] : []);
			graphSelectionChanged(new SelectedNodesChangedEvent(nodes));
		}
		
		private function closeOntologyTree(event:MouseEvent):void {
			var flexovizApp:FlexoViz = (flexoviz.parent as FlexoViz);
			if (flexovizApp) {
				flexovizApp.hideOntologyTree();
			}
		}
		
		/////////////////////////
		// Helper functions
		/////////////////////////
		
		/**
		 * Passes the selection from the tree to FlexViz IF the node isn't already 
		 * selected.  It handles grouped nodes slightly differently - if the node is inside a grouped 
		 * node then it selects the grouped node instead (if it isn't already selected).
		 */
		private function selectNodeInFlexViz(treeNode:TreeNode):void {
			var grouped:Boolean = flexoviz.groupingManager.isGrouped(treeNode.id);
			if (grouped) {
				var groupedNode:GroupedNode = flexoviz.groupingManager.getGroupedNodeForNode(treeNode.id);
				if (groupedNode && !groupedNode.selected) {
					// select only this grouped node
					flexoviz.selectedNode = groupedNode;
				}
			} else {
				var selected:Boolean = flexoviz.isSelectedByID(treeNode.id);
				// select it (and only it) if the node isn't already selected
				if (!selected) {
					flexoviz.selectNodeByID(treeNode.id, false, true);
				}
			}
		}
		
		/**
		 * Expands or collapses one or more tree nodes for the given concepts.
		 * If multiple concepts are given, then only the tree nodes that are already in the
		 * tree are expanded.
		 * Note that when we call tree.expandItem() by default we aren't firing the
		 * tree open/close events and so there won't be an infinite loop.
		 */
		private function expandCollapseTreeNode(concepts:Array, expand:Boolean = true):void {
			if (linkViews && (tree.width >= 10) && tree.visible) {
				var concept:NCBOConcept;
				var treeNodes:Array;
				if (concepts.length == 1) {
					// load and expand the tree node
					concept = concepts[0];
					expandCollapseConcept(concept, expand, true);
				} else {
					// only expand the ones already in the tree
					for each (concept in concepts) {
						expandCollapseConcept(concept, expand, false); 
					}
				}
			}
		}
		
		/**
		 * Expands or collapses the concepts in the graph that match the tree node.
		 */
		private function expandCollapseGraphNode(treeNode:TreeNode, expand:Boolean):void {
			if (linkViews) {
				var node:IGraphNode = flexoviz.model.getNode(treeNode.id);
				//trace((expand ? "Expanding" : "Collapsing") + " graph neighborhood for " + node);
				if (node && node.visible) {
					flexoviz.searchProvider.toggleNeighborhood(node, expand, !expand);
				}
			}
		}
		
		/**
		 * Attemps to find the first non-grouped node in the array.
		 * If it doesn't find one in the array but it finds a GroupedNode then
		 * it recurses on those nodes.
		 */
		private function getFirstNonGroupedNode(nodes:Array):IGraphNode {
			var firstNode:IGraphNode = null;
			var groupedNode:GroupedNode = null;
			if (nodes && (nodes.length > 0)) {
				for each (var node:IGraphNode in nodes) {
					if (node is GroupedNode) {
						if (groupedNode == null) {
							groupedNode = GroupedNode(node);
						}
					} else {
						firstNode = node;
						break;
					}
				} 
				if ((firstNode == null) && (groupedNode != null)) {
					// check to see if the currently selected tree node is actually
					// part of this grouped node, in which case we don't want to continue
					// otherwise we'll always select the same node and confuse the user
					var found:Boolean = false;
					var treeNode:TreeNode = super.selectedNode;
					if (treeNode) {
						var foundNode:IGraphNode = groupedNode.getNode(treeNode.id);
						found = (foundNode != null);
					}
					// recurse on the grouped nodes
					if (!found) {
						firstNode = getFirstNonGroupedNode(groupedNode.groupedNodes);
					}
				}
			}
			return firstNode;
		}
		
	}
}