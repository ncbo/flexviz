package org.ncbo.uvic.flex.model
{
	
	/**
	 * Simple interface for NCBOConcept and NCBOSearchResultConcept since they 
	 * both define id and name properties.
	 * 
	 * @author Chris Callendar
	 */
	public interface IConcept extends INCBOItem
	{
		
		/** The ontology version id. */
		function get ontologyVersionID():String;
		
	}
}