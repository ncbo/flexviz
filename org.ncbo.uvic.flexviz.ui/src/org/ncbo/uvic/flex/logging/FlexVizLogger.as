package org.ncbo.uvic.flex.logging
{
	import ca.uvic.cs.chisel.flexviz.FlexGraph;
	import ca.uvic.cs.chisel.flexviz.events.ExportEvent;
	import ca.uvic.cs.chisel.flexviz.events.GraphArcLabelsEvent;
	import ca.uvic.cs.chisel.flexviz.events.GraphColorChangedEvent;
	import ca.uvic.cs.chisel.flexviz.events.GraphErrorEvent;
	import ca.uvic.cs.chisel.flexviz.events.GraphLayoutEvent;
	import ca.uvic.cs.chisel.flexviz.events.GraphSelectionModeChangedEvent;
	import ca.uvic.cs.chisel.flexviz.events.GraphZoomChangedEvent;
	import ca.uvic.cs.chisel.flexviz.events.GroupedNodesEvent;
	import ca.uvic.cs.chisel.flexviz.events.HideOrphansChangedEvent;
	import ca.uvic.cs.chisel.flexviz.events.NavigationEvent;
	import ca.uvic.cs.chisel.flexviz.events.SelectedNodesChangedEvent;
	import ca.uvic.cs.chisel.flexviz.filter.FilterChangedEvent;
	import ca.uvic.cs.chisel.flexviz.filter.TypeFilter;
	import ca.uvic.cs.chisel.flexviz.model.IGraphNode;
	import ca.uvic.cs.chisel.flexviz.util.ExportOptions;
	
	import flash.events.Event;
	
	import flex.utils.StringUtils;
	
	import mx.core.Application;
	import mx.events.FlexEvent;
	
	import org.ncbo.uvic.flex.events.NCBOToolTipChangedEvent;
	import org.ncbo.uvic.flex.events.NodeLabelFieldChangedEvent;
	import org.ncbo.uvic.flex.events.OntologyChangedEvent;
	import org.ncbo.uvic.flex.events.OntologyTreeVisibilityChanged;
	import org.ncbo.uvic.flex.model.NCBOConcept;
	import org.ncbo.uvic.flex.model.NCBOOntology;
	import org.ncbo.uvic.flex.search.NCBOSearchProvider;
	
	/**
	 * Adds event listeners onto the search provider and the graph for logging
	 * FlexViz specific events.
	 * 
	 * @author Chris Callendar
	 * @date May 20th, 2009
	 */
	public class FlexVizLogger
	{
		
		private static var wasLoggingConceptEvents:Boolean = false;

		private var provider:NCBOSearchProvider;
		private var selectedNodes:Object;
		
		public function FlexVizLogger(provider:NCBOSearchProvider):void {
			this.provider = provider;
			this.selectedNodes = new Object();
			
			LogService.restService = provider.service;
			
			// Graph events
			provider.graph.addEventListener(GraphLayoutEvent.GRAPH_LAYOUT_FINISHED, layoutFinished);
			provider.graph.addEventListener(GraphErrorEvent.ERROR, graphError);
			provider.graph.addEventListener(SelectedNodesChangedEvent.SELECTED_NODES_CHANGED, selectedNodesChanged);
			
			// Ontology events
			provider.addEventListener(OntologyChangedEvent.ONTOLOGY_CHANGED, ontologyChanged);
			provider.graph.addEventListener(OntologyTreeVisibilityChanged.ONTOLOGY_TREE_VISIBILITY_CHANGED, ontologyTreeChanged);
			
			Application.application.addEventListener(FlexEvent.APPLICATION_COMPLETE, appComplete);
		}
		
		private function appComplete(event:FlexEvent):void {
			// Graph events - don't add until app has loaded
			provider.graph.groupingManager.addEventListener(GroupedNodesEvent.NODES_GROUPED, nodesGrouped);
			provider.graph.groupingManager.addEventListener(GroupedNodesEvent.NODES_UNGROUPED, nodesGrouped);
			provider.graph.filterManager.addEventListener(FilterChangedEvent.FILTER_CHANGED, filtersChanged);
			provider.graph.addEventListener(FlexGraph.GRAPH_FIT_TO_SCREEN, fitToScreen);
			provider.graph.addEventListener(FlexGraph.GRAPH_EXPAND_NODES, fitToScreen);
			provider.graph.navigationManager.addEventListener(NavigationEvent.NAVIGATION_EVENT, navigationEvent);
			provider.graph.filterManager.addEventListener(HideOrphansChangedEvent.HIDE_ORPHANS_CHANGED, hideOrphans);
			provider.graph.addEventListener(GraphSelectionModeChangedEvent.GRAPH_SELECTION_MODE_CHANGED, selectionModeChanged);
			provider.graph.addEventListener(GraphZoomChangedEvent.GRAPH_ZOOM_CHANGED, zoomChanged);
			provider.graph.addEventListener(GraphArcLabelsEvent.GRAPH_ARC_LABELS, arcLabels);
			provider.graph.addEventListener(GraphColorChangedEvent.GRAPH_COLOR_CHANGED, colorChanged);
			provider.graph.addEventListener(FlexGraph.GRAPH_SHOW_HELP_PANEL, showHelpPanel);
			provider.graph.addEventListener(ExportEvent.GRAPH_EXPORT, graphExported);
			
			// Ontology events
			provider.graph.addEventListener(NCBOToolTipChangedEvent.ARC_TOOLTIP_CHANGED, arcToolTipsChanged);
			provider.graph.addEventListener(NCBOToolTipChangedEvent.NODE_TOOLTIP_CHANGED, nodeToolTipsChanged);
			provider.addEventListener(NodeLabelFieldChangedEvent.NODE_LABEL_FIELD_CHANGED, nodeLabelFieldChanged);
		}
		
		private function get versionID():String {
			return provider.ontologyVersionID;
		}
		
		private function get virtualID():String {
			return provider.ontologyVirtualID;
		}
		
		private function get visibleNodesCount():int {
			return provider.graph.model.visibleNodes.length;
		}
		
		private function ontologyChanged(event:OntologyChangedEvent):void {
			var ontology:NCBOOntology = provider.getOntology(event.versionID);
			if (ontology) {
				LogService.logOntologyEvent(ontology, "loaded");
			}
		}
		
		private function layoutFinished(event:GraphLayoutEvent):void {
			//trace("[FlexVizLogger] " + event.layout.name + " finished");
			LogService.logNavigationEvent(versionID, virtualID, "layout", event.layout.name, visibleNodesCount);
		}
		
		private function nodesGrouped(event:GroupedNodesEvent):void {
			var grouped:Boolean = (event.type == GroupedNodesEvent.NODES_GROUPED);
			var name:String = event.groupedNode.text;
			var nodes:int = event.groupedNode.groupedNodes.length;
			// chop off the " (2)" from the name since we are storing it in the number column
			var ending:String = " (" + nodes + ")";
			if (StringUtils.endsWith(name, ending)) {
				name = name.substr(0, name.length - ending.length);
			}
			//trace("[FlexVizLogger] nodesGrouped(" + name + ", " + nodes + ", " + grouped + ")"); 
			LogService.logNavigationEvent(versionID, virtualID, (grouped ? "grouped" : "ungrouped"), name, nodes); 
		}
		
		private function filtersChanged(event:FilterChangedEvent):void {
			if ((event.type == FilterChangedEvent.FILTER_CHANGED) && 
				(event.filter is TypeFilter) && (event.filterType != null)) {
				//trace("[FlexVizLogger] filter changed: " + event.filter.name);
				var filter:TypeFilter = TypeFilter(event.filter);
				var type:String = event.filterType;
				var on:Boolean = filter.isTypeVisible(type);
				LogService.logNavigationEvent(versionID, virtualID, filter.name, type, (on ? 1 : 0)); 
			}
		}
		
		private function graphError(event:GraphErrorEvent):void {
			LogService.logError(event.error);
		}
		
		private function selectedNodesChanged(event:SelectedNodesChangedEvent):void {
			var newMap:Object = {};
			var newSelection:Array = [];
			for each (var node:IGraphNode in event.selectedNodes) {
				if (!selectedNodes.hasOwnProperty(node.id)) {
					newSelection.push(node.id);
				}
				newMap[node.id] = true;
			}
			// limit the number of newly selected nodes?
			if (newSelection.length <= 4) {
				for each (var nodeID:String in newSelection) {
					var concept:NCBOConcept = provider.getConcept(nodeID);
					if (concept) {
						logSelection(concept, virtualID, true);
					}
				}
			} 
			
			// save this for next time so we don't add duplicate events
			selectedNodes = newMap;
		}

		private function selectionModeChanged(event:GraphSelectionModeChangedEvent):void {
			LogService.logNavigationEvent(versionID, virtualID, "selection mode", event.mode, 0);
		}
		
		private function zoomChanged(event:GraphZoomChangedEvent):void {
			if (event.oldScale != event.scale) {
				LogService.logNavigationEvent(versionID, virtualID, "zoom", "", event.scale);
			}
		}
		
		private function navigationEvent(event:NavigationEvent):void {
			var back:Boolean = (event.action == NavigationEvent.ACTION_BACK);
			var forward:Boolean = (event.action == NavigationEvent.ACTION_FORWARD);
			if (back || forward) {
				LogService.logNavigationEvent(versionID, virtualID, "history", "", (back ? -1 : 1));
			}
		}
		
		private function fitToScreen(event:Event):void {
			LogService.logNavigationEvent(versionID, virtualID, event.type, "", visibleNodesCount);
		}
		
		private function hideOrphans(event:HideOrphansChangedEvent):void {
			LogService.logNavigationEvent(versionID, virtualID, "hide orphans", "", (event.on ? 1 : 0));
		}
		
		private function arcLabels(event:GraphArcLabelsEvent):void {
			LogService.logNavigationEvent(versionID, virtualID, "arc labels", event.action, (event.on ? 1 : 0));
		}

		private function colorChanged(event:GraphColorChangedEvent):void {
			LogService.logNavigationEvent(versionID, virtualID, event.kind + " color changed", event.itemType, event.color);
		}

		private function ontologyTreeChanged(event:OntologyTreeVisibilityChanged):void {
			LogService.logNavigationEvent(versionID, virtualID, "ontology tree", "", (event.treeVisible ? 1 : 0));
		}
		
		private function arcToolTipsChanged(event:NCBOToolTipChangedEvent):void {
			LogService.logNavigationEvent(versionID, virtualID, "tooltips", "arcs");
		}

		private function nodeToolTipsChanged(event:NCBOToolTipChangedEvent):void {
			LogService.logNavigationEvent(versionID, virtualID, "tooltips", "nodes");
		}
		
		private function nodeLabelFieldChanged(event:NodeLabelFieldChangedEvent):void {
			LogService.logNavigationEvent(versionID, virtualID, "node label field", event.labelField);
		}
		
		private function showHelpPanel(event:Event):void {
			LogService.logNavigationEvent(versionID, virtualID, "help");
		}
		
		private function graphExported(event:ExportEvent):void {
			var options:ExportOptions = event.exportOptions;
			var format:String = options.contentType;	// text/xml, image/jpeg, image/png
			format = format.substr(format.indexOf("/") + 1);
			var str:String = format + "|" + options.filename;
			var num:int = 0;
			if (options.asURL) {
			 	str += "|" + options.emailTo;
			 	num = (options.asAttachment ? 2 : 1);
			}
			LogService.logNavigationEvent(versionID, virtualID, "export", str, num); 
		}
		
		
		public static function logSearchResult(concept:NCBOConcept, virtualID:String):void {
			LogService.logConceptEvent(concept, virtualID, "search result");
		}
		
		public static function logProperties(concept:NCBOConcept, virtualID:String):void {
			LogService.logConceptEvent(concept, virtualID, "properties");
		}

		public static function logLinkTo(concept:NCBOConcept, virtualID:String):void {
			LogService.logConceptEvent(concept, virtualID, "link to"); 
		}
		
		public static function logOntologyRoots(ontology:NCBOOntology):void {
			LogService.logOntologyEvent(ontology, "roots");
		}
		
		public static function logNeighbors(concept:NCBOConcept, virtualID:String, type:String):void {
			LogService.logConceptEvent(concept, virtualID, type);
		}
		
		public static function logExpandCollapse(concept:NCBOConcept, virtualID:String, expand:Boolean = true, fromGraph:Boolean = true):void {
			var type:String = (fromGraph ? "graph " : "tree ") + (expand ? "expand" : "collapse");
			LogService.logConceptEvent(concept, virtualID, type);			
		}
		
		public static function logSelection(concept:NCBOConcept, virtualID:String, fromGraph:Boolean = true):void {
			var type:String = (fromGraph ? "graph " : "tree ") + "selection";
			LogService.logConceptEvent(concept, virtualID, type);
		}
		
		public static function logTreeDoubleClick(concept:NCBOConcept, virtualID:String):void {
			LogService.logConceptEvent(concept, virtualID, "tree double click");
		}
		
		public static function logTreeLinkViews(linkViews:Boolean, versionID:String, virtualID:String):void {
			LogService.logNavigationEvent(versionID, virtualID, "tree link views", "", (linkViews ? 1 : 0));			
		}

		public static function logTreeSearch(searchText:String, versionID:String, virtualID:String = ""):void {
			LogService.logNavigationEvent(versionID, virtualID, "tree search", searchText, 0);
		}

		public static function logConceptEvents(log:Boolean):void {
			if (!log && LogService.LOG_CONCEPT) {
				wasLoggingConceptEvents = true;
				LogService.LOG_CONCEPT = false;
			} else if (log && wasLoggingConceptEvents) {
				LogService.LOG_CONCEPT = true;
				wasLoggingConceptEvents = false;
			}
		}
		
		public static function logOpenFullVersionEvent(versionID:String, virtualID:String = "", ontologyName:String = ""):void {
			LogService.logNavigationEvent(versionID, virtualID, "openFullFlexViz", ontologyName, 0);
		}
		
	}
}