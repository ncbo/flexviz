package renderers
{
	import flex.utils.ui.TextHighlighter;
	import flex.utils.ui.renderers.CheckBoxHighlighter;
	
	import org.ncbo.uvic.flex.doi.DegreeOfInterestService;
	import org.ncbo.uvic.flex.model.NCBOOntology;

	/**
	 * Adds DOI support for the ontology checkbox renderer.
	 * This is needed to use a custom styleName when the DOI is enabled,
	 * and has the default text highlighting when the DOI is not enabled.
	 * 
	 * @author Chris Callendar
	 */
	public class OntologyCheckBoxRenderer extends CheckBoxHighlighter
	{

		private static const DOI_ONTOLOGIES:String = "searchOntologies";
			
		private var styleNameSet:Boolean;

		public function OntologyCheckBoxRenderer(textHighlighter:TextHighlighter = null) {
			super(textHighlighter);
		}
		
		override public function newInstance():* {
			return new OntologyCheckBoxRenderer(highlighter);
		}
		
		override protected function updateDisplayList(w:Number, h:Number):void {
			var ontology:NCBOOntology = (data as NCBOOntology);
			if (DegreeOfInterestService.isHighlighting(DOI_ONTOLOGIES)) {
				var style:String = DegreeOfInterestService.getStyleName(ontology, DOI_ONTOLOGIES);
				if (style != styleName) {
					styleName = style;
					styleNameSet = true;
				}
			} else {
				if (styleNameSet && (styleName != null)) {
					styleName = null;
					styleNameSet = false;
				}
			}
			
			super.updateDisplayList(w, h);
		}
		
		override protected function highlightText():void {
			// only highlight if the DOI is turned off
			if (!styleNameSet) {
				super.highlightText();
			}
		}
		
	}
}