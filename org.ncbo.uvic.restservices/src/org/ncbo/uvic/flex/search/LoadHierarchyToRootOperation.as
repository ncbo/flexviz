package org.ncbo.uvic.flex.search
{
	import flex.utils.Map;
	
	import mx.utils.ObjectUtil;
	
	import org.ncbo.uvic.flex.IRestService;
	import org.ncbo.uvic.flex.OntologyConstants;
	import org.ncbo.uvic.flex.events.NCBOOperationEvent;
	import org.ncbo.uvic.flex.model.NCBOConcept;
	import org.ncbo.uvic.flex.model.NCBORelationship;

	/**
	 * Retrieves the hierarchy to root for a concept.
	 * It gets the parents of the concept, and then recursively gets the parents of each parent.
	 * 
	 * @author Chris Callendar
	 */
	public class LoadHierarchyToRootOperation extends SequenceOperation {
		
		private static const MAX_SIZE:uint = 100;
		
		private var seenConcepts:Map;
		private var superClassesOnly:Boolean;
		private var firstPathOnly:Boolean;
//		private var _allowedRelTypes:Array;
		
		public function LoadHierarchyToRootOperation(service:IRestService, ontologyID:String, concept:NCBOConcept, 
					callbackFunction:Function = null, superClassesOnly:Boolean = false, firstPathOnly:Boolean = false) {
			super(service, ontologyID, concept, callbackFunction);
			this.superClassesOnly = superClassesOnly;
			this.firstPathOnly = firstPathOnly;
//			this._allowedRelTypes = new Array();
//			this._allowedRelTypes.push("is_a");
			
			seenConcepts = new Map();
			seenConcepts[concept.id] = true;
			addOperation(new LoadParentsOperation(service, ontologyID, concept, operationFinished, superClassesOnly)); 
		}
		
//		public function get allowedRelationshipTypes():Array {
//			return _allowedRelTypes;
//		}
//		
//		/** Restrict which relationship types to follow. */
//		public function set allowedRelationshipTypes(value:Array):void {
//			_allowedRelTypes = value;
//		}
		
		override protected function operationFinished(event:NCBOOperationEvent):void {
			// no need to call addTime(event) because we call the super below
			
			var child:NCBOConcept = event.concept;
			var parents:Array = event.neighborConcepts;
			var parentCount:uint = parents.length;
			
			// filter parents to only keep the ones with the allowed relationship types
//			if ((parentCount > 0) && allowedRelationshipTypes && (allowedRelationshipTypes.length > 0)) {
//				parents = parents.filter(function(parent:NCBOConcept, i:int, a:Array):Boolean {
//					var rel:NCBORelationship = getParentRelationship(child, parent);
//					return rel && (allowedRelationshipTypes.indexOf(rel.type) != -1); 
//				});
//			}
			
			// add a new operation for each parent that we haven't seen before
			if (firstPathOnly && (parentCount > 1)) {
				// sort the parents - make the IS_A relationships come first, default to alphabetically
				sortParents(parents, child);
			}
			if ((parentCount > 1) && firstPathOnly) {
				parentCount = 1;
			}
			
			for (var i:int = 0; i < parentCount; i++) {
				var parent:NCBOConcept = NCBOConcept(parents[i]);
				if (parent && !seenConcepts.hasOwnProperty(parent.id)) {
					seenConcepts[parent.id] = true;
					var op:LoadParentsOperation = 
						new LoadParentsOperation(service, ontologyID, parent, operationFinished, superClassesOnly);
					// Breadth first search 
					//addOperation(op);
					// Depth first search
					addOperationAt(op, index+1);
				} else if (parent) {
					//trace("Already seen this artifact: [" + parent.id + "] " + parent.name);
				}
			} 
			
			// process the next operation
			super.operationFinished(event);
		}
		
		override protected function done():void {
			super.done();
		}
		
		override public function get canBeStopped():Boolean {
			return true;
		}
		
		/**
		 * Sort the parent concepts - make the IS_A relationships come first, default to alphabetically.
		 */
		private function sortParents(parents:Array, child:NCBOConcept):Array {
			parents.sort(function(parent1:NCBOConcept, parent2:NCBOConcept):int {
				var rel1:NCBORelationship = getParentRelationship(child, parent1);
				if (rel1 && (rel1.type == OntologyConstants.IS_A)) {
					return -1;
				} 
				var rel2:NCBORelationship = getParentRelationship(child, parent2);
				if (rel2 && (rel2.type == OntologyConstants.IS_A)) {
					return 1;
				}
				// sort alphabetically
				return ObjectUtil.stringCompare(parent1.name, parent2.name);
			});
			return parents;
		}
		
		private function getParentRelationship(child:NCBOConcept, parent:NCBOConcept):NCBORelationship {
			for each (var rel:NCBORelationship in child.relationships) {
				var src:NCBOConcept = (rel.inverted ? rel.destination : rel.source);
				var dest:NCBOConcept = (rel.inverted ? rel.source : rel.destination);
				if ((src == child) && (dest == parent)) {
					return rel;
				}
			}
			return null;
		}
		
	
	}
}