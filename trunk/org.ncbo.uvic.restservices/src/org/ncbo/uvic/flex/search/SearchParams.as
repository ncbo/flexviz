package org.ncbo.uvic.flex.search
{
	import flash.net.URLVariables;
	
	import flex.utils.DateUtils;
	import flex.utils.StringUtils;
	
	import mx.utils.StringUtil;
	
	import org.ncbo.uvic.flex.model.IOntology;
	
	/**
	 * Holds the various search parameters, and builds a query string
	 * from all of the parameters that aren't the defaults.
	 * The query string is property url-encoded.
	 * 
	 * @author Chris Callendar
	 */
	public class SearchParams
	{
		
		public var searchText:String;
		public var exactMatch:Boolean;
		public var includeAttributes:Boolean;
		public var pageSize:int;
		public var pageNum:int;
		public var date:Date;
		public var ontologyIDs:String;
		public var ontologyNames:String;
		
		// for previous search, not sent to server
		public var results:int;
		// maps to the database search event id
		public var id:uint;
		
		public function SearchParams(text:String = "") {
			searchText = text;
			exactMatch = false;
			includeAttributes = false;
			pageNum = -1;
			pageSize = -1;
			date = new Date();
			ontologyIDs = "";
			ontologyNames = "";
			
			results = -1;
			id = 0;
		}
		
		public function toString():String {
			var str:String = searchText;
			if (ontologyNames.length > 0) {
				str += " (" + (ontologyNames.length > 40 ? 
					StringUtil.trim(ontologyNames.substr(0, 40)) + "..." : ontologyNames) + ")";
			}
			return str;
		}
		
		/**
		 * Compares this to the given params.
		 * They are deemed equal if they have the same values for
		 * the searchText, ontologyIDs, exactMatch, and includeAttributes.
		 */
		public function equals(params:SearchParams):Boolean {
			if (this == params) {
				return true;
			}
			if (params != null) {
				if ((searchText == params.searchText) && 
					(ontologyIDs == params.ontologyIDs) && 
					(exactMatch == params.exactMatch) &&
					(includeAttributes == params.includeAttributes)) {
					return true;
				}
			}
			return false;
		}
		
		/**
		 * Builds a query string out of the search parameters like:
		 * ?query=searchText&pagesize=5&pagenum=1&includeproperties=true&isexactmatch=true&ontologyids=1020,1030
		 * Default values won't be included in the query string.
		 * The query string is encoded using a URLVariables object.
		 */
		public function get queryString():String {
			// old way
			//var escapedText:String = StringUtils.encodeURLString(searchText);

			// use a URLVariables object to encode the query string
			var vars:URLVariables = new URLVariables();

			// April 7th, 2010 - new way of passing in search queries to handle special characters like "/"
			vars.query = searchText;
			
			if (exactMatch) {
				vars.isexactmatch = 1;
			}
			if (includeAttributes) {
				vars.includeproperties = 1;
			}
			if (pageSize > 0) {
				vars.pagesize = pageSize;
			}
			if (pageNum > 0) {
				vars.pagenum = pageNum;
			}
			if (ontologyIDs.length > 0) {
				vars.ontologyids = ontologyIDs;
			}
			// encodes the string
			var query:String = vars.toString();
			
			// old way
//			if (query.length > 0) {
//	    		query = "?" + query;
//	    	}
//			return escapedText + query;
			
			// new way - include the searchText in the query
			return "?" + query;
		}
		
		public function get isValid():Boolean {
			return (searchText.length >= 2);
		}
				
		public function addOntology(ontology:IOntology):void {
			if ((ontology != null) && (ontology.ontologyID.length > 0)) {
				if (ontologyIDs.length > 0) {
					ontologyIDs += ",";
					ontologyNames += ", ";
				}
				ontologyIDs += ontology.ontologyID;
				if ((ontology as Object).hasOwnProperty("nameAndAbbreviation")) {
					ontologyNames += (ontology as Object)["nameAndAbbreviation"];
				} else {
					ontologyNames += ontology.name;
				}
			}
		}
		
		public function removeAllOntologies():void {
			ontologyIDs = "";
			ontologyNames = "";
		}
		
		public function get ontologyIDsArray():Array {
			return (ontologyIDs.length == 0 ? [] : ontologyIDs.split(","));
		}
				
		public static function parse(obj:Object):SearchParams {
			var params:SearchParams = new SearchParams();
			params.searchText = (obj.searchText as String);
			if (obj.hasOwnProperty("date")) {
				params.date = (obj.date as Date);
			} else if (obj.hasOwnProperty("dateString")) {	// from PHP
				params.date = DateUtils.parseSQLDate(obj.dateString);
			}
			params.exactMatch = (obj.exactMatch as Boolean);
			params.includeAttributes = (obj.includeAttributes as Boolean);
			// legacy
			if (obj.hasOwnProperty("includeProperties")) {
				params.includeAttributes = (obj.includeProperties as Boolean);
			}
			params.pageNum = (obj.pageNum as int);
			params.pageSize = (obj.pageSize as int);
			if (obj.ontologyIDs != null) {
				params.ontologyIDs = (obj.ontologyIDs as String);
			}
			if (obj.ontologyNames != null) {
				params.ontologyNames = (obj.ontologyNames as String);
			}
			params.results = int(obj.results);
			params.id = uint(obj.id);
			return params;
		}
		
	}
}