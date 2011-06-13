package org.ncbo.uvic.flex.filter
{
	import ca.uvic.cs.chisel.flexviz.filter.OrphanNodeFilter;
	import ca.uvic.cs.chisel.flexviz.model.IGraphItem;
	
	import org.ncbo.uvic.flex.search.NCBOSearchProvider;

	public class NCBOOrphanNodeFilter extends OrphanNodeFilter
	{
		public function NCBOOrphanNodeFilter(on:Boolean = true) {
			super(on);
		}
		
		override public function isVisible(item:IGraphItem):Boolean {
			// special case for roots - always show them
			if (item.getProperty(NCBOSearchProvider.PROP_ROOT) == true) {
				return true;
			}
			return super.isVisible(item);
		}
		
	}
}