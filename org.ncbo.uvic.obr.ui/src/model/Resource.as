package model
{
	import mx.utils.StringUtil;
	
	public class Resource
	{
		
		public var id:String;
		public var name:String;
		/** URL of the resource. */
		public var url:String;
		/** Base URL for a specific element in the resource. */
		public var elementURL:String;
		[Bindable]
		public var description:String;
		public var logo:String;
		
		public var mainContext:String;
		
		// loaded separated
		public var numAnnotations:int = 1;
		
		public function Resource(id:String, name:String, url:String = "", elementURL:String = "", 
								 desc:String = "", logo:String = "", mainContext:String = "") {
			this.id = id;
			this.name = name;
			this.url = StringUtil.trim(url);
			this.elementURL = StringUtil.trim(elementURL);
			this.description = StringUtil.trim(desc);
			this.logo = StringUtil.trim(logo);
			this.mainContext = mainContext;
		}
		
		public function toString():String {
			return nameAndID;
		}
		
		public function get nameAndID():String {
			var str:String = name;
			if (id.length > 0) {
				str += " [" + id + "]";
			}
			return str;
		}
		

	}
}