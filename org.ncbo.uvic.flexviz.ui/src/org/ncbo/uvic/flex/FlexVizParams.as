package org.ncbo.uvic.flex
{
	import ca.uvic.cs.chisel.flexviz.ExtendedFlexGraph;
	
	import flex.utils.Utils;
	
	import org.ncbo.uvic.flex.search.SearchBy;
	import org.ncbo.uvic.flex.search.SearchMode;
	
	
	/**
	 * Holds some default parameter names and values which 
	 * are used when passing parameters into Flex applications.
	 * 
	 * @author Chris Callendar
	 */
	public class FlexVizParams extends NCBOAppParams
	{

		public static const SEARCH_MODE:String 			= "searchmode"; 
		public static const SHOW:String 				= "show"; 
		public static const SEARCH_BY:String 			= "searchby";
		public static const USERID:String				= "userid"; 
		public static const HIDE_TOOLBAR:String			= ExtendedFlexGraph.PARAM_HIDE_TOOLBAR; 		// "hidetoolbar"
		public static const HIDE_SEARCHBAR:String		= ExtendedFlexGraph.PARAM_HIDE_SEARCHBAR; 		// "hidesearchbar"
		public static const HIDE_FILTERPANEL:String 	= ExtendedFlexGraph.PARAM_HIDE_FILTERPANEL; 	// "hidefilterpanel"
		public static const HIDE_TOPBAR:String			= "hidetopbar";			// basic
		public static const HIDE_FULLVERSION:String 	= "hidefullversion";	// basic
		public static const HIDE_EMAIL:String 	  		= "hideemail";			// basic
		public static const HIDE_BUG:String 	  	  	= "hidebug";			// basic
		public static const SHOW_ARC_LABELS:String		= "showarclabels"; 
		public static const ROTATE_ARC_LABELS:String  	= "rotatearclabels";
		public static const ADMIN_EMAIL:String 			= "adminemail";
		public static const BUG_URL:String 				= "bugurl";
		public static const CAN_CHANGE_ONTOLOGY:String	= "canchangeontology";
		public static const WIDGET:String				= "widget";
		public static const ALLOW_NAVIGATION:String		= "allownavigation";	// basic 
		public static const ALERT_NO_ONTOLOGY:String 	= "alertnoontology";	// basic
		public static const HIGHLIGHT_ARCS:String		= "highlightarcs";		// basic
		public static const NODE_TOOLTIPS:String		= "nodetooltips";
		public static const ARC_TOOLTIPS:String			= "arctooltips";
		public static const ANIMATE:String				= "animate";
		public static const SHOW_ONTOLOGY_NAME:String 	= "showontologyname";	// basic
		

		public static const DEFAULT_SEARCH_MODE:String			= SearchMode.CONTAINS.toString().toLowerCase();
		public static const DEFAULT_SEARCH_BY:String			= SearchBy.NAME.toString().toLowerCase();
		public static const DEFAULT_HIDE_TOOLBAR:Boolean		= true;
		public static const DEFAULT_HIDE_SEARCHBAR:Boolean		= true;
		public static const DEFAULT_HIDE_FILTERPANEL:Boolean	= true;
		public static const DEFAULT_HIDE_TOPBAR:Boolean			= false;
		public static const DEFAULT_HIDE_FULLVERSION:Boolean	= false;
		public static const DEFAULT_HIDE_EMAIL:Boolean			= false;
		public static const DEFAULT_HIDE_BUG:Boolean			= false;
		public static const DEFAULT_SHOW_ARC_LABELS:Boolean 	= true;
		public static const DEFAULT_ROTATE_ARC_LABELS:Boolean	= true;
		public static const DEFAULT_ADMIN_EMAIL:String			= "support@bioontology.org";
		public static const DEFAULT_BUG_URL:String				= "https://bmir-gforge.stanford.edu/gf/project/flexviz/tracker/";
		public static const DEFAULT_TITLE:String				= "BioPortal Ontology Visualization";
		public static const DEFAULT_CAN_CHANGE_ONTOLOGY:Boolean = true;
		public static const DEFAULT_WIDGET:Boolean 				= false;
		public static const DEFAULT_ALLOW_NAVIGATION:Boolean	= true;
		public static const DEFAULT_ALERT_NO_ONTOLOGY:Boolean 	= false;
		public static const DEFAULT_HIGHLIGHT_ARCS:Boolean 		= true;
		
		private static var singleton:FlexVizParams = null;
		
		private var parameters:Object;
		
		public function FlexVizParams() {
			if (FlexVizParams.singleton == null) {
				// browser params take precidence
				parameters = Utils.getCombinedParameters(true);
			} else {
				throw new Error("Singleton");
			}
		}
		
		private static function getInstance():FlexVizParams {
			if (singleton == null) {
				singleton = new FlexVizParams();
				var debug:Boolean = getBooleanParam(DEBUG, DEFAULT_DEBUG);
				if (debug) {
					Utils.printAllParameters(getParams());
				}
			}
			return singleton;
		}
		
		public static function addParams(moreParam:Object):void {
			var params:Object = getParams();
			for (var key:String in moreParam) {
				params[key] = moreParam[key];
			}
		}
		
		public static function getParams():Object {
			return getInstance().parameters;
		}
		
		public static function getParamsString(separator:String = "&"):String {
			return Utils.getParams(separator, getParams());
		}
		
		public static function getParam(key:String, def:String = null):String {
			var value:String = def;
			var params:Object = getInstance().parameters;
			if ((key != null) && (key.length > 0) && params.hasOwnProperty(key)) {
				value = String(params[key]);
			}
			return value;
		}
		
		public static function getBooleanParam(key:String, def:Boolean = false):Boolean {
			var str:String = getParam(key, ""+def);
			return Utils.toBoolean(str, def);
		}
		
		public static function getNumberParam(paramName:String, defaultValue:Number = 0):Number {
			var val:String = getParam(paramName, defaultValue.toString());
			return new Number(val);
		}
		
	}
}