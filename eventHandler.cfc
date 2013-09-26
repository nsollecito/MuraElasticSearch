<!---
    Mura ElasticSearch

    License:
    Apache License
    Version 2.0, January 2004
    http://www.apache.org/licenses/
--->
<cfcomponent extends="mura.plugin.pluginGenericEventHandler">
<cfscript>
	function onApplicationLoad($) {
		var contentGateway=getBean("contentGateway")
		
		variables.pluginConfig.addEventHandler(this);
		variables.searchService = new lib.searchService(siteId=$.event('siteId'), pluginConfig=variables.pluginConfig, configBean=variables.configBean);

		//contentGateway.injectMethod("getPublicSearch#variables.pluginConfig.getPluginID()#", contentGateway.getPublicSearch);
		//contentGateway.injectMethod("getPrivateSearch#variables.pluginConfig.getPluginID()#",contentGateway.getPrivateSearch);

		contentGateway.injectMethod("getPrivateSearch", searchService.getPrivateSearchReplacement);
		contentGateway.injectMethod("getPublicSearch", searchService.getPublicSearchReplacement);
	}

	function onAfterContentSave($) {
		var content = $.event('contentBean');
		if ( content.getActive() && listFindNoCase("Page,Folder,Portal,Calendar,Gallery,Link,File", content.getType()) )
			variables.searchService.indexItem(content);
	}

	function onAfterContentDelete($) {
		var content=$.event("contentBean")
		variables.searchService.deleteDoc(content.getContentId());	
	}

</cfscript>
</cfcomponent>