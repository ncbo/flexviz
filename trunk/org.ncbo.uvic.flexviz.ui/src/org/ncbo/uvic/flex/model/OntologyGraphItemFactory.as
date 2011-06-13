package org.ncbo.uvic.flex.model
{
	import ca.uvic.cs.chisel.flexviz.model.DefaultGraphArc;
	import ca.uvic.cs.chisel.flexviz.model.DefaultGraphNode;
	import ca.uvic.cs.chisel.flexviz.model.IGraphArc;
	import ca.uvic.cs.chisel.flexviz.model.IGraphModel;
	import ca.uvic.cs.chisel.flexviz.model.IGraphNode;
	
	import org.ncbo.uvic.flex.NCBOToolTipProperties;
	
	/**
	 * Acts as the bridge between the NCBO ontologies and the FlexGraph nodes and arcs.
	 * Allows you to specify a label function that determines how the nodes are labeled.
	 * 
	 * @author Chris Callendar
	 * @date September 24th, 2008
	 */
	public class OntologyGraphItemFactory
	{
		
		private var _labelField:String;
		
		public function OntologyGraphItemFactory() {
			_labelField = null;
		}


		public function get labelField():String {
			return _labelField;
		}
		
		public function set labelField(field:String):void {
			_labelField = field;
		}
		
		/**
		 * Goes through every (cached) concept in the ontology and gets the 
		 * corresponding IGraphNode and updates the node's text value.
		 */
		public function reloadNodeLabels(ontology:NCBOOntology, model:IGraphModel):void {
			if (ontology && model) {
				var concepts:Array = ontology.cachedConcepts;
				for (var i:int = 0; i < concepts.length; i++) {
					var concept:NCBOConcept = NCBOConcept(concepts[i]);
					var node:IGraphNode = model.getNode(concept.id);
					if (node != null) {
						// update the text, this fires an event which causes the node
						// to be re-painted and updated with the new text
						node.text = getNodeText(concept);
					}
				}	
			}
		}
		
		/** 
		 * Creates and returns a new IGraphNode from the given concept.
		 */
		public function createNode(concept:NCBOConcept):IGraphNode {
			// the node's text value is set based on the labelField property
			var text:String = getNodeText(concept); 
			var node:IGraphNode = new DefaultGraphNode(concept.id, concept.type, text);
			// no point in setting the tooltip, we use our custom tooltip renderer
			node.tooltip = null;
			return node;
		}
		
		/**
		 * Determines what the node's text should be based on the labelField property.
		 * If the labelField isn't set, then the concept's name is used.
		 */
		protected function getNodeText(concept:NCBOConcept):String {
			var text:String = "";
			if (concept != null) {
				if (labelField != null) {
					// first check if it is one of the predefined concept fields
					if (labelField == NCBOToolTipProperties.ID) {
						text = concept.id; 
					} else if (labelField == NCBOToolTipProperties.NAME) {
						text = concept.name;
					} else if (labelField == NCBOToolTipProperties.TYPE) {
						text = concept.type;
					} else if (labelField == NCBOToolTipProperties.CHILD_COUNT) {
						text = concept.childCount.toString();
					} else if (labelField == NCBOToolTipProperties.PARENT_COUNT) {
						text = concept.parentCount.toString();
					} 
					// otherwise check if it is a property of the concept
					else if (concept.hasProperty(labelField)) {
						var value:Object = concept.getProperty(labelField);
						if (value is String) {
							text = String(value);
						} else if (value != null) {
							text = value.toString();
						}
					} else {
						text = (concept.name ? concept.name : concept.id);
					}
				} else {
					text = (concept.name ? concept.name : concept.id);
				}
			}
			return text;
		}
		
		
		/** Creates and returns a new IGraphArc from the given relationship. */
		public function createArc(rel:NCBORelationship, src:IGraphNode, 
							dest:IGraphNode, inverted:Boolean = false):IGraphArc {
			var arc:IGraphArc = new DefaultGraphArc(rel.id, src, dest, rel.type, null, inverted);
			return arc;
		}

	}
}