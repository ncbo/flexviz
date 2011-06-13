package org.ncbo.uvic.ontologytree
{
	import flex.utils.StringUtils;
	
	import mx.core.IUID;
	import mx.utils.StringUtil;
	
	import org.ncbo.uvic.flex.model.NCBOConcept;
	import org.ncbo.uvic.flex.model.NCBORelationship;
	
	public class TreeNode implements IUID
	{
		
		private var _uid:String;
		public var parent:NCBOConcept;
		public var concept:NCBOConcept;
		public var parentTreeNode:TreeNode;
		private var _relType:String;
		private var _shortName:String;
		
		public function TreeNode(concept:NCBOConcept, parent:NCBOConcept) {
			this.concept = concept;
			this.parent = parent;
			this.uid = null;
		}
		
		public function get uid():String {
			return _uid;
		}
		
		public function set uid(value:String):void {
			_uid = value;
		} 
		
		public function get name():String {
			return concept.name;
		}
		
		public function get id():String {
			return concept.id;
		}
		
		public function get children():Array {
			return concept.subClasses;
		}
		
		public function get childCount():int {
			return concept.childCount;
		}
		
	    public function get relType():String {
	    	if (_relType == null) {
	    		_relType = "";
	    		if (concept && parent) {
			    	var rels:Array = concept.relationships;
			    	for (var i:int = 0; i < rels.length; i++) {
			    		var rel:NCBORelationship = rels[i];
			    		if (rel.parentChildRelationship && (rel.source == parent) && 
			    			(rel.destination == concept)) {
			    			_relType = rel.type;
			    			break;
			    		}
			    	}
			    }
		    }
	    	return _relType;
	    }

		public function toString():String {
			return name;
		}
		
		public function get shortName():String {
			if (!_shortName) {
				if (concept && concept.name) {
					// remove any new lines
					_shortName = StringUtils.stripCharacters(concept.name, ['\n'], [' ']);
					if (_shortName.length > 40) {
						_shortName = StringUtil.trim(_shortName.substr(0, 38)) + "...";
					}
				} else {
					_shortName = "";
				}
			}
			return _shortName;
		}

	}
}