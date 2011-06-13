package org.ncbo.uvic.flex.events
{
	import flash.events.Event;

	public class OntologyChangedEvent extends Event
	{
		
		public static const ONTOLOGY_CHANGED:String = "ontologyChanged";
		
		public var versionID:String;
		public var virtualID:String;
		
		public function OntologyChangedEvent(ontologyVersionID:String, ontologyVirtualID:String = "") {
			super(ONTOLOGY_CHANGED);
			this.versionID = ontologyVersionID;
			this.virtualID = ontologyVirtualID;
		}
		
	}
}