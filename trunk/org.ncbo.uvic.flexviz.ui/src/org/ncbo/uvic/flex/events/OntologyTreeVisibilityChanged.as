package org.ncbo.uvic.flex.events
{
	import flash.events.Event;
	
	import org.ncbo.uvic.flex.ui.FlexoVizOntologyTree;

	/**
	 * Fired when the FlexViz ontology tree visibility changes.
	 * 
	 * @author Chris Callendar
	 * @date June 26th, 2009
	 */
	public class OntologyTreeVisibilityChanged extends Event
	{

		public static const ONTOLOGY_TREE_VISIBILITY_CHANGED:String = "ontologyTreeVisibilityChanged";
		
		public var treeVisible:Boolean;

		public function OntologyTreeVisibilityChanged(visible:Boolean) {
			super(ONTOLOGY_TREE_VISIBILITY_CHANGED);
			this.treeVisible = visible;
		}
		
	}
}