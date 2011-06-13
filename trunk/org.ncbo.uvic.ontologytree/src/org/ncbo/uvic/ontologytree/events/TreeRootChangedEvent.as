package org.ncbo.uvic.ontologytree.events
{
	import flash.events.Event;
	
	import org.ncbo.uvic.flex.model.NCBOConcept;

	/**
	 * Fired when the OntologyTree root concept changes.
	 * When the tree is restored to it's original roots, the value of 
	 * concept will be set to the PREVIOUS root concept.
	 * 
	 * @author Chris Callendar
	 * @date December 12th, 2009
	 */
	public class TreeRootChangedEvent extends Event
	{
		
		public static const TREE_ROOT_CHANGED:String 	= "treeRootChanged";
		public static const TREE_ROOT_RESTORED:String	= "treeRootRestored";
		
		public var concept:NCBOConcept;
		
		public function TreeRootChangedEvent(type:String, concept:NCBOConcept) {
			super(type);
			this.concept = concept;
		}
		
		override public function clone():Event { 
			return new TreeRootChangedEvent(type, concept);
		}
		
	}
}