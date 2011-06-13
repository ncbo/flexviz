package org.ncbo.uvic.flex.ui
{
	import flex.utils.ui.ContentWindow;
	
	import mx.core.Application;
	import mx.core.ScrollPolicy;
	import mx.events.FlexEvent;
	
	import org.ncbo.uvic.flex.model.NCBOConcept;

	/**
	 * Displays the concept's properties.
	 * 
	 * @author Chris Callendar
	 * @date December 12th, 2008
	 */
	public class ConceptPropertyWindow extends ContentWindow
	{
		
		private var _concept:NCBOConcept;
		private var form:ConceptPropertyPane;
		
		public function ConceptPropertyWindow(concept:NCBOConcept = null, canResize:Boolean = true, canMove:Boolean = true) {
			super(ContentWindow.OK, ContentWindow.OK);
			this.concept = concept;
			resizable = canResize;
			movable = canMove;
			minWidth = 100;
			minHeight = 100;
			if (concept != null) {
				title = "Properties for " + concept.name;
			}

			layout = "absolute"; 
			verticalScrollPolicy = ScrollPolicy.AUTO;
			horizontalScrollPolicy = ScrollPolicy.OFF;
			var app:Application = (Application.application as Application);
			width = Math.min(500, app.width - 20);
			height = Math.min(450, app.height - 20);
			setStyle("verticalGap", 2);
		}
		
		public function get concept():NCBOConcept {
			return _concept;
		}
		
		public function set concept(c:NCBOConcept):void {
			this._concept = c;
			if (form) {
				form.concept = c;
			}
		}
		
		override protected function createChildren():void {
			super.createChildren();
			
			form = new ConceptPropertyPane();
			form.x = 0;
			form.y = 0;
			form.percentWidth = 100;
			//form.percentHeight = 100;
			container.addChild(form);
			
			form.concept = concept;
		}
		
	}
}