package org.ncbo.uvic.flex
{
	import org.ncbo.uvic.flex.util.NavigateToBioPortal;
	
	/**
	 * Holds the parameter names and default values
	 * that are used in many of the Flex applications.
	 */ 
	public class NCBOAppParams
	{

		/**
		 * Defines whether we are in debug mode (true/false)
		 * Defaults to false.
		 */
		public static const DEBUG:String = "debug";
		
		/**
		 * Defines the base Rest Services URL.
		 * Defaults to "http://rest.bioontology.org/bioportal/".
		 */
		public static const SERVER:String = "server";
		
		/**
		 * Defines the base redirect URL for BioPortal.
		 * This link is used when opening terms or ontologies in BioPortal.
		 * Defaults to "http://bioportal.bioontology.org/".
		 */
		public static const REDIRECT_URL:String = "redirecturl";
		
		/**
		 * Defines an optional search string to use.
		 * Defaults to "".
		 */
		public static const SEARCH:String = "search";
		
		/**
		 * Defines an optional ontology id (virtual id), or a comma-separated list of ontology ids.
		 * Defaults to "".
		 */
		public static const ONTOLOGY:String = "ontology";
		
		/**
		 * Defines whether the above ontology parameter is the virtual ontology id of the version id.
		 */
		public static const ONTOLOGY_VIRTUAL:String	= "virtual";

		/**
		 * The id of the node/term/concept to show on startup.
		 */
		public static const NODE_ID:String = "nodeid"; 
		
		public static const TITLE:String= "title";
		
		/** 
		 * Defines the optional logging parameter. Defaults to false. 
		 */
		public static const LOG:String = "log";
		
		public static const LOGGING:String = "logging";
		
		public static const DEFAULT_ONTOLOGY:String		= "";
		public static const DEFAULT_ONTOLOGY_VIRTUAL:Boolean = false;
		public static const DEFAULT_SEARCH:String		= "";
		public static const DEFAULT_NODE_ID:String		= "";
		public static const DEFAULT_DEBUG:Boolean		= false;
		public static const DEFAULT_LOG:Boolean 		= false;

	}
}