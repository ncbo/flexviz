package org.ncbo.uvic.flex.ui
{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import flex.utils.ArrayUtils;
	import flex.utils.ui.Spinner;
	import flex.utils.ui.chooser.Chooser;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.controls.List;
	import mx.core.Application;
	import mx.events.FlexEvent;
	
	import org.ncbo.uvic.flex.IRestService;
	import org.ncbo.uvic.flex.events.NCBOSearchEvent;
	import org.ncbo.uvic.flex.model.IOntology;
	import org.ncbo.uvic.flex.search.SearchParams;

	[Event(name="enterPressed", type="flash.events.KeyboardEvent")]
	[Event(name="ontologyChanged", type="flash.events.Event")]
	[Event(name="minTextLengthChanged", type="flash.events.Event")]
	[Event(name="maxSearchResultsChanged", type="flash.events.Event")]

	/**
	 * Uses a flex.utils.ui.chooser.Chooser component to show an autocompleting
	 * text box.  The autocompletion is done using the NCBO rest services by searching.
	 * 
	 * @author Chris Callendar
	 * @date March 30th, 2010
	 */
	public class AutoCompleteSearchBox extends Canvas
	{
		
		public static const ENTER_PRESSED:String = "enterPressed";
		
		private var _chooser:Chooser;
		private var _spinner:Spinner;
		
		private var previousSearches:ArrayCollection = new ArrayCollection();
		private var timeoutID:uint = 0;
		private var searchParams:SearchParams;
		private var searchInProgress:Boolean;
		private var autoCompleteCache:Object;
		
		public var service:IRestService;
		private var _ontology:IOntology;
		private var _minTextLength:uint;
		
		public function AutoCompleteSearchBox() {
			super();
			this._minTextLength = 3;
			
			this.searchParams = new SearchParams();
			this.searchParams.pageSize = 10;
			this.autoCompleteCache = new Object();
			
			addEventListener(FlexEvent.CREATION_COMPLETE, created);
		}
		
		public function get chooser():Chooser  {
			if (_chooser == null) {
				_chooser = new Chooser();
				_chooser.matchType = Chooser.MATCH_ANY_PART;
				_chooser.dataProvider = previousSearches;
				_chooser.percentWidth = 100;
				_chooser.addEventListener(KeyboardEvent.KEY_DOWN, chooserKeyDown);
				_chooser.addEventListener(KeyboardEvent.KEY_UP, chooserKeyUp);
			}
			return _chooser;
		}
		
		public function get spinner():Spinner {
			if (!_spinner) {
				_spinner = new Spinner();
				_spinner.visible = false;
			}
			return _spinner;
		}
		
		override public function set enabled(value:Boolean):void {
			super.enabled = value;
			chooser.enabled = value;
		}
		
		[Bindable("ontologyChanged")]
		public function get ontology():IOntology { 
			return _ontology;
		}
		
		/**
		 * Sets the ontology to restrict the search on.
		 * Set to null to search across all ontologies.
		 */
		public function set ontology(value:IOntology):void {
			if (value != _ontology) {
				_ontology = value;
				searchParams.removeAllOntologies();
				if (value) {
					searchParams.addOntology(value);
				}
				autoCompleteCache = new Object();	// clear the recent search cache
				dispatchEvent(new Event("ontologyChanged"));
			}
		}
		
		public function get prompt():String {
			return chooser.prompt;
		}
		
		public function set prompt(value:String):void {
			chooser.prompt = value;
		}
		
		[Bindable("minTextLengthChanged")]
		public function get minTextLength():uint {
			return _minTextLength;
		}
		
		/**
		 * Sets the minimum text length to start autocompleting.
		 * Must be 1 or greater.  Defaults to 3.
		 */
		[Inspectable(category="Common", defaultValue="3")]
		public function set minTextLength(min:uint):void {
			if (min != _minTextLength) {
				_minTextLength = Math.max(1, min);
				dispatchEvent(new Event("minTextLengthChanged"));
			}
		}
		
		public function get text():String {
			return chooser.text;
		}
		
		[Inspectable(category="Common", defaultValue="")]
		public function set text(txt:String):void {
			chooser.text = txt;
		}
		
		[Bindable("maxSearchResultsChanged")]
		public function get maxSearchResults():uint {
			return searchParams.pageSize;
		}
		
		/**
		 * Sets the maximum number of search results to use in the autocompletion.
		 * Defaults to 10.  Must be at least 1.
		 */
		[Inspectable(category="Common", defaultValue="10")]
		public function set maxSearchResults(value:uint):void {
			if (value != searchParams.pageSize) {
				searchParams.pageSize = Math.min(1, value);
				dispatchEvent(new Event("maxSearchResultsChanged"));
			}
		}
		
		override protected function createChildren():void {
			super.createChildren();
			addChild(chooser);
			addChild(spinner);
		}
		
		private function created(event:FlexEvent):void {
			// make sure the size of the chooser dropdown is not too big
			if (chooser.combo) {
				var rowCount:int = chooser.combo.rowCount;
				var list:List = chooser.combo.dropDown;
				var rowHeight:Number = (isNaN(list.rowHeight) ? 26 : list.rowHeight);
				var dropDownHeight:Number = rowCount * rowHeight;
				var pt:Point = chooser.localToGlobal(new Point());
				var dropDownY:Number = pt.y + chooser.height;
				var appHeight:Number = Application.application.height;
				if (dropDownHeight > (appHeight - dropDownY)) {
					dropDownHeight = appHeight - dropDownY;
					rowCount = Math.floor(dropDownHeight / rowHeight);
					// set the explicit row count
					chooser.combo.rowCount = Math.max(2, rowCount);
				}
			}
		}
		
		private function chooserKeyDown(event:KeyboardEvent):void {
			// remove any previous search results
			if (previousSearches.length > 0) {
				previousSearches.removeAll();
			}
			chooser.hideDropDown();
		}
		
		private function chooserKeyUp(event:KeyboardEvent):void {
			if (event.keyCode == Keyboard.ENTER) {
				dispatchEvent(new KeyboardEvent(ENTER_PRESSED, false, false, event.charCode, 
					event.keyCode, event.keyLocation, event.ctrlKey, event.altKey, event.shiftKey));
			} else if (event.keyCode == Keyboard.ESCAPE) {
				cancelAutoComplete();
			} else {
				startAutoCompleteSearch();
			}
		}
		
		protected function startAutoCompleteSearch():void {
			// cancel a pending search
			if (timeoutID != 0) {
				clearTimeout(timeoutID);
			}

			var txt:String = chooser.text;
			if (txt.length >= minTextLength) {
				var lower:String = txt.toLowerCase();
				if (autoCompleteCache.hasOwnProperty(lower)) {
					// use the cached results
					var conceptNames:Array = (autoCompleteCache[lower] as Array);
					//trace("Loaded " + concepts.length + " cached results");
					showAutoCompleteConcepts(conceptNames);
				} else {
					timeoutID = setTimeout(autoCompleteSearch, 400);
				}
			}
		}
		
		protected function autoCompleteSearch():void {
			timeoutID = 0;
			var txt:String = chooser.text;
			searchParams.searchText = txt;
			// perform a search, and start the spinner
			startAutoCompleteSpinner();
			//trace("Searching for " + txt + "...");
			// don't log these searches since they are not complete
			searchInProgress = true;
			if (service) {
				service.search(searchParams, autoCompleteSearchResultHandler, false, false /* no log */);
			} else {
				trace("No service was set on AutoCompleteSearchBox!");
			}
		}
		
		private function autoCompleteSearchResultHandler(event:NCBOSearchEvent):void {
			if (spinner.visible) {
				spinner.stop();
				spinner.visible = false;
			}
			if (!event.isError && event.concepts) {
				// cache for next time - only save the unique concept names
				var conceptNames:Array = ArrayUtils.toArrayByProperty(event.concepts, null, true);
				var txt:String = event.searchText.toLowerCase();
				if (!autoCompleteCache.hasOwnProperty(txt)) {
					autoCompleteCache[txt] = conceptNames;
				}
				
				// if the user clicked "Go" while waiting for a search, then don't show the dropdown list!
				if (searchInProgress) {
					showAutoCompleteConcepts(conceptNames);
					searchInProgress = false;
				}
				//trace("Cached " + event.concepts.length + " autocomplete results");
			}
		}
		
		private function showAutoCompleteConcepts(conceptNames:Array):void {
			if (conceptNames.length > 0) {
				// need to clone this array because ArrayCollection.removeAll() will clear the array
				previousSearches.source = conceptNames.slice();
				chooser.updateDropDown();
			}
		}
	
		private function startAutoCompleteSpinner():void {
			spinner.x = width - spinner.width - 24/*clear button*/;
			spinner.y = Math.max(0, (height - spinner.height) / 2); 
			spinner.visible = true;
			spinner.start();
		}
		
		public function cancelAutoComplete():void {
			// cancel autocomplete search in progress
			if (searchInProgress) {
				searchInProgress = false;
			}
			if (timeoutID != 0) {
				clearTimeout(timeoutID);
				timeoutID = 0;
			}
			chooser.hideDropDown();
			if (spinner.visible) {
				spinner.stop();
				spinner.visible = false;
			}
		}
		
	}
}