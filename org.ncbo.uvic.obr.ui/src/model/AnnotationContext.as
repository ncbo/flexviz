package model
{
	import flex.utils.StringUtils;
	
	
	/**
	 * Defines the properties of an annotation context - the context name,
	 * the term id and name, and the mgrep offsets.
	 * 
	 * @author Chris Callendar
	 * @date February 2009
	 */
	public class AnnotationContext
	{
		
		private static const MGREP:String = "mgrepContext";
		private static const MAPPING:String = "mappingContext";
		private static const ISA:String = "isaContext";
		private static const OLD_MGREP:String = "mgrepContextBean";
		private static const OLD_MAPPING:String = "mappingContextBean";
		private static const OLD_ISA:String = "isaContextBean";
		
		public var contextClass:String;		// java class name and package
		public var name:String;
		public var isDirect:Boolean;
		
		public var conceptID:String;
		private var _conceptName:String;
		public var ontologyVersionID:String;
		
		// Mgrep only
		public var offsetStart:Number;
		public var offsetEnd:Number;
		// Extract just the sentence from the full text  
		public var sentence:String;
		public var sentenceOffset:Number;
		
		// Mapping only
		public var mappingType:String;
		
		// Is_a closure only
		public var level:String;
		
		
		private var _nameNoResource:String;
		private var _mgrep:Boolean;
		private var _mapping:Boolean;
		private var _isa:Boolean;
		
		public function AnnotationContext(name:String, contextClass:String = "", direct:Boolean = false) {
			this.name = name;
			this.contextClass = contextClass;
			this.isDirect = direct;
			this._mgrep = (MGREP == contextClass) || (OLD_MGREP == contextClass);
			this._mapping = (MAPPING == contextClass) || (OLD_MAPPING == contextClass);
			this._isa = (ISA == contextClass) || (OLD_ISA == contextClass);
			
			this.conceptID = "";
			this._conceptName = "";
			this.ontologyVersionID = "";
			// Mgrep
			this.offsetStart = -1;
			this.offsetEnd = -1;
			this.sentence = "";
			this.sentenceOffset = 0;
			// Mapping
			this.mappingType = "";
			// IsA
			this.level = "";
			
			// When searching by resource element the name is like "AE_name", "AE_description", 
			// When annotating it is just "MAPPING", "MGREP", etc
			var und:int = name.indexOf("_");
			if (und != -1) {
				_nameNoResource = name.substr(und + 1);
			} else {
				_nameNoResource = name;
			}
		}
		
		public function toString():String {
			return name + ": " + conceptName + " [" + conceptID + "]";
		}
		
		public function setConceptID(fullConceptID:String):void {
			// the fullConceptID is like ontologyID/conceptID
			var split:Array = fullConceptID.split("/");
			if (split.length == 2) {
				ontologyVersionID = split[0];
				conceptID = split[1];
			} else {
				conceptID = fullConceptID;
			}
		}
		
		public function setMgrep(fullConceptID:String, conceptName:String, start:Number, end:Number):void {
			setConceptID(fullConceptID);
			this._conceptName = conceptName;
			offsetStart = start;
			offsetEnd = end;
		}
		
		public function setMapping(fullConceptID:String, conceptName:String, type:String, start:Number = -1, end:Number = -1):void {
			setConceptID(fullConceptID);
			this._conceptName = conceptName;
			mappingType = type;
			offsetStart = start;
			offsetEnd = end;
		} 
		
		public function setIsA(conceptID:String, conceptName:String, ontologyID:String, level:String, start:Number = -1, end:Number = -1):void {
			this.conceptID = conceptID;
			this._conceptName = conceptName;
			this.ontologyVersionID = ontologyID;
			this.level = level;
			offsetStart = start;
			offsetEnd = end;
		}
		
		/**
		 * Returns the name of the context without the resource name.
		 * The name is usually something like "AE_name" or "AE_description", so 
		 * this function returns just "name" or "description".
		 */
		public function get nameWithoutResource():String {
			return _nameNoResource;
		}
		
		public function get fullConceptID():String {
			return ontologyVersionID + "/" + conceptID;
		}
		
		public function get conceptName():String {
			return (_conceptName.length == 0 ? conceptID : _conceptName);
		}
		
		public function set conceptName(value:String):void {
			_conceptName = (value ? value : "");
		}
		
		public function get isMgrep():Boolean {
			return _mgrep;
		}
		
		public function get isMapping():Boolean {
			return _mapping;
		}
		
		public function get isIsaClosure():Boolean {
			return _isa;
		}
		
		/**
		 * Compares two contexts to see if they contain the same information.
		 */
		public function equals(context:AnnotationContext):Boolean {
			if (context == this) {
				return true;
			}
			var same:Boolean = (contextClass == context.contextClass) && (name == context.name) &&
				(conceptID == context.conceptID) && (ontologyVersionID == context.ontologyVersionID);
			if (same) {
				if (isMgrep) {
					same = (offsetStart == context.offsetStart) && (offsetEnd == context.offsetEnd);
				} else if (isMapping) {
					same = (mappingType == context.mappingType);
				} else if (isIsaClosure) {
					same = (level == context.level);
				}
			}
			return same;
		}
		
	}
}