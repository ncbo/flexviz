package org.ncbo.uvic.ontologytree
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import flex.utils.ArrayUtils;
	import flex.utils.StringUtils;
	import flex.utils.ui.ContentWindow;
	import flex.utils.ui.UIUtils;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ICollectionView;
	import mx.collections.IViewCursor;
	import mx.controls.Alert;
	import mx.controls.treeClasses.HierarchicalCollectionView;
	import mx.controls.treeClasses.HierarchicalViewCursor;
	import mx.controls.treeClasses.ITreeDataDescriptor2;
	import mx.core.Application;
	import mx.events.CloseEvent;
	import mx.events.CollectionEvent;
	
	import org.ncbo.uvic.flex.IRestService;
	import org.ncbo.uvic.flex.events.NCBOConceptEvent;
	import org.ncbo.uvic.flex.events.NCBOConceptsEvent;
	import org.ncbo.uvic.flex.events.NCBOOperationEvent;
	import org.ncbo.uvic.flex.events.NCBOOperationStartingEvent;
	import org.ncbo.uvic.flex.events.NCBOPathToRootEvent;
	import org.ncbo.uvic.flex.events.NCBOSearchEvent;
	import org.ncbo.uvic.flex.model.NCBOConcept;
	import org.ncbo.uvic.flex.model.NCBOOntology;
	import org.ncbo.uvic.flex.model.NCBOSearchResultConcept;
	import org.ncbo.uvic.flex.search.IRestServiceOperation;
	import org.ncbo.uvic.flex.search.LoadChildrenOperation;
	import org.ncbo.uvic.flex.search.SearchMode;
	import org.ncbo.uvic.flex.ui.SearchResultsPanel;

	[Event(name="rootsLoaded", type="flash.events.Event")]

	public class OntologyDataDescriptor extends EventDispatcher implements ITreeDataDescriptor2
	{
		
		public static const ROOTS_LOADED:String = "rootsLoaded";
		public static const LOADING:TreeNode = new TreeNode(new NCBOConcept("", " "), null); // space matters!
		private static const ROOT:TreeNode = new TreeNode(new NCBOConcept("__ROOT", "Root"), null);
		private static const MAX_PATH_TO_ROOT_COUNT:uint = 50;

		private var _service:IRestService;
		private var _versionID:String;
		private var _virtualID:String;
		private var childrenCache:Object;
		private var nodeCache:Object;
		private var _clearServiceCache:Boolean
		private var _rootsLoaded:Boolean = false;
		private var showWarning:Boolean = true;
		
		private var _rootConcept:NCBOConcept = null;
		
		private var currentOperation:IRestServiceOperation;
		
		public function OntologyDataDescriptor(service:IRestService = null, ontologyVersionID:String = "") {
			this.service = service;
			this.ontologyVersionID = ontologyVersionID;
			this._clearServiceCache = true;
		}
		
		public function get service():IRestService {
			return _service;
		}
		
		public function set service(s:IRestService):void {
			this._service = s;
		}
				
		public function get ontologyVersionID():String {
			return _versionID;
		}
		
		public function set ontologyVersionID(id:String):void {
			if (id != _versionID) {
				// clear the cache from the last ontology - do this before setting the new id
				clearCache(clearServiceCache);
				_versionID = id;
				_rootsLoaded = false;
			}
		}
		
		public function get ontologyVirtualID():String {
			return _virtualID;
		}
		
		public function set ontologyVirtualID(id:String):void {
			_virtualID = id;
		}
		
		public function get rootConcept():NCBOConcept {
			return _rootConcept;
		}
		
		public function set rootConcept(newRoot:NCBOConcept):void {
			if (_rootConcept != newRoot) {
				_rootConcept = newRoot;
				_rootsLoaded = false;
				// don't need to clear the cache?
				//clearCache(false);
			}
		}
		
		/**
		 * Returns true if the rest service cache is cleared every time the ontology changes.
		 * Defaults to true.
		 */
		public function get clearServiceCache():Boolean {
			return _clearServiceCache;
		}
		
		/**
		 * Set to false if the rest service cache shouldn't be cleared every time the ontology changes.
		 * Defaults to true.
		 */
		public function set clearServiceCache(clear:Boolean):void {
			_clearServiceCache = clear;
		}
		
		public function get root():TreeNode {
			return ROOT;
		}
		
		public function get rootsLoaded():Boolean {
			return _rootsLoaded;
		}
		
		public function get roots():ICollectionView {
			if (!ontologyVersionID) {
				return new ArrayCollection();
			}
			if (!_rootsLoaded) {
				if (rootConcept) {
					var rootNode:TreeNode = getCachedNode(rootConcept, null);
					cacheChildren(ROOT.id, new ArrayCollection([ rootNode ]));
				} else {
					cacheChildren(ROOT.id, null);
				}
				_rootsLoaded = true;
			}
			var rootNodes:ICollectionView = getChildren(ROOT);
			return rootNodes;
		}
		
		/**
		 * Performs an exact match search on the concept name. If there is only one result
		 * then the path to root (an Array of TreeNodes) is passed into the callback function.
		 */
		public function loadPathToRootByName(conceptName:String, ontology:NCBOOntology, callback:Function, allowPartialMatch:Boolean = true):void {
			// exact match first
			service.getConceptsByName(ontology, conceptName, SearchMode.EXACT_MATCH, function(event:NCBOSearchEvent):void {
				if (event.concepts && (event.concepts.length >= 1)) {
					var searchConcept:NCBOSearchResultConcept = event.concepts[0];
					loadPathToRootByID(searchConcept.id, callback);
				} else if (allowPartialMatch) {
					// now do a contains search
					searchContains(conceptName, ontology, callback);
				} else {
					Alert.show("Concept could not be found.", "Error");
					callback([]);
				}
			});
		}
		
		private function searchContains(conceptName:String, ontology:NCBOOntology, callback:Function):void {
			service.getConceptsByName(ontology, conceptName, SearchMode.CONTAINS, function(event:NCBOSearchEvent):void {
				var error:Boolean = true;
				if (event.concepts && (event.concepts.length == 1)) {
					error = false;
					loadPathToRootByID(event.concepts[0].id, callback);
				} else if (event.concepts && (event.concepts.length > 1)) {
					error = false;
					var window:SearchResultsPanel = new SearchResultsPanel();
					window.optionsBoxShown = false;
					window.width = Math.min(300, Application.application.width - 10);
					var resultsHandler:Function = function(event:CloseEvent):void {
						var ok:Boolean = false;
						if (event.detail === ContentWindow.OK) {
							var concept:NCBOSearchResultConcept = window.selectedResult;
							if (concept) { 
								loadPathToRootByID(concept.id, callback);
								ok = true;
							}
						}
						if (!ok) {
							callback([]);
						}
					};
					var parent:DisplayObject = (Application.application as DisplayObject);
					window.show(event.concepts, "Search Results", parent, resultsHandler);
					window.x = 5;
					window.y = 50;	// approximately under the search bar
				}
				if (error) {
					Alert.show("Concept could not be found.", "Error");
					callback([]);
				}
			});			
		}
		
		/**
		 * Loads the first path to root for the given concept id.
		 * The callback takes an Array of TreeNode objects representing the path to root
		 * starting with the given concept.
		 */
		public function loadPathToRootByID(conceptID:String, callback:Function, alertErrors:Boolean = true):void {
			service.getConceptByID(ontologyVersionID, conceptID, function(event:NCBOConceptEvent):void {
				loadPathToRoot(event.concept, callback);
			}, false, alertErrors);
		}
		
		/**
		 * Loads the first path to root for the given concept.
		 * The callback takes an Array of TreeNode objects representing the path to root
		 * starting with the given concept, and the expandLeaf/collapseLeaf parameters.
		 */ 
		public function loadPathToRoot(concept:NCBOConcept, callback:Function, 
							expandLeaf:Boolean = false, collapseLeaf:Boolean = false):void {
			if (concept) {
				// OLD WAY - load the hierarchy one parent at a time, very slow
//				var handler:Function = function(event:NCBOOperationEvent):void {
//					// returns the FIRST path to root (might by multiple) including this concept
//					var pathToRoot:Array = [];
//					buildPathToRoot(concept, pathToRoot);
//					callback(pathToRoot, expandLeaf, collapseLeaf);
//				};
				// load the first path to root only,and only on superclasses
//				var op:LoadHierarchyToRootOperation = new LoadHierarchyToRootOperation(service, 
//								ontologyVersionID, concept, handler, true, true);
//				op.addEventListener(NCBOOperationStartingEvent.OPERATION_STARTING, pathToRootNodeCount);
//				runOperation(op);

				// NEW WAY - use the path to root service, makes a single call to the service
				var handler:Function = function(event:NCBOPathToRootEvent):void {
					var pathToRoot:Array = [];
					// need to convert from NCBOConcepts to TreeNodes
					var parent:NCBOConcept = null;
					if (event.pathToRoot.length > 0) {
						var parentTreeNode:TreeNode = null;
						for (var i:int = 0; i < event.pathToRoot.length; i++) {
							var concept:NCBOConcept = event.pathToRoot[i];
							var treeNode:TreeNode = getCachedNode(concept, parent);
							pathToRoot.push(treeNode);
							treeNode.parentTreeNode = parentTreeNode;
							parent = concept;
							parentTreeNode = treeNode;
						}
					}
					
					callback(pathToRoot, expandLeaf, collapseLeaf);
					if (event.isError) {
						Alert.show("Error loading hierarchy:\n" + event.error.message, "Error");
					}
				};				
				service.getPathToRoot(ontologyVersionID, concept.id, handler); 
			} else {
				callback([]);
			}
		} 
		
		// NOT USED anymore
		private function buildPathToRoot(concept:NCBOConcept, pathToRoot:Array):void {
			// use superclasses, not parents
			var parents:Array = concept.superClasses;
			if ((concept != rootConcept) && (parents.length > 0)) {
				if (parents.length > 1) {
					//trace("Warning - multiple paths to root! (" + parents.length + ")");
				}

				// always get the first parent (should we sort alphabetically?)
				var parent:NCBOConcept = parents[0];
				var node:TreeNode = getCachedNode(concept, parent);	//creates and caches if not found
				pathToRoot.push(node);
				buildPathToRoot(parent, pathToRoot);
			} else {
				var root:TreeNode = getCachedNode(concept, null);
				pathToRoot.push(root);
			}
		}
		
		/**
		 * Searches through all the nodes loaded into the tree to find if the 
		 * ones that have the given id (e.g. same concept).
		 */
		public function findNodesByID(nodeID:String):Array {
			var nodes:Array = [];
			if (rootsLoaded && nodeID) {
				var roots:ArrayCollection = getCachedChildren(ROOT.id);
				findNodesByIDInCollection(nodeID, roots, nodes);
			}
			return nodes;
		}
		
		private function findNodesByIDInCollection(nodeID:String, collection:ArrayCollection, found:Array):void {
			if (collection) {
				for (var i:int = 0; i < collection.length; i++) {
					var node:TreeNode = (collection[i] as TreeNode);
					if (node) {
						if (node.id == nodeID) {
							found.push(node);
						}
						// recursively check children
						var children:ArrayCollection = getCachedChildren(node.id);
						findNodesByIDInCollection(nodeID, children, found);
					}
				}
			}
		}
		
		/**
		 * Searches through all the cached concepts to see if the concept has already been loaded.
		 */
		public function findNodeByName(nodeName:String, ignoreCase:Boolean = true):TreeNode {
			var node:TreeNode = null;
			if (rootsLoaded && (nodeName != null) && (nodeName.length > 0)) {
				var roots:ArrayCollection = getCachedChildren(ROOT.id);
				node = findNodeByNameInCollection(nodeName, roots, ignoreCase);
			}
			return node;
		}
		
		private function findNodeByNameInCollection(nodeName:String, collection:ArrayCollection, 
													 ignoreCase:Boolean = true):TreeNode {
			if (collection) {
				for (var i:int = 0; i < collection.length; i++) {
					var node:TreeNode = (collection[i] as TreeNode);
					if (node) {
						if (StringUtils.equals(node.name, nodeName, ignoreCase)) {
							return node;
						}
						// recursively check children
						var children:ArrayCollection = getCachedChildren(node.id);
						var found:TreeNode = findNodeByNameInCollection(nodeName, children, ignoreCase);
						if (found) { 
							return found;
						}
					}
				}
			}
			return null;
		}
		
		/**
		 * Searches through all the cached concepts to find any with the matching name.
		 */
		public function findNodesByName(nodeName:String, ignoreCase:Boolean = true):Array {
			var nodes:Array = [];
			if (rootsLoaded && (nodeName != null) && (nodeName.length > 0)) {
				var roots:ArrayCollection = getCachedChildren(ROOT.id);
				findNodesByNameInCollection(nodeName, roots, nodes, ignoreCase);
			}
			return nodes;
		}
		
		private function findNodesByNameInCollection(nodeName:String, collection:ArrayCollection, 
													found:Array, ignoreCase:Boolean = true):void {
			if (collection) {
				for (var i:int = 0; i < collection.length; i++) {
					var node:TreeNode = (collection[i] as TreeNode);
					if (node) {
						if (StringUtils.equals(node.name, nodeName, ignoreCase)) {
							found.push(node);
						}
						// recursively check children
						var children:ArrayCollection = getCachedChildren(node.id);
						findNodesByNameInCollection(nodeName, children, found, ignoreCase);
					}
				}
			}
		}
		
		/**
		 * Returns all the TreeNodes for a given concept.  
		 * This will usually return a single TreeNode, but if the concept has multiple 
		 * parents then it will return one tree node per parent.
		 */
		public function conceptToNodes(concept:NCBOConcept):Array {
			var nodes:Array = [];
			if (concept) {
				var treeNode:TreeNode;
				var parents:Array = concept.parents;
				if (parents.length > 0) {
					for (var i:int = 0; i < parents.length; i++) {
						var parent:NCBOConcept = parents[i];
						treeNode = getCachedNode(concept, parent);	// creates too
						nodes.push(treeNode);
					}
				} else {
					treeNode = getCachedNode(concept, null);
					nodes.push(treeNode);
				}
			}
			return nodes;
		}
		
		/**
		 * Calls loadChildren() on each TreeNode in the hierarchy in sequence.  It waits for the 
		 * children to finish loading before loading the next one.
		 * When all have been loaded then the callback gets called.
		 */
		public function loadChildrenForHierarchy(hierarchy:Array, index:uint = 0, callback:Function = null):void {
			if (index < hierarchy.length) {
				var node:TreeNode = hierarchy[index];
				var collection:ICollectionView = getChildren(node);
				if ((collection.length == 1) && (collection[0] == LOADING)) {
					// wait for the children to load
					var collectionChanged:Function = function(event:CollectionEvent):void {
						collection.removeEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChanged);
						loadChildrenForHierarchy(hierarchy, index + 1, callback);
					};
					collection.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChanged);
				} else {
					// children are already loaded
					loadChildrenForHierarchy(hierarchy, index + 1, callback);
				}
			} else if (callback != null) {
				callback();
			}
		}
		
		///////////////////////////////////
		// ITreeDataDescriptor functions
		///////////////////////////////////

		public function getChildren(obj:Object, model:Object = null):ICollectionView {
			var node:TreeNode = (obj as TreeNode);
			var children:ArrayCollection = getCachedChildren(node.id);
			if (children == null) {
				children = new ArrayCollection();
				cacheChildren(node.id, children);
				if (!node.concept.hasLoadedNeighbors) {
					children.source = [ LOADING ];
					if (node == ROOT) {
						//trace("Loading roots for " + ontologyID);
						if (ontologyVersionID) {
							service.getTopLevelNodes(ontologyVersionID, rootsLoadedHandler);
						} else {
							Alert.show("Warning - no ontology to load in the tree!", "Warning");
						}
					} else {
						//trace("Loading children for " + concept.nameAndID);
						var handler:Function = function(event:NCBOOperationEvent):void {
							childrenLoadedHandler(event, node);
						};
						var op:LoadChildrenOperation = new LoadChildrenOperation(service, ontologyVersionID, 
																node.concept, handler);
						runOperation(op);
					}
				} else {
					var subClasses:Array = node.children;
					addSort(children, (subClasses.length > 1));
					var childNodes:Array = conceptsToNodes(subClasses, node.concept);
					children.source = childNodes;
					
					// make sure the parent treeNode is set on each child node
					setParentTreeNode(childNodes, node);
				}
			}
			return children;
		}
		
		public function hasChildren(obj:Object, model:Object = null):Boolean {
			var node:TreeNode = (obj as TreeNode);
			return (node != LOADING) && (node.childCount > 0);
		}
		
		public function isBranch(node:Object, model:Object = null):Boolean {
			var branch:Boolean = hasChildren(node, model);
			return branch;
		}
		
		public function getData(node:Object, model:Object = null):Object {
			return node;
		}
		
		public function addChildAt(parent:Object, newChild:Object, index:int, model:Object = null):Boolean {
			return false;
		}
		
		public function removeChildAt(parent:Object, child:Object, index:int, model:Object = null):Boolean {
			return false;
		}

	    /** Copied from DefaultDataDescriptor */
	    public function getHierarchicalCollectionAdaptor(hierarchicalData:ICollectionView, 
					uidFunction:Function, openItems:Object, model:Object = null):ICollectionView {
	        return new HierarchicalCollectionView(hierarchicalData, this, uidFunction, openItems);
	    }
	
  	    /** Copied from DefaultDataDescriptor */
	    public function getNodeDepth(node:Object, iterator:IViewCursor, model:Object = null):int {
	        var depth:int = (node == iterator.current ? HierarchicalViewCursor(iterator).currentDepth : -1);
	        return depth;
	    }
	
	    public function getParent(node:Object, collection:ICollectionView, model:Object = null):Object {
	    	var treeNode:TreeNode = (node as TreeNode);
	    	if (treeNode && treeNode.parentTreeNode) {
	    		return treeNode.parentTreeNode;
	    	}
	    	// from DefaultDataDescriptor
	        return HierarchicalCollectionView(collection).getParentItem(node);
	    }
	    
	    
	    //////////////////////////////////////
	    // Children and TreeNode Caching
	    //////////////////////////////////////
	    
		private function clearCache(clearServiceCache:Boolean = true):void {
			childrenCache = new Object();
			nodeCache = new Object();
			if (service && clearServiceCache) {
				// clear the concepts from the current ontology
				service.clearConcepts(ontologyVersionID);
			}
		}
		
		private function cacheChildren(nodeID:String, children:ArrayCollection):void {
			if (children) {
				childrenCache[nodeID] = children;
			} else {
				delete childrenCache[nodeID];
			}
		}
		
		private function getCachedChildren(nodeID:String):ArrayCollection {
			return (childrenCache[nodeID] as ArrayCollection);
		}
		
	    private function getCachedNode(concept:NCBOConcept, parent:NCBOConcept, createIfNotFound:Boolean = true):TreeNode {
	    	var node:TreeNode = null;
	    	if (concept) {
		    	var key:String = (parent ? parent.id : "") + "_" + concept.id;
		    	node = (nodeCache[key] as TreeNode);
		    	if ((node == null) && createIfNotFound) {
		    		node = new TreeNode(concept, parent);
		    		nodeCache[key] = node;
		    	}
		    }
	    	return node;
	    }
	    
	    private function conceptsToNodes(concepts:Array, parent:NCBOConcept):Array {
	    	var nodes:Array = new Array(concepts.length);
	    	for (var i:int = 0; i < concepts.length; i++) {
	    		var concept:NCBOConcept = concepts[i];
	    		var node:TreeNode = getCachedNode(concept, parent);	// creates & caches if not found
	    		nodes[i] = node; 
	    	}
	    	return nodes;
	    }

	    
	    //////////////////////////////////////
	    // Root and Children Callbacks
	    //////////////////////////////////////
	    
		private function rootsLoadedHandler(event:NCBOConceptsEvent):void {
			var roots:Array = event.concepts;
			var cache:ArrayCollection = getCachedChildren(ROOT.id);
			addSort(cache, (roots.length > 1));
			var rootNodes:Array = conceptsToNodes(roots, null);
			cache.source = rootNodes;
			
			if (event.isError) {
				trace("Error loading roots: " + event.error);
			}
			
			dispatchEvent(new Event(ROOTS_LOADED));
		}
		
		private function childrenLoadedHandler(event:NCBOOperationEvent, parentTreeNode:TreeNode):void {
			var concept:NCBOConcept = event.concept;
			
			//var children:Array = event.neighborConcepts;
			// IMPORTANT - use the subClasses instead of the children
			var subClasses:Array = concept.subClasses;
			var cache:ArrayCollection = getCachedChildren(concept.id);
			//trace("Done loading " + subClasses.length + " children for " + concept.nameAndID);
			addSort(cache, (subClasses.length > 1));
			var nodes:Array = conceptsToNodes(subClasses, concept);
			cache.source = nodes;
			// set the parent treeNode on each child node
			setParentTreeNode(nodes, parentTreeNode);
						
			if (event.isError) {
				trace("Error loading children for '" + (concept ? concept.nameAndID : "null") + "': " + event.error);
			}
		}
		
		private function addSort(collection:ICollectionView, add:Boolean = true):void {
			if (add) {
				// sort alphabetically, ignore case
				ArrayUtils.addSort(collection, "name", true);
			}
		}
		
		private function setParentTreeNode(nodes:Array, parentTreeNode:TreeNode):void {
			for each (var treeNode:TreeNode in nodes) {
				treeNode.parentTreeNode = parentTreeNode;
			}
		}
		
		////////////////////////////
		// Operations and Warnings
		////////////////////////////
		
		public function stopCurrentOperation():void {
			if (currentOperation) {
				currentOperation.stop();
				currentOperation = null;
			}
		}
		
		private function runOperation(op:IRestServiceOperation):void {
			var finished:Function = function(event:NCBOOperationEvent):void {
				op.removeEventListener(NCBOOperationEvent.OPERATION_FINISHED, finished);
				currentOperation = null;
			}
			op.addEventListener(NCBOOperationEvent.OPERATION_FINISHED, finished);
			currentOperation = op;
			op.start();
		}
		
		private function pathToRootNodeCount(event:NCBOOperationStartingEvent):void {
			var nodeCount:uint = event.parentOperation.neighborConcepts.length;
			if (showWarning && (nodeCount >= MAX_PATH_TO_ROOT_COUNT)) {
				// have to pause the operation
				event.pauseOperation();
				
				var callback:Function = function(yes:Boolean):void {
					if (yes) {
						event.continueOperation();
					} else {
						event.stopOperation();
					}
				};
				var msg:String = "Loaded " + nodeCount + " terms so far.\nDo you want to continue?";
				showWarningDialog(msg, callback);
			}
		}
		
		private function showWarningDialog(lbl:String, callback:Function):void {
			var closeHandler:Function = function(yes:Boolean, checkboxSelected:Boolean):void {
				// update whether the warning dialog is shown next time
				showWarning = !checkboxSelected;
				if (callback != null) {
					callback(yes);
				}
			};
			UIUtils.createCheckBoxConfirmPopup(lbl, "Warning", "Don't show this warning", false, 
				ContentWindow.YES | ContentWindow.NO, ContentWindow.YES, null, closeHandler);
		}
		
	}
}