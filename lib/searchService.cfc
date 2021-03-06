<cfcomponent extends="mura.cfobject" output="false">
<cfscript>
	variables.pluginConfig = "";
	variables.configBean = "";

	function init(string siteId, any pluginConfig, any configBean) {

		variables.configBean = arguments.configBean;
		variables.pluginConfig = arguments.pluginConfig;
		variables.dbType = variables.configBean.getDbType();

		// ElasticSearch server URL
		this.endPoint = "http://localhost:9200";

		if ( len(arguments.pluginConfig.getCustomSetting('endpoint')) )
			this.endPoint = arguments.pluginConfig.getCustomSetting('endpoint');


		variables.wrapper = new cfelasticsearch.cfelasticsearch.api.Wrapper();
		variables.siteId = arguments.siteId;
		variables.indexName = arguments.siteId;

		// make sure ElasticSearch is running
		if (!checkService()) {
			throw "Can't find ElasticSearch. Please check to make sure the service is running and your Endpoint setting is correct in the plugin.";
		}

		// make sure index exists
		try {
			variables.wrapper.createIndex(variables.indexName);
		} 
		catch(any e){};

		return this;
	}




	function checkService() {
		/* create new http service */ 
	    httpService = new http(); 

	    httpService.setMethod("GET"); 
	    httpService.setUrl( this.endPoint );

	    result = httpService.send().getPrefix();

		return result.statusCode=="200 OK";
	}



	function startService() {
		try {
			thread action="run" name="startElasticSearch" {
				execute name="#expandPath('./lib/elasticsearch/bin/elasticsearch')#" arguments="" variable="result" timeout=30 {}
			}
			return true;
		}
		catch(any e){
			return false;
		}
	}

	

	function indexItem(string index=variables,indexName, any contentBean) {

		return variables.wrapper.addDoc(
			index=arguments.index,
			type="content",
			doc={
				categoryid = listToArray(valueList(arguments.contentBean.getCategoriesQuery().categoryid)),
				contentid = arguments.contentBean.getContentId(),
				contenthistid = arguments.contentBean.getContentHistId(),
				siteid = arguments.contentbean.getSiteId(),
				title = arguments.contentBean.getTitle(),
				menutitle = arguments.contentBean.getMenuTitle(),
				summary = arguments.contentBean.getSummary(),
				body = arguments.contentBean.getBody(),
				tags = listToArray(arguments.contentBean.getTags()),
				type = arguments.contentBean.getType(),
				subtype = arguments.contentBean.getSubtype(),
				urlTitle = arguments.contentBean.getUrlTitle(),
				restricted = arguments.contentBean.getRestricted(),
				restrictgroups = arguments.contentBean.getRestrictGroups(),
				displaystart = arguments.contentBean.getDisplayStart(),
				displaystop = arguments.contentBean.getDisplayStop(),
				remotesource = arguments.contentBean.getRemoteSource(),
				remotesourceurl = arguments.contentBean.getRemoteSourceUrl(),
				remoteurl = arguments.contentBean.getRemoteUrl(),
				fileid = arguments.contentBean.getFileId(),
				path = listToArray(arguments.contentBean.getPath()),
				thumbnail = arguments.contentBean.getImageUrl(size="small", complete=true),
				isnav = arguments.contentBean.getIsNav(),
				searchexclude = arguments.contentBean.getSearchExclude(),
				credits = listToArray(arguments.contentBean.getCredits()),
				filename = arguments.contentBean.getFilename(),
				parentid = arguments.contentBean.getParentId(),
				metadesc = arguments.contentBean.getMetaDesc(),
				metakeywords = arguments.contentBean.getMetakeywords(),
				releasedate = arguments.contentBean.getReleaseDate(),
				lastupdate = arguments.contentBean.getLastUpdate()
			},
			idField='contentId'
		);
	}



	function indexByRecordset(numeric startRow=1, numeric maxRows=1) {
		var queryService = new query();
		var result = "";
		var aDocs = [];
		var aDateFields = listToArray(uCase("releasedate,lastupdate,created,displaystart,displaystop"));
		var $ = application.serviceFactory.getBean('$');

		session.siteId = variables.siteId;
	    
	    /* set properties using implict setters */ 
	    queryService.setDatasource(variables.configBean.getDatasource()); 
	    queryService.setName("rsContent"); 
	    queryService.setMaxRows(arguments.maxRows);

	    savecontent variable="myQuery" {
		    writeOutput("
		      SELECT 
				tcontent.contentid, tcontent.contenthistid, tcontent.siteid, tcontent.title, tcontent.menutitle, 
				tcontent.summary, tcontent.tags, tcontent.type, tcontent.subtype, tcontent.urltitle, 
				tcontent.restricted, tcontent.restrictgroups, tcontent.displaystart, tcontent.displaystop, 
				tcontent.remotesource, tcontent.remotesourceurl, tcontent.remoteurl, tcontent.fileid, tcontent.path, 
				tcontent.body, tcontent.isnav, tcontent.searchexclude, tcontent.credits, tcontent.filename,
				tcontent.parentid, tcontent.releasedate, tcontent.lastupdate, tcontent.created, tcontent.changesetid, 
				tcontent.mobileexclude
		      FROM tcontent
		      WHERE 
				  tcontent.active = 1
				  and tcontent.type in ('Page','Folder','Portal','Calendar','Gallery','Link','File')
				  and tcontent.siteID = '#variables.siteId#'
				  ORDER BY tcontent.lastupdate DESC
		    ");
		}

		// retrieve resultset by dbtype
		if (variables.dbType == 'mysql') {
		    result = queryService.execute(sql="
		    	#myQuery#
		    	LIMIT #arguments.maxRows# OFFSET #arguments.startRow#
		    ");
		} else if (variables.dbtype == 'oracle') {
		    result = queryService.execute(sql="
				SELECT * FROM (
					SELECT a.*, rownum rn
					FROM (#myQuery#) a
					WHERE rownum < #arguments.maxRows+arguments.startRow#)
				WHERE rn >= #arguments.startRow#
		    ");
		}

	    rsContent = result.getResult();

	    for (row in rsContent) {
	    	// format date fields
	    	for (thisField in aDateFields) {
    			formattedDate = dateFormat(row[thisField], "YYYY-mm-dd") & " " & timeFormat(row[thisField], "HH:mm:ss");
    			row[thisField] = formattedDate;
	    	}
	    	
	    	// get thumbnail image url
	    	if ( len(row['fileid']) )
	    		row['thumbnail'] = $.getContentRenderer().createHREFForImage(fileid=row['fileid'], size="small", complete=true);
	    	else
				row['thumbnail'] = "";

			// clean up control chars
			row['summary'] = reReplace(row['summary'],'[[:cntrl:]]','','all')
			row['body'] = reReplace(row['body'],'[[:cntrl:]]','','all')

			// any list items to arrays
			row['categoryids'] = listToArray(valueList($.getBean('contentManager').getCategoriesByHistID(row['contenthistid']).categoryid));
			row['tags'] = listToArray(row['tags']);
			row['credits'] = listToArray(row['credits']);
			row['path'] = listToArray(row['path']);

			// convert all structkeys to lowercase
			row = convertStructToLower(row);

	    	arrayAppend(aDocs, row);
		}

		result = variables.wrapper.addDocs(
			index=variables.indexName,
			type="content",
			docs=aDocs,
			idField='contentid'
		);

		variables.wrapper.refresh(index=variables.indexName);

		return result;
	}


	function getStats(string index=variables.indexName) {
		return variables.wrapper.getStats(arguments.index);
	}


	function deleteDoc(string index=variables.indexName, string contentId) {
		try {
			return variables.wrapper.deleteDoc(index=arguments.index, type="content", id=arguments.contentId);
		}
		catch(any e) {}
	}


	function search(string q, string index=variables.indexName, string type="content", page=1, pageSize=25) {
		return variables.wrapper.search(argumentCollection=arguments);
	}

</cfscript>


	<cffunction name="getPublicSearchReplacement" returntype="any" access="public" output="false">
		<cfargument name="siteid" type="string" required="true">
		<cfargument name="keywords" type="string" required="true">
		<cfargument name="tag" type="string" required="true" default="">
		<cfargument name="sectionID" type="string" required="true" default="">
		<cfargument name="categoryID" type="string" required="true" default="">

		<cfscript>
			variables.wrapper = new cfelasticsearch.cfelasticsearch.api.Wrapper();
			var result = "";
			var qResult = "";

			// search criteria
			body = {
				filtered = {
					query = {
						query_string = { query = arguments.keywords }
					}
					, 
					filter = {
						term = { searchexclude = 0 }
					}
				}
			};

			// tags
			if ( len(arguments.tag) ) {
				structAppend(body.filtered, 
				{
					filter = {
						term = { tags = arguments.tag }
					}
				}
				, false);
			};

			// if for specific section
			if ( len(arguments.sectionid) ) {
				structAppend(body.filtered, 
				{
					filter = {
						term = { parentid = arguments.sectionid }
					}
				}
				, false);
			};

			// category filter 
			if ( len(arguments.categoryid) ) {
				structAppend(body.filtered, 
				{
					filter = {
						term = { categoryids = "*#arguments.categoryid#*" }
					}
				}
				, false);
			};

			// display start-stop range
			structAppend(body, {
				range = {
					displayStart = {
						from = dateFormat(createDate(1845,1,1), "YYYY-MM-dd") & " 00:00:00",
						to = dateFormat(now(), "YYYY-MM-dd") & " " & timeFormat(now(), "HH:mm:ss"),
						include_upper = true
					}
				}
			}, false);

			// wrap query
			body = { query = body };

			// pagination
			/* structAppend(body, {
				from = 1, 
				size = 100
			}, false); */

			// facets
			structAppend(body, {
				facets = {
					tags = {
						terms = {field = "tags.facet"}
					},
					credits = {
						terms= {field = "credits.facet"}
					},
					subtype = {
						terms = {field = "subtype"}
					}
				}
			}, false);

			// sorting 
			structAppend(body, {
				sort = [
					{releasedate = {order = "desc", ignore_unmapped = true}},
					{lastupdate = {order = "desc", ignore_unmapped = true}},
					"_score"
				]
			}, false);

			// execute query
			result = variables.wrapper._call(
				  uri    = "/#arguments.siteid#/content/_search"
				, method = "POST"
				, body   = serializeJson( body )
			);

			// convert results to query
			qResult = queryNew( structKeyList(result.hits.hits[1]._source) );
			i = 1;

			for (hit in result.hits.hits) {
				thisRow = hit._source;
				queryAddRow(qResult);

				for ( thisCol in listToArray(structKeyList(thisRow)) ) {
					// handle array values
					if ( listFindNoCase("tags,path,credits,categoryids", thisCol) )
						querySetCell(qResult, thisCol, arrayToList(thisRow[thisCol]));
					else
						querySetCell(qResult, thisCol, thisRow[thisCol]);
				}
				i++
			}

			return qResult;
		</cfscript>

	</cffunction>


	<cffunction name="getPrivateSearchReplacement" returntype="query" access="public" output="false">
		<cfargument name="siteid" type="string" required="true">
		<cfargument name="keywords" type="string" required="true">
		<cfargument name="tag" type="string" required="true" default="">
		<cfargument name="sectionID" type="string" required="true" default="">
		<cfargument name="searchType" type="string" required="true" default="default" hint="Can be default or image">

		<cfscript>
			variables.wrapper = new cfelasticsearch.cfelasticsearch.api.Wrapper();
			var result = "";
			var qResult = "";

			// search criteria
			body = {
				filtered = {
					query = {
						query_string = { query = arguments.keywords }
					}
				}
			};

			// tags
			if ( len(arguments.tag) ) {
				structAppend(body.filtered, 
				{
					filter = {
						term = { tags = arguments.tag }
					}
				}
				, false);
			};

			// if for specific section
			if ( len(arguments.sectionid) ) {
				structAppend(body.filtered, 
				{
					filter = {
						term = { parentid = arguments.sectionid }
					}
				}
				, false);
			};

			// wrap query
			body = { query = body };

			// pagination
			body.from = 0;
			body.size = 100;

			// facets
			structAppend(body, {
				facets = {
					tags = {
						terms = {field = "tags.facet"}
					},
					credits = {
						terms= {field = "credits.facet"}
					},
					subtype = {
						terms = {field = "subtype"}
					}
				}
			}, false);

			// sorting 
			structAppend(body, {
				sort = [
					"_score"
				]
			}, false);

			// execute query
			result = variables.wrapper._call(
				  uri    = "/#arguments.siteid#/content/_search"
				, method = "POST"
				, body   = serializeJson( body )
			);

			// convert results to query
			if (arrayLen(result.hits.hits)) {
				qResult = queryNew( structKeyList(result.hits.hits[1]._source) );
				i = 1;

				for (hit in result.hits.hits) {
					thisRow = hit._source;
					queryAddRow(qResult);

					for ( thisCol in listToArray(structKeyList(thisRow)) ) {
						// handle array values
						if ( listFindNoCase("tags,path,credits,categoryids", thisCol) )
							querySetCell(qResult, thisCol, arrayToList(thisRow[thisCol]));
						else
							querySetCell(qResult, thisCol, thisRow[thisCol]);
					}
					i++
				}
			}

			return qResult;
		</cfscript>
	</cffunction>


	 <cffunction name="convertStructToLower" access="public" returntype="struct">
        <cfargument name="st" required="true" type="struct">

        <cfset var aKeys = structKeyArray(st)>
        <cfset var stN = structNew()>
        <cfset var i= 0>
        <cfset var ai= 0>
        <cfloop array="#aKeys#" index="i">
            <cfif isStruct(st[i])>
                <cfset stN['#lCase(i)#'] = convertStructToLower(st[i])>
            <cfelseif isArray(st[i])>
                <cfloop from=1 to="#arraylen(st[i])#" index="ai">
                    <cfif isStruct(st[i][ai])>
                        <cfset st[i][ai] = convertStructToLower(st[i][ai])>
                    <cfelse>
                        <cfset st[i][ai] = st[i][ai]>
                    </cfif>
                </cfloop>
                <cfset stN['#lcase(i)#'] = st[i]>
            <cfelse>
                <cfset stN['#lcase(i)#'] = st[i]>
            </cfif>
        </cfloop>
        <cfreturn stn>
    </cffunction>


</cfcomponent>