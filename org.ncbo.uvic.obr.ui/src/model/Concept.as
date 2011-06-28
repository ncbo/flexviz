package model
{
	import flex.utils.StringUtils;
	
	import org.ncbo.uvic.flex.model.IConcept;
	import org.ncbo.uvic.flex.model.NCBOItem;
	
	
	public class Concept extends NCBOItem implements IConcept
	{
		
		public static const UMLS_SEMANTIC_TYPE:String = "T000";
		public static const BIOPORTAL_SEMANTIC_TYPE:String = "T999";
		
		public var ontologyID:String;		// localOntologyID
		public var isTopLevel:Boolean;		
		public var synonyms:Array;			// String[]
		public var semanticTypeIDs:Array;	// localSemanticTypeIDs, String[]
		
		// the number of annotations for this concept
		// it is something we count, not something provided by the services
		public var numAnnotations:int = 1; 
		// loading separately
		public var ontology:Ontology = null;
		
		public function Concept(id:String = "", prefName:String = "", topLevel:Boolean = false, ontologyID:String = "", 
								synonyms:Array = null, semanticTypes:Array = null) {
			super(convertID(id, ontologyID), prefName);
			this.isTopLevel = topLevel;
			this.ontologyID = ontologyID;
			this.synonyms = (synonyms == null ? [] : synonyms);
			this.semanticTypeIDs = (semanticTypes == null ? [] : semanticTypes);
		}
		
	
		public function get ontologyVersionID():String {
			return ontologyID;
		}
		
		/**
		 * By default the conceptID is prefixed with the ontologyID and a forward slash like
		 * "RCD/C0410081" or "SNOMEDCT/C0693437".
		 */
		private static function convertID(conceptID:String, ontologyID:String):String {
			if (StringUtils.startsWith(conceptID, ontologyID + "/")) {
				return conceptID.substr(ontologyID.length + 1);
			}
			return conceptID;
		}
		
		public function addSynonym(syn:String):void {
			if ((syn != null) && (synonyms.indexOf(syn) == -1)) {
				synonyms.push(syn);
			}
		}
		
		public function addSemanticType(type:String):void {
			if ((type != null) && (semanticTypeIDs.indexOf(type) == -1)) {
				semanticTypeIDs.push(type);
			}
		}
		
		public function hasSemanticType(semanticTypeID:String):Boolean {
			var found:Boolean = false;
			for (var i:int = 0; i < semanticTypeIDs.length; i++) {
				var type:String = semanticTypeIDs[i];
				if (type == semanticTypeID) {
					found = true;
					break;
				}
			}
			return found;
		}
		
		public function get isFromUMLS():Boolean {
			return hasSemanticType(UMLS_SEMANTIC_TYPE);
		}
		
		public function get isFromBioPortal():Boolean {
			return hasSemanticType(BIOPORTAL_SEMANTIC_TYPE);
		}
		
		override public function toString():String {
			return nameAndID;
		}
		
		public function get nameAndOntology():String {
			var str:String = name;
			if ((ontologyName != null) && (ontologyName.length > 0)) {
				str += " [" + ontologyName + "]";
			} 
			return str;
		}
		
		public function get ontologyName():String {
			return (ontology != null ? ontology.name : "");
		}
		
		public function get isBioPortal():Boolean {
			return (ontology != null ? ontology.isBioPortal : true /* default to BioPortal?!? */);
		}
		
		public function get isUMLS():Boolean {
			return (ontology != null ? ontology.isUMLS : false /* default to BioPortal?!? */);
		}

	}
}