package util
{
	public class ResourceElementID
	{
		
		public var elementID:String;
		public var resourceID:String;
		
		public function ResourceElementID(elementID:String, resourceID:String) {
			this.elementID = elementID;
			this.resourceID = resourceID;
		}
		
		public function toString():String {
			return elementID + " (" + resourceID + ")";
		}

	}
}