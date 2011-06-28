package model
{
	
	/**
	 * Holds the number of annotations for each annotation type: 
	 * 	- direct name
	 * 	- direct description
	 * 	- isa closure on name
	 * 	- isa closure on description
	 * 
	 * @author Chris Callendar
	 * @date March 3rd, 2009
	 */
	public class AnnotationStats
	{
		
		public var name:String;				// contextName
		public var annotationCount:int;		// nbAnnotation
		
		public function AnnotationStats(name:String = "", count:int = 0) {
			this.name = name;
			this.annotationCount = count;
		}
		
		public function toString():String {
			return name + ": " + annotationCount;
		}

	}
}