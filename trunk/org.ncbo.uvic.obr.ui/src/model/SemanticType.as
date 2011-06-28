package model
{
	public class SemanticType
	{
		
		public var id:String;
		public var name:String;
		
		public function SemanticType(id:String = "", name:String = "") {
			this.id = id;
			this.name = name;
		}
		
		public function get type():String {
			return id;
		}
		
		public function toString():String {
			return name;
		}

		public function get nameAndID():String {
			return name + " [" + id + "]";
		}
		
	}
}