package org.ncbo.uvic.ontologytree
{
	import mx.collections.CursorBookmark;
	import mx.collections.IViewCursor;
	import mx.controls.Tree;
	import mx.core.ScrollPolicy;
	
	internal class CustomTree extends mx.controls.Tree
	{
		
		public function CustomTree() {
			super();
		}
		
		public function get firstVisibleItemIndex():int {
			return verticalScrollPosition - offscreenExtraRowsTop;
		}
		
		// similar to getItemIndex, but with an optional startIndex
	    public function getCustomItemIndex(item:Object, startIndex:int = 0):int {
	        var cursor:IViewCursor = collection.createCursor();
	        cursor.seek(CursorBookmark.FIRST, startIndex);
	        var i:int = startIndex;
	        do {
	            if (cursor.current === item) {
	                break;
	            }
	            i++;
	        }
	        while (cursor.moveNext());
			// set back to 0 in case a change event comes along
			// and causes the cursor to hit an unexpected IPE
			cursor.seek(CursorBookmark.FIRST, 0);
	        return i;
	    }
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			if (horizontalScrollPolicy != ScrollPolicy.OFF) {
				// we call measureWidthOfItems to get the max width of the item renderers.
				// then we see how much space we need to scroll, setting maxHorizontalScrollPosition appropriately
				var diffWidth:Number = measureWidthOfItems(0, 0) - (unscaledWidth - viewMetrics.left - viewMetrics.right);
				if (diffWidth <= 0) {
					maxHorizontalScrollPosition = NaN;
				} else {
					maxHorizontalScrollPosition = diffWidth;
				}
			}
			super.updateDisplayList(unscaledWidth, unscaledHeight);
		}
		
	}
}