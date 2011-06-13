package org.ncbo.uvic.flex.ui
{
	
	import ca.uvic.cs.chisel.flexviz.ui.HelpPanel;
	
	import flex.utils.ui.UIUtils;
	
	import org.ncbo.uvic.flex.NCBOVersion;
	
	/**
	 * Extends the default flexviz help to add Ontology specific help.
	 * 
	 * @author Chris Callendar
	 */
	public class NCBOHelpPanel extends HelpPanel
	{
		
		public function NCBOHelpPanel() {
			super();
		}
		
		override protected function createChildren():void {
			super.createChildren();
			xplist.headerTitle = "Help for BioPortal Ontology Visualization " + NCBOVersion.VERSION_DATE; 
			xplist.addChildAt(UIUtils.createLabel("Please note that some of the features listed below are only available in the full version."), 0);
		}
		
		override protected function createNavigationHelpData():Array {
			var data:Array = super.createNavigationHelpData();
            data.push(createHelpObject("Right click on the canvas to show the context menu", bulletIcon));
            data.push(createHelpObject("In the canvas context menu you can run layouts and more", indentedBulletIcon));
            data.push(createHelpObject("Right click on a node to show the context menu", bulletIcon));
            data.push(createHelpObject("'Focus On...' will show the local neighborhood for the selected node(s), hiding everything else", indentedBulletIcon));
            data.push(createHelpObject("'Show Neighborhood' will display all the parents and children for the selected node(s)", indentedBulletIcon));
            data.push(createHelpObject("'Show Parents' will display the parents for the selected node(s)", indentedBulletIcon));
            data.push(createHelpObject("'Show Children' will display the children are shown for the selected node(s)", indentedBulletIcon));
            data.push(createHelpObject("'Show Hierarchy To Root' will show the selected node and all of its ancestors, and highlights the path", indentedBulletIcon));
            data.push(createHelpObject("'Hide' will remove the selected node(s) from the graph", indentedBulletIcon));
            data.push(createHelpObject("There is also a 'Nodes' menu at the top with many more actions", bulletIcon));
            data.push(createHelpObject("Right click on an arc to show the context menu", bulletIcon));
            data.push(createHelpObject("'Hide' will remove the arc from the graph", indentedBulletIcon));
            return data;
  		}
		
		override protected function createLayoutsHelpData():Array {
			var data:Array = super.createLayoutsHelpData();
            data.push(createHelpObject("Layouts can also be run from the 'Layouts' menu at the top or from the canvas context menu", bulletIcon));
			return data;
		}
		
		override protected function createLabelsHelpData():Array {
			var data:Array = super.createLabelsHelpData();
			data.push(createHelpObject("Node labels and tooltips can be configured from the Nodes menu", bulletIcon));
			data.push(createHelpObject("Arc tooltips can be configured from the Arcs menu", bulletIcon));
			data.push(createHelpObject("For labels and tooltips only known properties can be used"));
			data.push(createHelpObject("If a property (eg rdfs:label) isn't listed then no nodes or arcs have that property"));
			return data;
		}
		
	}
}