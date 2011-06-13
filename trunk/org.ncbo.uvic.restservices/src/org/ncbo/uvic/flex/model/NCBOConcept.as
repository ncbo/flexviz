package org.ncbo.uvic.flex.model
{
	
	/**
	 * Represents an ontological concept which consists of an id, label, type, children, parents, and some 
	 * generic properties such a comments, definitions, synonyms, etc.
	 * 
	 * For now the type is always set to "concept". In the future different types might be supported.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBOConcept extends NCBOItem implements IConcept
	{
		
		private var _childCount:int;
		private var _parentCount:int;
		private var _ontologyVersionID:String;
		private var _fullID:String;
		private var _type:String;
		
		private var _neighborsLoaded:Boolean;
		// all children - even those that aren't subclasses
		private var _children:Array;
		// only the children that are sub classes (subset of children)
		private var _subClasses:Array;
		// all the parents, even those that aren't superclasses
		private var _parents:Array;
		// only the super class parents (subset of parents)
		private var _superClasses:Array;
		
		private var _relationships:Array; 
		
		public function NCBOConcept(id:String, name:String, type:String = "concept", ontologyVersionID:String = "") {
			super(id, name);
			this.type = type;
			this._childCount = 0;
			this._parentCount = 0;
			this._ontologyVersionID = ontologyVersionID;
			
			this._neighborsLoaded = false;
			this._children = new Array();
			this._subClasses = new Array();
			this._parents = new Array();
			this._superClasses = new Array();
			this._relationships = new Array(); 
		}
		
		/////////////////
		// PROPERTIES
		/////////////////
		
		public function get ontologyVersionID():String {
			return _ontologyVersionID;
		}
		
		public function get fullID():String {
			return (_fullID ? _fullID : id);
		}
		
		public function set fullID(value:String):void {
			_fullID = value;
		}
		
		public function get type():String {
			return _type;
		}
		
		public function set type(typ:String):void {
			// only the parser should set this!
			this._type = typ;
		}
		
		public function get childCount():int {		
			return _childCount;
		}
		
		public function set childCount(count:int):void {
			// only the parser should set this!
			this._childCount = count;
		}
		
		public function get parentCount():int {
			return _parentCount;
		}
		
		public function set parentCount(count:int):void {
			// only the parser should set this!
			this._parentCount = count;
		}
		
		
		///////////////////////////
		// CHILD/PARENT Functions
		///////////////////////////
		
		public function get hasLoadedNeighbors():Boolean {
			return _neighborsLoaded;
		}
		
		public function set hasLoadedNeighbors(loaded:Boolean):void {
			this._neighborsLoaded = loaded;
		}
		
		public function get hasChildren():Boolean {
			return (_children.length > 0) || !hasLoadedNeighbors;
		}
		
		public function get children():Array {
			return _children;
		}
		
		public function get subClasses():Array {
			return _subClasses;
		}
		
		public function addChild(child:NCBOConcept, isSubClass:Boolean = false):void {
			if (child != null) {
				// check if already exists
				var add:Boolean = true;
				for (var i:int = 0; i < _children.length; i++) {
					if (NCBOConcept(_children[i]).id == child.id) {
						add = false;
						break;
					}
				}
				if (add) {
					_children.push(child);
					if (isSubClass) {
						_subClasses.push(child);
					}
				}
			}
		}
		
		/** Returns the cached descendants. */
		public function get loadedDescendants():Array {
			var descendants:Array = new Array();
			if (hasLoadedNeighbors) {
				for (var i:int = 0; i < _children.length; i++) {
					var child:NCBOConcept = NCBOConcept(_children[i]);
					if (descendants.indexOf(child) == -1) {
						descendants.push(child);
						var more:Array = child.loadedDescendants;
						for (var j:int = 0; j < more.length; j++) {
							var grandchild:NCBOConcept = more[j];
							if (descendants.indexOf(grandchild) == -1) {
								descendants.push(grandchild);
							}
						}
					}
				}
			}
			return descendants;
		}
					
		public function get hasParents():Boolean {
			return (parents.length > 0) || !hasLoadedNeighbors;
		}
		
		public function get parents():Array {
			return _parents;
		}
		
		public function get superClasses():Array {
			return _superClasses;
		}
		
		public function addParent(parent:NCBOConcept, isSuperClass:Boolean = false):void {
			if (parent != null) {
				// check if already exists
				var add:Boolean = true;
				for (var i:int = 0; i < _parents.length; i++) {
					if (NCBOConcept(_parents[i]).id == parent.id) {
						add = false;
						break;
					}
				}
				if (add) {
					_parents.push(parent);
					if (isSuperClass) {
						_superClasses.push(parent);
					}
				}
			}
		}
				
		public function get relationshipsCount():int {
			return _relationships.length;
		}
				
		public function get relationships():Array {
			return _relationships;
		}
		
		public function addRelationship(rel:NCBORelationship):void {
			if (rel != null) {
				// check if this relationship already exists
				for (var i:int = 0; i < _relationships.length; i++) {
					if (NCBORelationship(_relationships[i]).id == rel.id) {
						return;
					}
				}
				_relationships.push(rel);
			}
		}
		
		public function get isRoot():Boolean {
			return hasLoadedNeighbors && (parents.length == 0);
		}
		
		
		/**
		 * Returns the connected nodes.
		 * It iterates through the cached relationships for this artifact
		 * and returns all the source/destination artifacts excluding this artifact.
		 */
		public function get connectedConcepts():Array {
			var connected:Array = new Array();
			if (relationships.length > 0) {
				for (var i:int = 0; i < relationships.length; i++) {
					var rel:NCBORelationship = NCBORelationship(relationships[i]);
					if (rel.source != this) {
						connected.push(rel.source);
					} else if (rel.destination != this) {
						connected.push(rel.destination);
					}
				}
			}
			return connected;
		}
				
	}
}