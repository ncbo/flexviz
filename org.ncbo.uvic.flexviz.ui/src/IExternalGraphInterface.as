package
{
	
	/**
	 * Defines the interface for JavaScript calls into FlexViz.
	 * 
	 * @author Chris Callendar
	 * @date December 18th, 2008
	 */
	public interface IExternalGraphInterface
	{
		
		/** Returns the id of the selected node or null. */
		function getSelectedNodeID():String;
		/** Returns the name of the selected node or null. */
		function getSelectedNodeName():String;
		/** Returns the ids of the selected nodes. */
		function getSelectedNodeIDs():Array;
		/** Returns the names of the selected nodes in an array. */
		function getSelectedNodeNames():Array;
		
		/**
		 * Selects a node with the given id.
		 * If the node doesn't exist in the graph then nothing happens.
		 * @param id the id of the node to select
		 * @param append if true then the node will be appended to the current selection
		 * if false then the node becomes the only selected node
		 */
		function selectNodeByID(id:String, append:Boolean = false):void;
		
		/**
		 * Focuses on the node with the given id.
		 * @param id the id of the node
		 * @param option the focus option - neighborhood, hierarchy to root, parents, children
		 * If not specified then the current option is used.
		 */
		function searchByID(id:String, option:String = null):void;
		
		/**
		 * Searches for the given concept/term by name, and shows the neighborhood or hierarchy to root.
		 * @param name the concept/term name to search for
		 * @param option the focus option - neighborhood, hierarchy to root, parents, children
		 * If not specified then the current option is used.
		 */ 
		function searchByName(name:String, option:String = null):void;
		
		/**
		 * Clears the graph.
		 */
		function clear():void;
		
		/**
		 * Loads an ontology, and possible focusses on a specific node.
		 * @param ontologyID the id of the ontology to show
		 * @param nodeID the optional id of the node to show, otherwise shows the roots
		 * @param isVirtual if true then the ontology id is a virtual id, if false then it is the version id 
		 * @param showOption the optional string specifying the show option.  Valid strings are:
		 *  "neighborhood", "children", "parents", "hierarchy".
		 */
		function loadOntology(ontologyID:String, nodeID:String = null, isVirtual:Boolean = false,
								showOption:String = null):void;
		
		/**
		 * Adds an item to the nodes layer context menu.  When the menu item is selected
		 * the JavaScript function is called with two parameters - the node id and name.
		 * @param menuItemID the id for the menu item
		 * @param label the label for the context menu item
		 * @param jsCallbackFunctionName the name of the JavaScript function to called when the
		 * 	context menu is selected. It should take 4 parameters: the node id, node name,
		 * 	menu item id, and the swf id.
		 */ 
		function addNodeContextMenuItem(menuItemID:String, label:String, jsCallbackFunctionName:String, 
										separatorBefore:Boolean = false):void;
		
		/** Adds a node mouse over listener which passes the event on to the javascript function. */
		function addNodeMouseOverListener(jsFunctionName:String):void;
		
		/** Sets the header label text. */
		function setHeaderText(text:String):void;
		
		/** Sets the footer label text. */
		function setFooterText(text:String):void;
		
	}
}