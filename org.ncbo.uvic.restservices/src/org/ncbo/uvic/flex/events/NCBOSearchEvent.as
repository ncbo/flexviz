package org.ncbo.uvic.flex.events
{
	import org.ncbo.uvic.flex.search.SearchParams;

	/**
	 * Holds the search results (Array of NCBOSearchResultOntology objects) and the search parameters.
	 * It also has the paging properties too.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBOSearchEvent extends NCBOEvent 
	{
		
		private var _params:SearchParams;
		
		// paging vars
		private var _pageNum:int;
		private var _numPages:int;
		private var _pageSize:int;
		private var _numResultsPage:int;
		private var _numResultsTotal:int;
		
		private var _ontologies:Array;  
		
		public function NCBOSearchEvent(concepts:Array = null, ontologies:Array = null, params:SearchParams = null, error:Error = null) {
			super(concepts, "NCBOSearchEvent", error);
			this._ontologies = (ontologies == null ? [] : ontologies);
			this._params = params;
			_pageNum = 1;
			_numPages = 1;
			_pageSize = 0;
			_numResultsPage = 0;
			_numResultsTotal = 0;
		}

		public function get ontologies():Array {
			return _ontologies;
		}
				
		public function get concepts():Array {
			return collection;
		}
		
		public function get searchParams():SearchParams {
			return _params;
		}
		
		public function get searchText():String {
			return (_params ? _params.searchText : ""); 
		}
		
		public function get pageNum():int {
			return _pageNum;
		}
		
		public function set pageNum(page:int):void {
			_pageNum = page;
		}
		
		public function get pageSize():int {
			return _pageSize;
		}
		
		public function set pageSize(size:int):void {
			_pageSize = size;
		}
		
		public function get numPages():int {
			return _numPages;
		}
		
		public function set numPages(pages:int):void {
			_numPages = pages;
		}
		
		public function get numResultsPage():int {
			return _numResultsPage;
		}
		
		public function set numResultsPage(results:int):void {
			_numResultsPage = results;
		}
		
		public function get numResultsTotal():int {
			return _numResultsTotal;
		}
		
		public function set numResultsTotal(total:int):void {
			_numResultsTotal = total;
		}
		
	}
}