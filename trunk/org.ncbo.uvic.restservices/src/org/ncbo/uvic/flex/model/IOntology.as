package org.ncbo.uvic.flex.model
{
	
	/**
	 * Simple interface for NCBOOntology and NCBOSearchResultOntology since they 
	 * define the id, ontolgyID, ontologyVersionID, and name properties.
	 * 
	 * @author Chris Callendar
	 */
	public interface IOntology extends INCBOItem
	{
		
		/** Returns the ontology id (also called the virtual id) - this is used for searching. */
		function get ontologyID():String;
		/** Returns the unique id for the ontology - this is the same as id. */
		function get ontologyVersionID():String;

	}
}