package org.ncbo.uvic.flex.events
{
	import org.ncbo.uvic.flex.model.NCBOOntologyMetrics;
	
	public class NCBOOntologyMetricsEvent extends NCBOEvent
	{

		public function NCBOOntologyMetricsEvent(metrics:NCBOOntologyMetrics = null, error:Error = null) {
			super((metrics == null ? null : [ metrics ]), "NCBOOntologyMetricsEvent", error);
		}
		
		public function get metrics():NCBOOntologyMetrics {
			return (item as NCBOOntologyMetrics);
		}
		
	}
}