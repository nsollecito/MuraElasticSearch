<!---
    Mura Elastic Search
    
    License:
    Apache License
    Version 2.0, January 2004
    http://www.apache.org/licenses/
--->
<cfinclude template="plugin/config.cfm" />


<cfscript>
	$ = application.serviceFactory.getBean('$');

	search = new lib.searchService(siteId="default", configBean=$.globalConfig());

	//search.indexByRecordset(1, 10);
	writeDump(var=search.search(q="Running"));
</cfscript>

<cfsavecontent variable="variables.body">
	<cfoutput>
	<h2>Mura ElasticSearch</h2>
	<p>

	</p>
	</cfoutput>
</cfsavecontent>

<cfoutput>#application.pluginManager.renderAdminTemplate(body=variables.body,pageTitle=request.pluginConfig.getName())#</cfoutput>