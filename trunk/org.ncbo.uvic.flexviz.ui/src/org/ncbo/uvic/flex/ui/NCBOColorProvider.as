package org.ncbo.uvic.flex.ui
{
	import ca.uvic.cs.chisel.flexviz.renderers.DefaultColorProvider;
	
	import org.ncbo.uvic.flex.OntologyConstants;

	/**
	 * Custom color provider for ontologies.  
	 * Uses the list of known node and arc types and assigns colors for each type.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBOColorProvider extends DefaultColorProvider
	{
		
		public function NCBOColorProvider() {
			super();
			
			assignColorsForKnownNodeTypes();
			assignColorsForKnownArcTypes();
		}

		private function assignColorsForKnownNodeTypes():void {
			// keep the same color for Classes, Terms, Properties, and Individuals
			nodeColors[OntologyConstants.TERM] = defaultNodeColors[0];
			nodeColors[OntologyConstants.OWL_CLASS] = defaultNodeColors[0];
			nodeColors[OntologyConstants.CLASS] = defaultNodeColors[0];
			nodeColors[OntologyConstants.PROPERTY] = defaultNodeColors[1];
			nodeColors[OntologyConstants.INDIVIDUAL] = defaultNodeColors[3];
			// keep the GroupedNode the same color as it used to be
			nodeColors[OntologyConstants.GROUPED_CONCEPTS] = defaultNodeColors[2];
			// assign any other node types
			assignColorsForNodeTypes(OntologyConstants.allNodeTypes); 
		}
		
		private function assignColorsForKnownArcTypes():void {
			assignColorsForArcTypes(OntologyConstants.allArcTypes); 
		}
		
	}
}