package obs.client;

import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.methods.PostMethod;

public class ObaClient {
	
	public static final String obsUrl = "http://ncbolabs-dev2.stanford.edu:8080/OBS_v1/oba/";
	//public static final String obsUrl = "http://localhost:8080/OBS_v1/oba/";

	private static String text = "Osteosarcoma TE85 cell tissue culture study Amino acid conjugated surfaces and controls";
	
	public static void main( String[] args ) {
		 System.out.println("********************* OBA CLIENT TEST ************************* \n");
		 try {
			 HttpClient client = new HttpClient();
			 PostMethod method = new PostMethod(obsUrl);

			 // Configure the form parameters
			 method.addParameter("scored", "true");
			 method.addParameter("text", text);
			 method.addParameter("format", "asText");
			 method.addParameter("localOntologyIDs", "SNOMEDCT,13578,MSH,NCI");
			 method.addParameter("levelMin", "0");
			 method.addParameter("levelMax", "0");
			 //method.addParameter("localSemanticTypeIDs", "T047,T048,T191");
			 method.addParameter("mappingTypes", "null");
				 

			 // Execute the POST method
			 int statusCode = client.executeMethod(method);
			 if( statusCode != -1 ) {
				 String contents = method.getResponseBodyAsString();
				 method.releaseConnection();
				 System.out.println(contents);
			 }
		 }
		 catch( Exception e ) {
			 e.printStackTrace();
		 }
	 }

}
