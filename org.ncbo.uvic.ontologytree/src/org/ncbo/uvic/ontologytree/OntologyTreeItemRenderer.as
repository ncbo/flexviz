package org.ncbo.uvic.ontologytree
{
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import flex.utils.ui.Spinner;
	
	import mx.controls.Tree;
	import mx.controls.treeClasses.TreeItemRenderer;
	import mx.core.IFactory;
	import mx.core.IToolTip;
	import mx.events.ToolTipEvent;
	
	import org.ncbo.uvic.flex.OntologyConstants;

	/**
	 * Extends the default TreeItemRenderer class to show a spinner icon
	 * when the children of the tree are loading.
	 * 
	 * @author Chris Callendar
	 * @date April 16th, 2009
	 */
	public class OntologyTreeItemRenderer extends TreeItemRenderer implements IFactory
	{
		
		[Embed(source='/assets/isa.gif')]
		private static const ISA_CLASS:Class;
		[Embed(source='/assets/partof.gif')]
		private static const PARTOF_CLASS:Class;
		[Embed(source='/assets/developsfrom.gif')]
		private static const DEVELOPS_CLASS:Class;
//		[Embed(source='/assets/regulates.gif')]
//		private static const REGULATES_CLASS:Class;
//		[Embed(source='/assets/regulates_up.gif')]
//		private static const REGULATES_POS_CLASS:Class;
//		[Embed(source='/assets/regulates_down.gif')]
//		private static const REGULATES_NEG_CLASS:Class;
		
		protected var spinner:Spinner;
		
		public function OntologyTreeItemRenderer(spinnerStyle:String = null) {
			super();
			spinner = new Spinner();
			spinner.styleName = spinnerStyle;
			doubleClickEnabled = true;
		}
		
		override protected function createChildren():void {
			super.createChildren();
			addEventListener(ToolTipEvent.TOOL_TIP_SHOW, toolTipShowHandler);
			
			// This prevents the TextField from being selected 
			// that way in mouse events the currentTarget will be this instead of the TextField
			if (label) {
				label.selectable = false;
				label.mouseEnabled = false;
			}
		}
		
		public function newInstance():* {
			return new OntologyTreeItemRenderer(spinner.styleName as String);
		}
				
		override protected function commitProperties():void {
			// the icon position is set in commitProperties()
			super.commitProperties();
			
			// now add or remove the spinner icon 
			var isLoading:Boolean = (data == OntologyDataDescriptor.LOADING);
			if (isLoading && spinner.parent == null) {
				addChild(spinner);
			} else if (!isLoading && (spinner.parent == this)) {
				removeChild(spinner);
			}
			spinner.running = isLoading && visible && (parent != null);
			if (icon) {
				icon.visible = !isLoading;
			}
			// check for the is_a and part_of relationships
			if (!isLoading) {
				var tree:Tree = (owner as Tree);
				// check if the tree already has a folder icon
				var folderClosedIcon:Object = (tree ? tree.getStyle("folderClosedIcon") : null);
				if (!folderClosedIcon) {
					updateIcon();
				}
			}
		}
		
		override protected function updateDisplayList(w:Number, h:Number):void {
			super.updateDisplayList(w, h);
			
			// position the spinner
			if (spinner.parent == this) {
				if (disclosureIcon) {
					spinner.x = disclosureIcon.x;
				} else if (icon) {
					spinner.x = icon.x - 1;
				} else if (label) {
					spinner.x = label.x - spinner.width - 1;
				}
			}
		}
	
		private function toolTipShowHandler(event:ToolTipEvent):void {
			var tt:IToolTip = event.toolTip;
			var pt:Point = localToGlobal(new Point());
			var tx:Number = tt.x;
			var ty:Number = pt.y + height;
			
			// don't let toolTip go outside the parent
			var parentLoc:Point = parent.localToGlobal(new Point());
			var bottom:Number = ty + tt.height;
			if (bottom > (parentLoc.y + parent.height)) {
				// position above
				ty = pt.y - tt.height;
			}

			// position below the current tree item and to the right of the mouse
			tt.move(tx, ty);
		}	
		
		private function updateIcon():void {
			var node:TreeNode = (data as TreeNode);
			if (node && node.parent) {
				var relType:String = node.relType;
				if (relType == OntologyConstants.IS_A) {
					setIcon(ISA_CLASS);
				} else if (relType.toLowerCase().indexOf("part") != -1) {
					setIcon(PARTOF_CLASS);
				} else if (relType == OntologyConstants.DEVELOPS_FROM) {
					setIcon(DEVELOPS_CLASS);
				}
			}
		}
		
		private function setIcon(iconClass:Class):void {
			if (icon) {
				removeChild(DisplayObject(icon));
			}
			icon = new iconClass();
			addChild(DisplayObject(icon));
		}
		
		
	}
}