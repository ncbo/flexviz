package org.ncbo.uvic.flex.events
{
	import flex.utils.ArrayUtils;
	
	import org.ncbo.uvic.flex.model.NCBOOntology;
	

	/**
	 * Holds multiple ontologies which were used in one or more operations.
	 * 
	 * @author Chris Callendar
	 * @date March 2nd, 2009
	 */
	public class NCBOOntologiesOperationsEvent extends NCBOOntologyOperationEvent 
	{
		
		private var _ontologies:Array;
		
		public function NCBOOntologiesOperationsEvent(ontologies:Array = null, error:Error = null) {
			super((ArrayUtils.first(ontologies) as NCBOOntology), error);
			this._ontologies = ontologies;
		}
		
		public function get ontologies():Array {
			return _ontologies;
		}
		
	}
}