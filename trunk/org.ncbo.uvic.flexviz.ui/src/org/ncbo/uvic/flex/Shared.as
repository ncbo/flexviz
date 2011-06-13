package org.ncbo.uvic.flex
{
	import ca.uvic.cs.chisel.flexviz.FlexGraph;
	import ca.uvic.cs.chisel.flexviz.layouts.Layouts;
	import ca.uvic.cs.chisel.flexviz.model.DefaultGraphModel;
	import ca.uvic.cs.chisel.flexviz.model.IGraphNode;
	
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	
	import org.ncbo.uvic.flex.model.NCBOOntology;
	import org.ncbo.uvic.flex.search.NCBOSearchProvider;
	import org.ncbo.uvic.flex.search.SearchBy;
	import org.ncbo.uvic.flex.search.SearchShowOption;
	
	/**
	 * Utility class for working with SharedObjects.
	 * 
	 * @author Chris Callendar
	 */
	public class Shared
	{
		
		private static const NAME:String = "flexoviz_cache";
		
		private static const SEARCH_SHOW_OPTION:String 	= "searchShowOption";
		private static const ONTOLOGY_ID:String 		= "ontologyID";
		private static const LAST_ONTOLOGY_ID:String 	= "lastOntologyID";
		private static const PREVIOUS_SEARCHES:String 	= "previousSearches_";
		private static const RECENT_ONTOLOGIES:String 	= "recentOntologies";
		
		private static function loadSharedObject():SharedObject {
			SharedObject.defaultObjectEncoding = ObjectEncoding.AMF3;
			var shared:SharedObject = SharedObject.getLocal(NAME, "/");
			return shared;		
		}
		
		public static function saveSearchShowOption(option:SearchShowOption):void {
			var shared:SharedObject = loadSharedObject();
			if ((shared != null) && (shared.data != null)) {
				shared.data[SEARCH_SHOW_OPTION] = option.name;
				shared.flush();
			}
		}
		
		public static function loadSearchShowOption():SearchShowOption {
			var option:SearchShowOption = null;
			var shared:SharedObject = loadSharedObject();
			if ((shared != null) && (shared.data != null)) {
				var has:Boolean = shared.data.hasOwnProperty(SEARCH_SHOW_OPTION); 
				if (has && (shared.data[SEARCH_SHOW_OPTION] != null)) {
					var str:String = (shared.data[SEARCH_SHOW_OPTION] as String);
					option = SearchShowOption.parse(str);
				}
			}
			return option;
		}
		
		public static function saveLastOntologyID(ontologyID:String):void {
			var shared:SharedObject = loadSharedObject();
			if ((shared != null) && (shared.data != null)) {
				var hasID:Boolean = shared.data.hasOwnProperty(LAST_ONTOLOGY_ID); 
				if (!hasID || (hasID && (shared.data[LAST_ONTOLOGY_ID] != ontologyID))) {
					shared.data[LAST_ONTOLOGY_ID] = ontologyID;
					shared.flush();					
				}
			}
		}
		
		public static function loadLastOntologyID():String {
			var ontologyID:String = null;
			var shared:SharedObject = loadSharedObject();
			if ((shared != null) && (shared.data != null)) {
				var hasID:Boolean = shared.data.hasOwnProperty(LAST_ONTOLOGY_ID); 
				if (hasID && (shared.data[LAST_ONTOLOGY_ID] != null)) {
					ontologyID = String(shared.data[LAST_ONTOLOGY_ID]);
				}
			}
			return ontologyID;
		}
		
		public static function savePreviousSearches(previousSearches:Array, ontologyID:String):void {
			var shared:SharedObject = loadSharedObject();
			if ((shared != null) && (shared.data != null) && (ontologyID != null)) {
				var key:String = PREVIOUS_SEARCHES + ontologyID;
				shared.data[key] = previousSearches;
				shared.flush();
				//trace("Saved previous searches: " + previousSearches.join(","));
			}
		}
		
		public static function loadPreviousSearches(ontologyID:String):Array {
			var searches:Array = [];
			var shared:SharedObject = loadSharedObject();
			if ((shared != null) && (shared.data != null) && (ontologyID != null)) {
				var key:String = PREVIOUS_SEARCHES + ontologyID;
				if (shared.data.hasOwnProperty(key)) {
					searches = (shared.data[key] as Array); 
				}
			}
			//trace("Loaded " + searches.length + " previous searches for " + ontologyID + ": " + searches.join(","));
			return (searches ? searches : []);
		}


		public static function loadRecentOntologies():Array {
			var recent:Array = [];
			var shared:SharedObject = loadSharedObject();
			if ((shared != null) && (shared.data != null)) {
				var key:String = RECENT_ONTOLOGIES;
				if (shared.data.hasOwnProperty(key)) {
					recent = (shared.data[key] as Array); 
				}
			}
			return (recent ? recent : []);
		}
				
		public static function addRecentOntology(ontology:NCBOOntology):void {
			var shared:SharedObject = loadSharedObject();
			if (ontology && shared && (shared.data != null)) {
				var recent:Array = loadRecentOntologies();
				// check if this ontology exists, if so move it first
				var index:int = -1;
				for (var i:int = 0; i < recent.length; i++) {
					var ont:Object = recent[i];
					if (ont.id == ontology.id) {
						index = i;
						break;
					}
				}
				if (index != -1) {
					recent.splice(index, 1);
				}
				var simple:Object = { id: ontology.id, name: ontology.nameAndAbbreviation, ontologyID: ontology.ontologyID };
				recent.unshift(simple);
				// delete extras
				const max:uint = 10;
				if (recent.length > max) {
					recent.splice(max, recent.length - max);
				} 
				
				var key:String = RECENT_ONTOLOGIES;
				shared.data[key] = recent;
				shared.flush();
				//trace("Saved recent ontogies: " + recent.length);
			}
		}
		
		public static function saveSharedGraph(graph:FlexGraph, searchProvider:NCBOSearchProvider, lastNodeID:String):void {
			if (searchProvider.ontologyID != null) {
				var shared:SharedObject = loadSharedObject();

				// NCBO parameters
				shared.data[ONTOLOGY_ID] = searchProvider.ontologyID;
				// save as another property - this one won't be deleted
				if (searchProvider.ontologyID != null) {
					shared.data[LAST_ONTOLOGY_ID] = searchProvider.ontologyID;
				}
				
				shared.data.nodeID		= lastNodeID;
				// these three properties don't need to be copied to the full version
				//shared.data.searchBy 	= searchProvider.searchBy.toString();
				//shared.data.searchMode  = searchProvider.searchMode.toString();
				//shared.data.showOption  = searchProvider.showOption.toString();
				shared.data.baseServerURL = searchProvider.baseServerURL;
				shared.data.baseTitle 	= searchProvider.baseTitle;

				// generic graph parameters
				shared.data.layout = graph.layout.name;
				shared.data.arcLabels = graph.showArcLabels.toString();
				shared.data.rotateLabels = graph.rotateArcLabels.toString();
				
				// save node and arc type filter state? 
				//this.filterManager.nodeTypeFilter.hiddenTypes
				//this.filterManager.arcTypeFilter.hiddenTypes
				
				// save the graph to xml - saves the selected nodes and arcs, node positions
				var xml:XML = graph.exportToXML();
				shared.data.graphXML = xml;
				
				// save the cache - might have to set a max number of cached items?
				var ontology:NCBOOntology = searchProvider.getOntology();
				var cache:XML = ontology.exportToXML();
				shared.data.cacheXML = cache;
				
				// save to disk
				shared.flush();
			}
		}
		
		public static function loadSharedGraph(graph:FlexGraph, searchProvider:NCBOSearchProvider):Boolean {
			var loaded:Boolean = false;
			var shared:SharedObject = loadSharedObject();
			if ((shared != null) && (shared.data != null)) {
				// try to find the last loaded ontology, this parameter is NOT deleted
				if (shared.data.hasOwnProperty(LAST_ONTOLOGY_ID)) {
					searchProvider.lastOntologyID = String(shared.data.lastOntologyID); 
				}
				
				// now try to load the ontology that BasicFlexoViz defined
				var ontologyID:String = null;
				var ontology:NCBOOntology = null;
				if (shared.data.hasOwnProperty(ONTOLOGY_ID)) {
					ontologyID = (shared.data.ontologyID as String);
					searchProvider.ontologyID = ontologyID;
					ontology = searchProvider.getOntology();
				}
				if (ontology != null) {
					//trace("Loaded Ontology from cache: " + ontologyID);
					
					var nodeID:String = (shared.data.nodeID as String);
					// these three properties are no longer saved
					//searchProvider.searchBy = SearchBy.parse(String(shared.data.searchBy));
					//searchProvider.searchMode = SearchMode.parse(String(shared.data.searchMode));
					//searchProvider.showOption = SearchShowOption.parse(String(shared.data.showOption));
					searchProvider.baseServerURL = (shared.data.baseServerURL as String);
					searchProvider.baseTitle = (shared.data.baseTitle as String);
					
					// set the graph layout
					var layoutName:String = String(shared.data.layout);
					graph.layout = Layouts.getInstance().getLayout(layoutName);
					
					// keep the arc labels consisten
					graph.showArcLabels = ("true" == shared.data.arcLabels);
					graph.rotateArcLabels = ("true" == shared.data.rotateLabels);

					// load the cache from xml (do this before we load the graph model)
					var cacheXML:XML = XML(shared.data.cacheXML);
					ontology.importFromXML(cacheXML);
					
					// clear the graph first
					graph.model = new DefaultGraphModel();
					// load the graph to xml - loads the selected nodes and arcs, node positions
					var xml:XML = XML(shared.data.graphXML);
					graph.importFromXML(xml);
					
					// make sure that the focussed node is showing
					var matchingNodes:Array = graph.matchingNodes;
					if ((searchProvider.searchBy == SearchBy.ID) && (nodeID.length > 0)) {
						if (graph.model.containsNodeByID(nodeID)) {
							graph.centerOnNode(graph.model.getNode(nodeID));
						}
					// otherwise center on the first matching node
					} else if (matchingNodes.length > 0) {
						graph.centerOnNode(IGraphNode(matchingNodes[0]));
					}
					
					// set the ontology name on the graph's watermark label
					searchProvider.loadOntologyName();

					loaded = true;
				}
				
				// clear the cache and save to disk?
				// if we delete this, then if the page is reloaded/refreshed, we won't know which ontology to load
				// and so we will have to prompt the user to choose an ontology
				delete shared.data.ontologyID;
				// do NOT delete the lastOntologyID parameter
				delete shared.data.nodeID;
				delete shared.data.searchBy;
				delete shared.data.searchMode;
				delete shared.data.showOption;
				delete shared.data.layout;
				delete shared.data.cacheXML;
				delete shared.data.graphXML;
				shared.flush();
			}
				
			return loaded;
		}
		

	}
}