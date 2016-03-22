<!---
    Mura ElasticSearch

    License:
    Apache License
    Version 2.0, January 2004
    http://www.apache.org/licenses/
--->
component extends="mura.plugin.pluginGenericEventHandler" {

	function onApplicationLoad($) {
		var contentGateway = $.getBean("contentGateway");

		variables.searchService = new lib.searchService(siteId=$.event('siteId'), pluginConfig=variables.pluginConfig, configBean=variables.configBean);

		variables.pluginConfig.addEventHandler(this);
		variables.pluginConfig.getApplication().setValue("searchService",variables.searchService);

		contentGateway.injectMethod("getPublicSearch#variables.pluginConfig.getPluginID()#", contentGateway.getPublicSearch);
		contentGateway.injectMethod("getPrivateSearch#variables.pluginConfig.getPluginID()#", contentGateway.getPrivateSearch);
		contentGateway.injectMethod("getPublicSearch", getPublicSearch);
		contentGateway.injectMethod("getPrivateSearch", getPrivateSearch);
	}


	function getPublicSearch(required string siteId, required string keywords, required string tag="", required string sectionID="", required string categoryID="") {
		var pConfig = application.pluginManager.getConfig('elasticSearch');
		var assignedSiteIds = valueList(pConfig.getAssignedSites().siteId);

		if ( listFindNoCase(assignedSiteIds, arguments.siteId) ) {
			return pConfig.getApplication().getValue('searchService').getPublicSearchReplacement(argumentCollection=arguments);
		} else {
			return evaluate("getPublicSearch#pConfig.getPluginID()#(argumentCollection=arguments)");
		}
	}


	function getPrivateSearch(required string siteId, required string keywords, required string tag="", required string sectionID="", required string categoryID="") {
		var pConfig = application.pluginManager.getConfig('elasticSearch');
		var assignedSiteIds = valueList(pConfig.getAssignedSites().siteId);

		if ( listFindNoCase(assignedSiteIds, arguments.siteId) ) {
			return pConfig.getApplication().getValue('searchService').getPrivateSearchReplacement(argumentCollection=arguments);
		} else {
			return evaluate("getPrivateSearch#pConfig.getPluginID()#(argumentCollection=arguments)");
		}
	}


	function onAfterContentSave($) {
		var content = arguments.$.event('newBean');
		var siteid=$.event('siteid');
		
		variables.searchService.indexItem(index=siteId, contentBean=content);
	}

	function onAfterContentDelete($) {
		var content=$.event("contentBean");
		var siteid=$.event('siteid');

		variables.searchService.deleteDoc(index=siteid, contentId=content.getContentId());
	}
}