package org.ncbo.uvic.flex.util
{
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import flex.utils.StringUtils;
	
	import org.ncbo.uvic.flex.logging.LogService;
	import org.ncbo.uvic.flex.model.IConcept;
	import org.ncbo.uvic.flex.model.IOntology;
	
	
	/**
	 * Contains some utility functions for opening ontology or concept pages in BioPortal.
	 * By default the pages are opened in a new (re-usable) window, but can also
	 * be opened in the same window as Flex is currently running in using the 
	 * SAME_WINDOW constant.
	 * 
	 * @author Chris Callendar
	 * @date March 5th, 2009
	 */
	public class NavigateToBioPortal
	{
		
		public static const SAME_WINDOW:String = "_self";
		public static const NEW_WINDOW:String = "_blank";
		
		public static const DEFAULT_BASE_URL:String = "http://bioportal.bioontology.org/";
		
		public static const LOG_LINK:String = "link";
		public static const LOG_DOWNLOAD:String = "download";
		
		private static var _baseURL:String = DEFAULT_BASE_URL;
		
		public static function get baseURL():String {
			return _baseURL;
		}
		
		public static function set baseURL(url:String):void {
			if (url) {
				if (url.charAt(url.length - 1) != "/") {
					url = url + "/"; 
				}
				if (!StringUtils.startsWith(url, "http://", true)) {
					url = "http://" + url;
				}
				_baseURL = url;
			}
		}
		
		public static function get downloadURL():String {
			return baseURL + "bioportal/ontologies/download/";
		}
		
		public static function get downloadVirtualURL():String {
			return baseURL + "bioportal/virtual/download/";
		}
		
		/**
		 * Opens up the view ontology metadata page in BioPortal.
		 */
		public static function viewOntologyMetaDataByID(ontologyVersionID:String, window:String = "ViewOntologyWindow"):void {
			var url:String = getBioPortalOntologyMetaDataURL(ontologyVersionID);
			if (url != null) {
				navigateToURL(new URLRequest(url), window);
				LogService.logOntologyEvent3(ontologyVersionID, "", "", LOG_LINK);
			}
		}
		
		/**
		 * Opens up the view ontology metadata page in BioPortal.
		 */
		public static function viewOntologyMetaData(ontology:IOntology, window:String = "ViewOntologyWindow"):void {
			if (ontology) {
				var url:String = getBioPortalOntologyMetaDataURL(ontology.id);
				if (url != null) {
					navigateToURL(new URLRequest(url), window);
					LogService.logOntologyEvent(ontology, LOG_LINK);
				}
			}
		}
		
		/**
		 * Opens up the view ontology page in BioPortal, showing the root concepts.
		 */
		public static function viewOntologyByID(ontologyID:String, window:String = "ViewOntologyWindow", isVirtual:Boolean = false):void {
			var url:String = getBioPortalURL(ontologyID, "", isVirtual);
			if (url != null) {
				navigateToURL(new URLRequest(url), window);
				LogService.logOntologyEvent3((isVirtual ? "" : ontologyID), "", (isVirtual ? ontologyID : ""), LOG_LINK);
			}
		}
		
		/**
		 * Opens up the view ontology page in BioPortal, showing the root concepts.
		 */
		public static function viewOntology(ontology:IOntology, window:String = "ViewOntologyWindow", 
											isVirtual:Boolean = false):void {
			if (ontology) {
				var url:String = getBioPortalURL((isVirtual ? ontology.ontologyID : ontology.ontologyVersionID), "", isVirtual);
				if (url != null) {
					navigateToURL(new URLRequest(url), window);
					LogService.logOntologyEvent(ontology, LOG_LINK);
				}
			}
		}
		
		/**
		 * Opens up the view concept page in BioPortal, may take a while to load.
		 */
		public static function viewConceptByID(conceptID:String, ontologyID:String, window:String = "ViewConceptWindow", 
											   isVirtual:Boolean = false):void {
			var url:String = getBioPortalURL(ontologyID, conceptID, isVirtual);
			if (url != null) {
				navigateToURL(new URLRequest(url), window);
				if (isVirtual) {
					LogService.logConceptEvent3(conceptID, "", "", ontologyID, LOG_LINK);
				} else {
					LogService.logConceptEvent3(conceptID, "", ontologyID, "", LOG_LINK);
				}
			}
		}
		
		/**
		 * Opens up the view concept page in BioPortal, may take a while to load.
		 */
		public static function viewConcept(concept:IConcept, ontologyID:String, window:String = "ViewConceptWindow", 
										   isVirtual:Boolean = false):void {
			if (concept) {
				var url:String = getBioPortalURL(ontologyID, concept.id, isVirtual);
				if (url != null) {
					navigateToURL(new URLRequest(url), window);
					if (isVirtual) {
						LogService.logConceptEvent(concept, ontologyID, LOG_LINK);
					} else {
						LogService.logConceptEvent(concept, "", LOG_LINK);
					}
				}
			}
		}
		
		/**
		 * Returns the URL for the concept in BioPortal.
		 * @isVirtual if true then the ontologyID is the virtual id, if false (default) then
		 * the ontologyID is assumed to be the version id.
		 */
		public static function getBioPortalURL(ontologyID:String, conceptID:String = "", 
											   isVirtual:Boolean = false):String {
			var url:String = null;
			if (ontologyID.length > 0) {
				// September 25th 2009 - changed from "visualize" to "visconcepts"
				// November 10th 2009 - changed back to visualize, and changed from ?id= to ?conceptid=
				// April 19th 2010 - virtual changed to /visualize/virtual, and supports ?conceptid parameter
				url = baseURL + "visualize/" + (isVirtual ? "virtual/" : "") + ontologyID;
				if (conceptID.length > 0) {
					// need to URL encode the concept ID
					var encodedID:String = encodeURIComponent(conceptID);
					// the virtual service doesn't accept the ?conceptid parameter
					// but starting April 19th 2010 it will support it
					//if (!isVirtual) {
	    				encodedID = "?conceptid=" + encodedID;
	    			//}
					url = url + "/" + encodedID;
				}
			}
			return url;
		}
		
		/**
		 * Returns the URL for the ontology metadata in BioPortal.
		 */
		public static function getBioPortalOntologyMetaDataURL(ontologyVersionID:String):String {
			var url:String = null;
			if (ontologyVersionID) {
				url = baseURL + "ontologies/" + ontologyVersionID;
			}
			return url;
		}
		
		/**
		 * Opens in a new window the link to download the given ontology, which can either be
		 * by version id or virtual id.
		 */
		public static function downloadOntology(ontology:IOntology, isVirtual:Boolean = false):void {
			if (ontology) {
				var url:String;
				if (isVirtual && ontology.ontologyID) {
					url = downloadVirtualURL + ontology.ontologyID;
				} else { 
					url = downloadURL + ontology.ontologyVersionID;
				}
				navigateToURL(new URLRequest(url), "DownloadWindow");
				LogService.logOntologyEvent(ontology, LOG_DOWNLOAD);
			}
		}

	}
}