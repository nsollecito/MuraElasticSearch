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
	param name="variables.result" default="";

	search = new lib.searchService(siteId=siteId);
	pluginConfig = $.getPlugin('ElasticSearch');

	//writeDump(var=search.getPrivateSearchReplacement(siteId=siteId, keywords='City Livin'), abort=1);

	if ( isDefined('form.submit') ) { 
		if ( form.submit == 'Index Records' ) {
			result = search.indexByRecordset(argumentCollection=form);
		} else if ( form.submit == 'Update Record' ) {
			c = $.getBean('content').loadBy(contentid=form.contentid, siteid=siteid);
			result = search.indexItem(index=siteid, contentBean=c);
		} else if ( form.submit == 'Purge Index' ) {
			result = search.purgeIndex(index=siteid);
			location url="./" addToken=false;
		} else if ( form.submit == 'Generate Mapping' ) {
			result = search.generateMapping(index=siteid);
			location url="./" addToken=false;
		}
	}

	dbStats = search.getStats()['indices'][siteId]['total'];
</cfscript>

<cfsavecontent variable="variables.body">
	<cfoutput>

	<div class="row">
		<h2>Mura ElasticSearch</h2>
		
		<h3>Index Stats for #ucase(siteId)#</h3>
		<p class="alert">
			<strong>Doc Count:</strong> #dbStats.docs.count# <br/>
			<strong>Index Size:</strong> #dbStats.store.size_in_bytes# (bytes) <br/>
			<strong>Fetch Time:</strong> #dbStats.search.fetch_time_in_millis# <br/>
			<strong>Query Time:</strong> #dbStats.search.query_time_in_millis# <br/>
			<strong>Query Total:</strong> #dbStats.search.query_total#
		</p>
	</div>

	<div class="row">
		<div class="span5">
			<h3>Bulk Index Update</h3>
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
		</div>

		<div class="span5">
			<h3>Update Single Record</h3>
			<form action="" method="post">
				<label>
					Content Id:<br />
					<input type="text" name="contentid" value="">
				</label>
				<br />
				<input type="submit" name="submit" value="Update Record"/>
			</form>
		</div>
	</div>

	<div class="row">
		<div class="span5">
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
		</div>
		<div class="span5">
			<h3>Utility</h3>
			<p>
				<i class="icon-gears"></i> 
				When first setting up a new SiteId, you will need to generate the data mappings for the index in ElasticSearch. Make sure to Purge first.
			</p>
			<form action="" method="post">
				<select name="siteid">
					<cfloop query="#pluginConfig.getAssignedSites()#">
						<option value="#siteid#">#siteid#</option>
					</cfloop>
				</select>
				&nbsp;
				<input type="submit" name="submit" value="Generate Mapping"/>
			</form>
			
			<p>
				<i class="icon-warning-sign"></i> 
				Clear out the current index to rebuild.
			</p>
			<form action="" method="post">
				<select name="siteid">
					<cfloop query="#pluginConfig.getAssignedSites()#">
						<option value="#siteid#">#siteid#</option>
					</cfloop>
				</select>
				&nbsp;
				<input type="submit" name="submit" value="Purge Index"/>
			</form>
		</div>
	</div>

	<cfif isDefined("form.submit") && form.submit == 'Run Search'>
		<cfset thisSearch = search.getPublicSearchReplacement(siteId=siteId, keywords=form.q, returnFacets=1) />
		<div class="row">
			<cfdump var="#thisSearch#" />
		</div>

		<!---cfset results = thisSearch.hits.hits />

		<cfif !arrayLen(results)>
			<strong>No Results for #form.q#</strong>
		<cfelse>
			<p><strong>#arrayLen(results)#</strong> results returned in #thisSearch.took#ms.</p>
			<ol>
				<cfloop from="1" to="#arrayLen(results)#" index="a">
					<cfset thisRecord = results[a]['_source']>
					<li>
						<cfif len(thisRecord.thumbnail)>
							<img src="#thisRecord.thumbnail#" align="left" />
						</cfif>
						<strong>#dateFormat(thisRecord.releaseDate, 'short')# #thisRecord.title#</strong><br />
						<p>#thisRecord.summary#</p>
						<small>#thisRecord.credits# | ContentId: #thisRecord.contentId#</small>
					</li>
					<br clear="both" />
				</cfloop>
			</ol>
		</cfif--->
	</cfif>
	</cfoutput>
</cfsavecontent>

<cfoutput>#application.pluginManager.renderAdminTemplate(body=variables.body,pageTitle=request.pluginConfig.getName())#</cfoutput>