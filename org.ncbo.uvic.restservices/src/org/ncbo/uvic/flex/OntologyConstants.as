package org.ncbo.uvic.flex
{
	import flex.utils.Map;
	
	
	/**
	 * Defines many of the Ontology Relationship types:
	 * is_a, part_of, subClassOf, etc.
	 * Also keeps a map of which arc types are inverted. 
	 * 
	 * @author Chris Callendar
	 */
	public class OntologyConstants
	{
		
		// node types
		public static const CONCEPT:String			= TERM; //"concept";
		public static const TERM:String				= "term";
		public static const CLASS:String			= "Class";
		public static const OWL_CLASS:String		= "owl:Class";
		public static const PROPERTY:String			= "Property";
		public static const INDIVIDUAL:String 		= "Individual";
		public static const GROUPED_CONCEPTS:String = "GroupedConcepts";
		
		// relationship types
		public static const IS_A:String 			= "is_a";			// inverted
		public static const IS_A_ATTRIBUTE:String 	= "Is a (attribute)";// inverted
		public static const PART_OF:String 			= "part_of";		// inverted
		public static const PART_OF2:String 		= "part of";		// inverted
		public static const DEVELOPS_FROM:String 	= "develops_from";	// inverted
		public static const HAS_SUBCLASS:String 	= "has subclass";
		public static const SUBCLASS_OF:String		= "subClassOf";		// inverted?
		public static const RDFS_SUBCLASS_OF:String	= "rdfs:subClassOf";// inverted?
		public static const HAS_INSTANCE:String 	= "has instance";
		public static const INSTANCE_OF:String		= "instanceOf";
		public static const HAS_PART:String			= "has_part";
		public static const PARTICIPATES_IN:String	= "participates_in";	// inverted
		public static const HAS_PARTICIPANT:String	= "has_participant";
		public static const CODES_FOR:String		= "codes_for";
		public static const ENCODED_BY:String		= "encoded_by";			// inverted?
		public static const HAS_SOURCE:String		= "has_source";
		public static const REGULATES:String		= "regulates";					// inverted?
		public static const POSITIVELY_REGULATES:String = "positively_regulates";	// inverted?
		public static const NEGATIVELY_REGULATES:String = "negatively_regulates";	// inverted?
		public static const LOCATION_OF:String		= "location_of";	// inverted?
		public static const LOCATED_IN:String		= "located_in";
		public static const TRANSFORMS_INTO:String	= "transforms_into";
		public static const TRANSFORMED_INTO:String	= "transformed_into";
		public static const TRANSFORMATION_OF:String = "transformation_of";	// inverted?
		// ICD9
		public static const PAR:String = "PAR";
		public static const CHD:String = "CHD";
		public static const SIB:String = "SIB";
		
		public static const OWL_THING:String 		= "owl:Thing";
		public static const THING:String	 		= "THING";
		public static const THING2:String	 		= ":THING";
		
		public static const SHOW_NETWORK_NEIGHBORHOOD:String 	= "Show Network Neighborhood";
	 	public static const SHOW_HIERARCHY_TO_ROOT:String 		= "Show Hierarchy To Root (All Relationships)";
		
		// Properties (can be multiple)
		public static const RDFS_COMMENT:String = "rdfs:comment";	// OWL only
		public static const COMMENT:String 		= "Comment";		// OBO
		public static const DEFINITION:String	= "Definition";
		public static const SYNONYM:String 		= "Synonym";
		public static const AUTHOR:String		= "Author";	
		
		private static var _allNodeTypes:Array = null;
		private static var _allArcTypes:Array = null;
		
		// contains only the arc types that are inverted
		private static var _invertedArcTypesMap:Map;
		
		public static function get allNodeTypes():Array {
			if (_allNodeTypes == null) {
				_allNodeTypes = new Array();
				_allNodeTypes.push(CONCEPT);
				_allNodeTypes.push(OWL_CLASS);
				_allNodeTypes.push(GROUPED_CONCEPTS);
			}
			return _allNodeTypes;
		}
		
		private static function get invertedArcTypesMap():Map {
			if (_invertedArcTypesMap == null) {
				_invertedArcTypesMap = new Map();
				
				// add the default inverted arcs
				_invertedArcTypesMap[SUBCLASS_OF] = true;
				_invertedArcTypesMap[INSTANCE_OF] = true;
	
				// April 21st 2010 - commented out the OBO rel types
				// OBO ontologies use the [R] flag to indicate the direction of the relationship
//				_invertedArcTypesMap[IS_A] = true;
//				_invertedArcTypesMap[IS_A_ATTRIBUTE] = true;
//				_invertedArcTypesMap[PART_OF] = true;
//				_invertedArcTypesMap[PART_OF2] = true;
//				_invertedArcTypesMap[DEVELOPS_FROM] = true;
//				_invertedArcTypesMap[PARTICIPATES_IN] = true;
//				_invertedArcTypesMap[ENCODED_BY] = true;
//				_invertedArcTypesMap[REGULATES] = true;
//				_invertedArcTypesMap[NEGATIVELY_REGULATES] = true;
//				_invertedArcTypesMap[POSITIVELY_REGULATES] = true;
//				_invertedArcTypesMap[LOCATION_OF] = true;
				
				_invertedArcTypesMap[PAR] = true;
			}
			return _invertedArcTypesMap;
		}
		
		/**
		 * Keep track of as many known arc types are possible.
		 * This is mainly done to ensure that the same arc types
		 * always have the same color each session.
		 */
		public static function get allArcTypes():Array {
			if (_allArcTypes == null) {
				var types:Array = new Array();
				
				// OBO / anatomy relationships
				types.push(IS_A);
				types.push(PART_OF);
				types.push(PART_OF2);
				types.push(DEVELOPS_FROM);
	
				// Protege relationships
				types.push(HAS_SUBCLASS);
				types.push(SUBCLASS_OF);
				types.push(HAS_PART);

				// more OBO relationships
				types.push(PARTICIPATES_IN);
				types.push(HAS_PARTICIPANT);
				types.push(CODES_FOR);
				types.push(ENCODED_BY);
				types.push(HAS_SOURCE);
				types.push(REGULATES);
				types.push(POSITIVELY_REGULATES);
				types.push(NEGATIVELY_REGULATES);
				types.push(LOCATION_OF);
				types.push(LOCATED_IN);
				types.push(TRANSFORMS_INTO);
				types.push(TRANSFORMED_INTO);
				types.push(TRANSFORMATION_OF);
				
				// Protege - never seen it though?
				types.push(HAS_INSTANCE);
				types.push(INSTANCE_OF);
				
				// ICD9
				types.push(PAR);
				types.push(CHD);
				types.push(SIB);
				
				types.push(IS_A_ATTRIBUTE);
				
				_allArcTypes = types;
			}
			return _allArcTypes;
		}
		
		/**
		 * Checks if a given arc type is inverted.
		 */
		public static function isArcTypeInverted(type:String):Boolean {
			var inverted:Boolean = (type != null) && invertedArcTypesMap.containsKey(type);
			return inverted;
		}
		
		/**
		 * Sets whether an arc type is inverted.
		 */
		public static function setArcTypeInverted(type:String, inverted:Boolean):void {
			if (type != null) {
				// make sure it is in the list of all arc types too
				if (_allArcTypes.indexOf(type) == -1) {
					trace("** Adding a new arc type: " + type + " (" + (inverted ? "inverted)" : "not inverted)"));
					allArcTypes.push(type);
				}
				if (inverted) {
					invertedArcTypesMap.setValue(type, true);
				} else {
					invertedArcTypesMap.removeValue(type);	
				}
			}
		}

	}
}