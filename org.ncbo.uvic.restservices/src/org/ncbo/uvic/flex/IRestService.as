package org.ncbo.uvic.flex
{
	import org.ncbo.uvic.flex.model.NCBOOntology;
	import org.ncbo.uvic.flex.search.SearchMode;
	import org.ncbo.uvic.flex.search.SearchParams;
	
	
	/**
	 * Defines the following functions of the NCBO Rest Service: 
	 * <li>get all ontologies</li>
	 * <li>get an ontology by id</li>
	 * <li>get the roots of an ontology</li>
	 * <li>get a concept by id</li>
	 * <li>search for all concepts by name</li>
	 * <li>get the parents of a concept</li>
	 * <li>get the children of a concept</li>
	 * 
	 * @author Chris Callendar
	 * @date September 24th, 2008
	 */
	public interface IRestService
	{
		
		/** Returns true if logging is turned on. */
		function get log():Boolean;
		/** Sets whether logging is on. */
		function set log(value:Boolean):void;
		
		/**
		 * Loads all the ontology groups and returns them to the callback function.
		 * The callback will take one NCBOGroupsEvent parameter.
		 */
		function getOntologyGroups(callback:Function):void;
		
		/**
		 * Loads the ontology categories and returns them to the callback function.
		 * The callback will take one NCBOCategoriesEvent parameter.
		 */
		function getOntologyCategories(callback:Function):void;
	
	 	/**
 	     * Loads the all the NCBO ontologies, caches them, and passes them into 
 	     * the callback function wrapped in an NCBOOntologiesEvent parameter.
 	     * @param callback the callback function, should have one parameter - an NCBOOntologiesEvent
 	     */
	    function getNCBOOntologies(callback:Function):void;
	    
	    /**
	    * Makes a call to the REST services for the NCBOOntology with the given id
	    * if it doesn't exist in the cache.
	    * @param getExtraInfo if true then we ensure that all the ontology properties have been loaded.
	    * @param alertErrors if true and and error happens, an Alert box will show up displaying the error
	    */
	    function getNCBOOntology(id:String, callback:Function, getExtraInfo:Boolean = false, alertErrors:Boolean = true):void;

   	    /**
	     * Makes a call to the REST services for the NCBOOntology with the given ontology ID.
	     * This ontology ID is also referred to as the "virtual" ID since it never changes.
	     */ 
	    function getOntologyByVirtualID(virtualID:String, callback:Function, alertErrors:Boolean = true):void;

		/**
		 * Returns all the different ontology versions (NCBOOntology objects) for the given virtual id.
		 */ 
		function getOntologyVersions(virtualID:String, callback:Function):void;
		
		/**
		 * Returns the ontology metrics for the given ontology (either the version id or virtual id).
		 */
		function getOntologyMetrics(ontologyID:String, callback:Function, isVirtual:Boolean = false):void; 

	    /**
	     * Loads the root nodes for the given ontology.
	     * If the ontology has already loaded the roots, then the callback function is called immediately.
	     * Otherwise the rest service will go get the roots and then call the callback.
	     * The root nodes that get returned are not "owl:Thing" or "THING", instead they are 
	     * the children of "owl:Thing" or "THING".
	     * @param callback the function which gets called with the NCBOConceptsEvent object
	     */
	    function getTopLevelNodes(ontologyID:String, callback:Function):void;
	    
	    /**
	     * Gets a concept from an ontology by ID.  
	     * The callback function should accept one parameter - an NCBONodeEvent object.
	     * This function will first try to find the node from the cache, if it can't be found
	     * then it will make a call to the web service to find the node.
	     * @param ontologyID the id of the ontology
	     * @param conceptID the id of the concept to find
	     * @param callback the function to call when the concept has been found (takes one param - NCBOConceptEvent)
	     * @param loadNeighbors if true and if the concept doesn't have its neighbors loaded yet we make a 
	     * 	call to the rest services to load concept and therefore the neighbors too.
  	     * @param alertErrors if true and and error happens, an Alert box will show up displaying the error
  	     * @param light if true then the light version of the rest service XML is returned (basic concept info)
  	     * @param noRelations if true then the returned XML doesn't contain any relation information
	     */
	    function getConceptByID(ontologyID:String, conceptID:String, callback:Function, 
	    						loadNeighbors:Boolean = false, alertErrors:Boolean = true, 
	    						light:Boolean = false, noRelations:Boolean = false):void;
	    
	    /**
	     * Searches for concepts by name.
	     * This function only works on one ontology, which has to be passed in as a paramter.
	     * To search multiple ontologies, use the search() function instead.
	     * Currently the mode only supports contains (default) or exact match.
	     * The callback will take an NCBOSearchEvent parameter containing the search results.
	     */
	    function getConceptsByName(ontology:NCBOOntology, conceptName:String, mode:SearchMode, callback:Function):void;

	    /**
	     * Searches across multiple ontologies.
	     * Also supports paging, set the flags in the SearchParams object to get a specific page. 
	     * Currently the mode only supports contains (default) or exact match.
	     * The callback will take an NCBOSearchEvent parameter containing the search results.
	     * Note that the search results will be NCBOSearchResultOntology objects containing NCBOSearchResultConcept objects.
	     * These objects will have the same id's as the NCBOOntology and NCBOConcept objects, but not as much other information.
	     * @param searchParams the search parameters, includes the search text, the mode (contains/exact match) and the ontology ids.
	     * @param logEvent if false then the search event won't be logged
	     */
	    function search(searchParams:SearchParams, callback:Function, parseHits:Boolean = true, logEvent:Boolean = true):void;
	    
	    /**
	     * Loads the children concepts from the Rest services if they haven't already been loaded,
	     * and returns them to the callback function wrapped in a NCBOConceptsEvent.
	     * @param subClassesOnly if true then only the children that are specified as subclasses in the
	     *  					 rest services XML are returned. Otherwise all children are returned.
	     */
	    function getChildConcepts(ontologyID:String, conceptID:String, callback:Function,
	    						  subClassesOnly:Boolean = false):void;
	    
	    /**
	     * Loads the parents concepts from the Rest services if they haven't already been loaded,
	     * and returns them to the callback function wrapped in a NCBOConceptsEvent.
	     * @param superClassesOnly if true then only the parents that are specified as superclasses in the
	     *  					 rest services XML are returned. Otherwise all parents are returned.
	     */
	    function getParentConcepts(ontologyID:String, conceptID:String, callback:Function,
	    						  superClassesOnly:Boolean = false):void;
	
	 	/**
	     * Retrieves the path to root for the given concept and ontology.
	     * The returned event is an NCBOPathToRootEvent which contains the path to root.
	     * The path is an array of NCBOConcept objects (including the given concept)
	     * starting from the root and ending in the given concept.
	     * The root is not THING or owl:Thing, instead it is the visible root underneath Thing.
	     * @param ontologyID the id of the ontology
	     * @param conceptID the id of the concept to find the path to root
	     * @param callback the function which gets called with the NCBOPathToRootEvent object
	     */
	    function getPathToRoot(ontologyID:String, conceptID:String, callback:Function):void;
	
		/** 
		 * Clears the concepts from the cache.
		 * If the ontologyID is specified then only that ontology is cleared.
		 * If the ontologyID is null then ALL ontologies are cleared.
		 * @see NCBOOntology.clear()
		 * @param ontologyID [optional] only clears the concepts for a single ontology 
		 */
		function clearConcepts(ontologyID:String = null):void;

		/** Clears the ontologies from the cache. */
		function clearOntologies():void;
		
		/** Clears the loaded categories. */ 
	    function clearCategories():void;
		
	}
}