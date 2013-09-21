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
	siteId = session.siteId;

	param name="form.maxRows" default="1000";
	param name="form.startRow" default="1";
	param name="form.q" default="";

	search = new lib.searchService(siteId=siteId, configBean=$.globalConfig());

	dbStats = search.getStats()['indices'][siteId]['total'];

	if ( isDefined('form.submit') ) { 
		if ( form.submit == 'Index Records' )
			search.indexByRecordset(argumentCollection=form);
	}

</cfscript>

<cfsavecontent variable="variables.body">
	<cfoutput>
	<h2>Mura ElasticSearch</h2>
	<p></p>
	<hr size=1 />

	<h3>Index Stats</h3>
	<p>
		<strong>Doc Count:</strong> #dbStats.docs.count# <br/>
		<strong>Index Size:</strong> #dbStats.store.size# (#dbStats.store.size_in_bytes# bytes) <br/>
		<strong>Fetch Time: </strong> #dbStats.search.fetch_time# <br/>
		<strong>Query Time: </strong> #dbStats.search.query_time# <br/>
		<strong>Query Total: </strong> #dbStats.search.query_total#
	</p>
	<hr size=1 />
	
	<h3>Bulk Index Update</h3>
	<p>
		<form action="" method="post">
			<label>
				Number of Records:<br />
				<input type="text" name="maxRows" value="#form.maxRows#">
			</label>
			<label>
				Start Row:<br />
				<input type="text" name="startRow" value="#form.startRow#">
			</label>
			<br />
			<input type="submit" name="submit" value="Index Records"/>
		</form>
	</p>
	<hr size=1 />

	<h3>Search</h3>
	<p>
		<form action="" method="post">
			<label>
				Keywords:<br />
				<input type="text" name="q" value="#form.q#">
			</label>
			<br />
			<input type="submit" name="submit" value="Run Search"/>
		</form>
	</p>
	<cfif isDefined("form.submit") && form.submit == 'Run Search'>
		<cfdump var="#search.search(argumentCollection=form)#">
	</cfif>
	</cfoutput>
</cfsavecontent>

<cfoutput>#application.pluginManager.renderAdminTemplate(body=variables.body,pageTitle=request.pluginConfig.getName())#</cfoutput>