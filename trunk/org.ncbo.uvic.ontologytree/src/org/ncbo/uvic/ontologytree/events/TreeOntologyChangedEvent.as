package org.ncbo.uvic.ontologytree.events
{
	import flash.events.Event;
	
	import org.ncbo.uvic.flex.model.NCBOOntology;

	/**
	 * Fired when the ontology in the OntologyTree changes.
	 * 
	 * @author Chris Callendar
	 * @date February 15th, 2010
	 */
	public class TreeOntologyChangedEvent extends Event
	{
		
		public static const ONTOLOGY_CHANGED:String = "ontologyChanged"; 
		
		private var _ontology:NCBOOntology;
		
		public function TreeOntologyChangedEvent(type:String, ontology:NCBOOntology) {
			super(type);
			this._ontology = ontology;
		}
		
		public function get ontology():NCBOOntology {
			return _ontology
		}
		
		override public function clone():Event {
			return new TreeOntologyChangedEvent(type, ontology);
		} 
		
	}
}