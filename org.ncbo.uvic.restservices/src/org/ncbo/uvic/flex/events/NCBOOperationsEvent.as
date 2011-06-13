package org.ncbo.uvic.flex.events
{
	import flex.utils.ArrayUtils;
	
	import org.ncbo.uvic.flex.model.NCBOConcept;
	

	/**
	 * Holds multiple concepts which were used in one or more operations as well 
	 * as the resulting neighbor concepts.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBOOperationsEvent extends NCBOOperationEvent 
	{
		
		private var _concepts:Array;
		
		public function NCBOOperationsEvent(neighborConcepts:Array = null, concepts:Array = null, error:Error = null) {
			super(neighborConcepts, (ArrayUtils.first(concepts) as NCBOConcept), error);
			this._concepts = (concepts == null ? new Array() : concepts);
		}
		
		public function get matchingConcepts():Array {
			return _concepts;
		}
		
	}
}