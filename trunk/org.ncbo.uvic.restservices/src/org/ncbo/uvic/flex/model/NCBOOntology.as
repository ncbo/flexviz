package org.ncbo.uvic.flex.model
{
	import flex.utils.DateUtils;
	import flex.utils.Map;
	import flex.utils.StringUtils;
	import flex.utils.Utils;
	
	import org.ncbo.uvic.flex.OntologyConstants;
	
	/**
	 * Represents an ontology - has an id, ontology id, display label, format (e.g. OBO, OWL), versions, and much more.
	 * Also holds all the cached concepts and relationships.
	 * Also has functions for exporting and importing the ontology to and from XML.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBOOntology extends NCBOItem implements IOntology
	{
		public static const LOCAL_ONTOLOGY:int = 3;

		private var _ontologyID:String;
		private var _abbreviation:String;
		private var _format:String;
		private var _version:String;
		private var _statusID:int;
		
		public var internalVersionNumber:Number;
		public var isRemote:Boolean;
		public var isView:Boolean;
		public var dateCreated:Date;
		
		private var _categoryIDs:Array;
		private var _groupIDs:Array;
		
		private var _rootsLoaded:Boolean;
		private var _roots:Array;
		private var _associations:Array;
		
		private var _nextRelID:int = 0;
		private var _concepts:Map;		// maps the concept id (string) to NCBOConcept
		private var _relationships:Map;	// maps the relationship id (int) to NCBORelationship
		
		private var _defaultRelType:String;
		
		public function NCBOOntology(id:String, ontologyID:String, displayLabel:String = "", abbreviation:String = "",
									 format:String = "OWL") {
			super(id, displayLabel);
			this._ontologyID = ontologyID;
			this._abbreviation = abbreviation;
			this._format = format;
			this._version = "";
			this._statusID = LOCAL_ONTOLOGY;
			this._categoryIDs = new Array();
			this._groupIDs = new Array();
			this._defaultRelType = OntologyConstants.SUBCLASS_OF;	// OWL
			clear();
		}
		
		public function clear():void {
			this._rootsLoaded = false;
			this._roots = new Array();
			this._associations = new Array();
			this._concepts = new Map();
			this._relationships = new Map();
		}
		

		override public function toString():String {
			return name;
		}
		
		public function get nameAndAbbreviation():String {
			return (hasAbbreviation ? name + " (" + abbreviation + ")" : name);
		}
		
		public function get ontologyVersionID():String {
			return id;
		}
		
		public function get ontologyID():String {
			return _ontologyID;
		}
		
		public function set ontologyID(oid:String):void {
			_ontologyID = oid;
		}
		
		public function get displayLabel():String {
			return name;
		}
		
		public function set displayLabel(label:String):void {
			name = label;
		}
		
		public function get hasAbbreviation():Boolean {
			return (abbreviation != null) && (abbreviation.length > 0);
		}
		
		public function get abbreviation():String {
			return _abbreviation;
		}
		
		public function set abbreviation(abbrev:String):void {
			_abbreviation = abbrev;
		}
		
		public function get format():String {
			return _format;	
		}
		
		public function set format(f:String):void {
			_format = f;
			if (f) {
				// use the default is_a relationship for OBO ontologies
				if (isOBO) {
					_defaultRelType = OntologyConstants.IS_A;
				}
			}
		}
		
		public function get isOBO():Boolean {
			return StringUtils.contains(format, "OBO");
		}
		
		public function get isOWL():Boolean {
			return StringUtils.contains(format, "OWL");
		}
		
		public function get version():String {
			return _version;
		}
		
		public function set version(v:String):void {
			_version = v;
		}
		
		public function get statusID():int {
			return _statusID;
		}
		
		public function set statusID(status:int):void {
			_statusID = status;
		}
		
		public function get isLocal():Boolean {
			return (statusID == LOCAL_ONTOLOGY);
		}
		
		public function hasCategory(categoryID:String):Boolean {
			return (categoryID != null) && (categoryIDs.indexOf(categoryID) != -1);	
		}
		
		public function get categoryIDs():Array {
			return _categoryIDs;
		}
		
		public function set categoryIDs(catIDs:Array):void {
			_categoryIDs = catIDs;
		}
		
		public function hasGroup(groupID:String):Boolean {
			return (groupID != null) && (groupIDs.indexOf(groupID) != -1);	
		}
		
		public function get groupIDs():Array {
			return _groupIDs;
		}
		
		public function set groupIDs(ids:Array):void {
			_groupIDs = ids;
		}
		
		public function get defaultRelType():String {
			return _defaultRelType;
		}
		
		public function set defaultRelType(def:String):void {
			_defaultRelType = def;
		}
		
		public function get hasLoadedRoots():Boolean {
			return _rootsLoaded;
		}
				
		public function get topLevelNodes():Array {
			return _roots;	
		}
		
		public function set topLevelNodes(roots:Array):void {
			if (roots == null) {
				_rootsLoaded = false;
				_roots = new Array();
			} else {
				_rootsLoaded = true;
				_roots = roots.slice();	// clone
			}
		}
				
		public function get associations():Array {
			return _associations;
		}
		
		public function set associations(assocs:Array):void {
			this._associations = assocs;
		}
		
		public function get cachedRootConceptCount():uint {
			return _roots.length;
		}
		
		public function get cachedConceptCount():uint {
			return _concepts.size;
		}
		
		public function get cachedConcepts():Array {
			return _concepts.values;
		}
		
		public function get cachedRelationshipCount():uint {
			return _relationships.size;
		}
		
		public function hasConcept(conceptID:String):Boolean {
			return ((conceptID != null) && _concepts.containsKey(conceptID));
		}
				
		public function getConcept(conceptID:String):NCBOConcept {
			if (hasConcept(conceptID)) {
				return NCBOConcept(_concepts[conceptID]);
			}
			return null;
		}
		
		public function addConcept(conceptID:String, name:String, type:String = ""):NCBOConcept {
			var concept:NCBOConcept = null;
			if ((conceptID != null) && (conceptID.length > 0)) {
				concept = getConcept(conceptID);
				if (concept == null) {
					if (!type) {
						type = OntologyConstants.CONCEPT;
					}
					concept = new NCBOConcept(conceptID, name, type, ontologyVersionID);
					_concepts[conceptID] = concept;
				}
			}
			return concept;
		}
		
		public function addRelationship(src:NCBOConcept, dest:NCBOConcept, parentChildRel:Boolean = false, 
				type:String = null, inverted:Boolean = false):NCBORelationship {
			// use the default relationship type - based on whether it is an OBO or OWL ontology
			//trace("addRel(" + type + ", " + src.id + ", " + dest.id + ", " + inverted);
			if (type == null) {
				type = defaultRelType;
			} else if (type == OntologyConstants.RDFS_SUBCLASS_OF) {
				// same as subClassOf
				type = OntologyConstants.SUBCLASS_OF;
			}			
			
			// first check if an identical relation already exists
			for each (var rel:NCBORelationship in _relationships) {
				// check inverse relations too
				if (((rel.source === src) && (rel.destination === dest)) ||
						((rel.source == dest) && (rel.destination == src))) {
					var same:Boolean = false;
					if (rel.type == type) {
						same = true;
					}
					// check if the existing relationship is of type subClassOf
					// we didn't know what type it was before, so use the new type (e.g. PAR)
					else if (rel.type == OntologyConstants.SUBCLASS_OF) {
						trace("Changing relationship type from " + rel.type + " to " + type);
						rel.type = type; 
						same = true;
//					} else if ((type == OntologyConstants.SUBCLASS_OF) && (rel.type == OntologyConstants.RDFS_SUBCLASS_OF)) {
//						// there is already a relationship, so don't add the default one?
//						same = true;
					}
					if (same) {
						//trace(rel.toString() + " already exists in this ontology");
						return rel;
					}
				}
			}
			
			// add the relationship, it doesn't already exist
			var id:int = _nextRelID++;
			// ensure a unique id
			while (_relationships.hasOwnProperty(id.toString(10))) {
				id = _nextRelID++;
			}
			
			return addRelationship2(id.toString(10), type, src, dest, parentChildRel, inverted);
		}
		
		private function addRelationship2(id:String, type:String, src:NCBOConcept, dest:NCBOConcept, 
						parentChildRel:Boolean = false, inverted:Boolean = false):NCBORelationship {
			var newRel:NCBORelationship = new NCBORelationship(id, type, src, dest, inverted, parentChildRel);
			_relationships[id] = newRel;
			//trace("Adding relationship: " + newRel.toString() + " (cprel=" + parentChildRel + ")");
			
			// add the parent/child relationships
			src.addChild(dest, parentChildRel);
			dest.addParent(src, parentChildRel);
			
			// also add it to the src and dest
			src.addRelationship(newRel);
			dest.addRelationship(newRel);
			
			//trace("Added relationship: " + newRel.id + ": " + newRel.toString());
			return newRel;
		} 
		
		public function hasRelationship(relID:String):Boolean {
			if ((relID != null) && (relID.length > 0)) {
				return _relationships.containsKey(relID);
			}
			return false;
		}
		
		public function getRelationship(relID:String):NCBORelationship {
			if (hasRelationship(relID)) {
				return NCBORelationship(_relationships[relID]);
			}
			return null;
		}
		
		///////////////////////
		
		/**
		 * Iterates through all cached concepts and
		 * returns an array of all the unique property names.
		 */
		public function collectConceptProperties():Array {
			var map:Map = new Map();
			for each (var concept:NCBOConcept in _concepts) {
				var props:Array = concept.propertyNames;
				for (var i:int = 0; i < props.length; i++) {
					var prop:String = String(props[i]);
					map.setValue(prop, true);
				} 
			}
			return map.keys;
		}
		
		
		///////////////////////
		// XML IMPORT/EXPORT
		///////////////////////
		
		public function exportToXML():XML {
			var xml:XML = <ontology/>;
			xml.@id = StringUtils.angleToSquareBrackets(id);
			xml.@ontologyID = StringUtils.angleToSquareBrackets(ontologyID);
			xml.@displayLabel = StringUtils.angleToSquareBrackets(displayLabel);
			if (hasAbbreviation) {
				xml.@abbreviation = StringUtils.angleToSquareBrackets(abbreviation);
			}
			xml.@format = StringUtils.angleToSquareBrackets(format);
			xml.@version = StringUtils.angleToSquareBrackets(version);
			xml.@statusID = statusID;
			xml.@internalVersionNumber = internalVersionNumber;
			xml.@isRemote = isRemote;
			xml.@isView = isView;
			xml.@dateCreated = DateUtils.toSQLDate(dateCreated);
			
			if (categoryIDs.length > 0) {
				xml.@categoryIDs = categoryIDs.join(",");
			}
			// don't save this value, just reload it
			//xml.@hasLoadedRoots = hasLoadedRoots.toString();
			
			var relsMap:Object = new Object();
			var rel:NCBORelationship;
			
			// add concepts to xml
			for each (var concept:NCBOConcept in _concepts) {
				xml.appendChild(conceptToXML(concept));
				// save relationships for later
				for (var i:int = 0; i < concept.relationships.length; i++) {
					rel = NCBORelationship(concept.relationships[i]);
					if (!relsMap.hasOwnProperty(rel.id)) {
						relsMap[rel.id] = rel;
					}
				}
			}
			// now add relationships to xml, they should go last
			for each (rel in relsMap) {
				xml.appendChild(relationshipToXML(rel));
			}
			
			return xml;
		}
		
		public function importFromXML(xml:XML):void {
			if (xml.@id == id) {
				ontologyID = xml.@ontologyID;
				displayLabel = xml.@displayLabel;
				abbreviation = xml.@abbreviation;
				format = xml.@format;
				version = xml.@version;
				statusID = parseInt(xml.@statusID, 10);
				internalVersionNumber = Number(xml.@internalVersionNumber);
				isRemote = Utils.toBoolean(xml.@isRemote);
				isView = Utils.toBoolean(xml.@isView);
				dateCreated = DateUtils.parseSQLDate(xml.@dateCreated);
				
				var catIDs:String = String(xml.@categoryIDs);
				categoryIDs = (catIDs.length > 0 ? catIDs.split(",") : []); 
				
				// parse the concepts first
				for each (var conceptXML:XML in xml.concept) {
					addConceptFromXML(conceptXML);
				}
				
				// also need to set the next relationsip id
				var maxID:Number = 0;
				
				// parse the relationships last, they require all the concepts to be loaded already
				for each (var relXML:XML in xml.relationship) {
					var rel:NCBORelationship = addRelationshipFromXML(relXML);
					if (rel != null) {
						maxID = Math.max(maxID, Utils.toInt(rel.id));
					} 
				}
				
				// set the next relationship id
				_nextRelID = maxID + 1;
			}
		}
		
		private function addConceptFromXML(conceptXML:XML):NCBOConcept {
			var id:String = String(conceptXML.@id);
			var concept:NCBOConcept = getConcept(id);
			if (concept == null) {
				var name:String = String(conceptXML.@name);
				var type:String = String(conceptXML.@type);
				concept = addConcept(id, name, type);
				concept.childCount = Utils.toInt(String(conceptXML.@childCount));
				// TODO not supported yet
				//concept.parentCount = Utils.toInt(String(conceptXML.@parentCount));				
				concept.hasLoadedNeighbors = (conceptXML.@hasLoadedNeighbors == "true");
				
				// load any additional properties (comments, definitions, and synonyms, ...)
				for each (var propXML:XML in conceptXML.property) {
					var propName:String = String(propXML.@name);
					if (!concept.hasProperty(propName)) {
						var propValue:Object = propXML.text().toString();
						var propType:String = propXML.@type;
						// special case for number and boolean values
						if ((propType != null) && (propType.length > 0)) {
							if (propType == "Number") {
								propValue = Number(propValue);
							} else if (propType == "Boolean") {
								propValue = Boolean(propValue);
							}
						}
						concept.setProperty(propName, propValue);
					}
				}
			} else {
				trace("Warning - concept already exists: " + concept);
			}
			return concept;
		}
		
		private function conceptToXML(concept:NCBOConcept):XML {
			var conceptXML:XML = <concept/>;
			
			// these are saved in the properties now
			conceptXML.@id = StringUtils.angleToSquareBrackets(concept.id);
			conceptXML.@name = StringUtils.angleToSquareBrackets(concept.name);
			conceptXML.@type = StringUtils.angleToSquareBrackets(concept.type);
			conceptXML.@childCount = concept.childCount;
			// TODO not supported yet
			//conceptXML.@parentCount = concept.parentCount;
			
			conceptXML.@hasLoadedNeighbors = concept.hasLoadedNeighbors.toString();
			
			// save any additional properties (comments, definitions, synonyms, etc)
			concept.propertyNames.forEach(function(propName:String, i:int, arr:Array):void {
				var prop:Object = concept.getProperty(propName);
				var propValue:String = null;
				var propType:String = null;
				// special case for number and boolean values
				if (prop is String) {
					propValue = String(prop);
				} else if (prop is Number) {
					propValue = prop.toString();
					propType = "Number";
				} else if (prop is Boolean) {
					propValue = prop.toString();
					propType = "Boolean";
				}
				if (propValue != null) {
					var propXML:XML = <property/>;
					propXML.@name = propName;
					propXML.appendChild(StringUtils.angleToSquareBrackets(propValue));
					if (propType != null) {
						propXML.@type = propType;
					}
					conceptXML.appendChild(propXML);
				}
			});
						
			return conceptXML;
		}
		
		private function addRelationshipFromXML(relXML:XML):NCBORelationship {
			var id:String = String(relXML.@id);
			var rel:NCBORelationship = getRelationship(id);
			if (rel == null) {
				var type:String = String(relXML.@type);
				var sourceID:String = String(relXML.@source);
				var destinationID:String = String(relXML.@destination);
				if (hasConcept(sourceID) && hasConcept(destinationID)) {
					var src:NCBOConcept = getConcept(sourceID);
					var dest:NCBOConcept = getConcept(destinationID);
					var parentChildRel:Boolean = ("true" == relXML.@parentChildRelationship);
					var inverted:Boolean = ("true" == relXML.@inverted);
					rel = addRelationship2(id, type, src, dest, parentChildRel, inverted);
					
					// don't forget that relationships can have properties... for now there are none
					
				} else {
					trace("Couldn't find the source and/or destination concepts!  " + 
						  "Source=" + sourceID + ", destination=" + destinationID);
				} 
			} else {
				trace("Warning - there is already a relationship with id " + id + ": " + rel.toString());
			}
			return rel;
		}
		
		private function relationshipToXML(rel:NCBORelationship):XML {
			var relXML:XML = <relationship/>;
			relXML.@id = rel.id;
			relXML.@type = StringUtils.angleToSquareBrackets(rel.type);
			relXML.@source = rel.sourceID;
			relXML.@destination = rel.destinationID;
			// only set these properties if they differ from the default values (false)
			if (rel.parentChildRelationship) {
				relXML.@parentChildRelationship = rel.parentChildRelationship.toString();
			}
			if (rel.inverted) {
				relXML.@inverted = rel.inverted.toString();
			}
			
			// don't forget that relationships can have properties... for now there are none
			
			return relXML;
		}
		
					
	}
	
}