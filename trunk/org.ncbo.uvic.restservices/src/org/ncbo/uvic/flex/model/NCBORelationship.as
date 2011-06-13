package org.ncbo.uvic.flex.model
{
	/**
	 * Represents a relationship from a source concept to a destination concept.
	 * Also has a type and an id (usually an integer).
	 * The name property is not used by the NCBORelationship class.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBORelationship extends NCBOItem
	{

		private var _fullID:String;
		private var _type:String;

		private var _src:NCBOConcept;
		private var _dest:NCBOConcept;		
		private var _inverted:Boolean;
		// true if this is a SubClass or SuperClass relationship
		private var _parentChildRelationship:Boolean;
	
		public function NCBORelationship(id:String, type:String, src:NCBOConcept, dest:NCBOConcept, 
					inverted:Boolean = false, parentChildRel:Boolean = false) {
			super(id);
			this.type = type;
			_src = src;
			_dest = dest;
			_inverted = inverted;
			_parentChildRelationship = parentChildRel;
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
		
		public function get source():NCBOConcept {
			return _src;
		}
		
		public function get sourceID():String {
			var src:NCBOConcept = source;
			return (src != null ? src.id : "");
		}
				
		public function get sourceName():String {
			return (source ? source.name : "");
		}

		public function get sourceNameAndID():String {
			return (source ? source.nameAndID : "");
		}
		
		public function get destination():NCBOConcept {
			return _dest;
		}
		
		public function get destinationID():String {
			var dest:NCBOConcept = destination;
			return (dest != null ? dest.id : "");
		}
		
		public function get destinationName():String {
			return (destination ? destination.name : "");
		}

		public function get destinationNameAndID():String {
			return (destination ? destination.nameAndID : "");
		}
		
		override public function toString():String {
			return sourceNameAndID + (inverted ? " <" : " ") + "-- " + type + " --" + 
							  (inverted ? " " : "> ") + destinationNameAndID;
		}
		
		public function get inverted():Boolean {
			return _inverted;
		}
		
		public function get parentChildRelationship():Boolean {
			return _parentChildRelationship;
		}
	
	}
}