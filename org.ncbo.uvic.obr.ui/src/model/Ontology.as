package model
{
	import org.ncbo.uvic.flex.model.IOntology;
	import org.ncbo.uvic.flex.model.NCBOItem;
	
	
	/**
	 * Represents an Ontology retrieved from the OBR annotation service.
	 * These ontologies are slightly different from the BioPortal ontologies, for one
	 * they can actually be UMLS ontologies (which currently aren't loaded into BioPortal).
	 * 
	 * @author Chris Callendar
	 * @date January 2009
	 */
	public class Ontology extends NCBOItem implements IOntology
	{
		
		public var version:String;
		public var numAnnotations:int;
		private var _isUMLS:Boolean;
		private var _ontologyID:String;
		public var abbreviation:String;
		
		// for the ontology recommender only
		public var score:Number;
		public var normalizedScore:Number;
		public var overlap:Number;
		public var numAnnotatingConcepts:Number;
		
		public function Ontology(id:String = "", name:String = "", version:String = "", 
								 nbAnnotations:int = 0, virtualOntID:String = "", abbrev:String = "") {
			super(id, name);
			this.version = version;
			this.numAnnotations = (isNaN(nbAnnotations) ? 0 : nbAnnotations);
			// hack - UMLS ontology id's aren't numbers, BioPortal ids are
			var numID:Number = Number(id);
			this._isUMLS = isNaN(numID);
			this._ontologyID = virtualOntID;
			this.abbreviation = abbrev;
			this.score = 0;
			this.normalizedScore = 0;
			this.overlap = 0;
			this.numAnnotatingConcepts = 0;
		}
		
		override public function toString():String {
			return id + ": " + name + " (" + ontologyID + ")";
		}
				
		public function get isUMLS():Boolean {
			return _isUMLS;
		}
		
		public function get isBioPortal():Boolean {
			return !isUMLS;
		}
		
		public function get nameAndAbbreviation():String {
			return (abbreviation? name + " (" + abbreviation + ")" : name);
		}
		
		public function get abbreviationOrName():String {
			return (abbreviation ? abbreviation : name);
		}
		
		public function get abbreviationOrID():String {
			return (abbreviation ? abbreviation : id);
		}
		
		// for IOntology
		
		public function get ontologyVersionID():String {
			return id;
		}
		
		public function get ontologyID():String {
			return _ontologyID;
		}
		
	}
}