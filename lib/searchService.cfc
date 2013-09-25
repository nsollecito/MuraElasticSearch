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
			flush interval="100";
			writeOutput("Starting ElasticSearch...");
			startService();
			sleep(8000);
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

	

	function indexItem(any contentBean) {
		return variables.wrapper.addDoc(
			index=variables.indexName,
			type="content",
			doc={
				contentid = arguments.contentBean.getContentId(),
				contenthistid = arguments.contentBean.getContentHistId(),
				siteid = arguments.contentbean.getSiteId(),
				title = arguments.contentBean.getTitle(),
				menutitle = arguments.contentBean.getMenuTitle(),
				summary = arguments.contentBean.getSummary(),
				body = arguments.contentBean.getBody(),
				tags = arguments.contentBean.getTags(),
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
				path = arguments.contentBean.getPath(),
				// thumbnail = toBinary($.getFile);
				isnav = arguments.contentBean.getIsNav(),
				searchexclude = arguments.contentBean.getSearchExclude(),
				credits = arguments.contentBean.getCredits(),
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
		var aDateFields = listToArray("releasedate,lastupdate,created,expires,displaystart,displaystop");
	    
	    /* set properties using implict setters */ 
	    queryService.setDatasource(variables.configBean.getDatasource()); 
	    queryService.setName("rsContent"); 
	    queryService.setMaxRows(arguments.maxRows);


	    savecontent variable="myQuery" {
		    writeOutput("
		      SELECT 
				contentid, contenthistid, siteid, title, menutitle, summary, tags, type, subtype, 
				urltitle, restricted, restrictgroups, displaystart, displaystop, remotesource, 
				remotesourceurl, remoteurl, fileid, path, body, isnav, searchexclude, credits, filename,
				lastupdate, parentid, releasedate, lastupdate, created, expires
		      FROM tcontent
		      WHERE 
				  active = 1
				  and type in ('Page','Folder','Portal','Calendar','Gallery','Link','File')
				  and siteID = '#variables.siteId#'
				  ORDER BY lastUpdate DESC
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
	    		if ( isDate(row[thisField]) ) {
	    			formattedDate = dateFormat(row[thisField], "YYYY-mm-dd") & " " & timeFormat(row[thisField], "HH:mm:ss");
	    			row[thisField] = formattedDate;
	    		} else {
	    			row[thisField] = javaCast("null", "");
	    		}
	    	}

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


	function deleteDoc(string contentId) {
		return variables.wrapper.deleteDoc(index=variables.index, id=arguments.contentId);
	}


	function search(string q, string index=variables.indexName, string type="content", page=1, pageSize=25) {
		return variables.wrapper.search(argumentCollection=arguments);
	}

</cfscript>


	<cffunction name="getPublicSearchReplacement" returntype="query" access="public" output="false">
		<cfargument name="siteid" type="string" required="true">
		<cfargument name="keywords" type="string" required="true">
		<cfargument name="tag" type="string" required="true" default="">
		<cfargument name="sectionID" type="string" required="true" default="">
		<cfargument name="categoryID" type="string" required="true" default="">

		<cfscript>
			var result = "";

			// search criteria
			body = {
				filtered = {
					query = {
						query_string = { query = arguments.keywords }
					}, 
					filter = {
						bool = {
							must = {
								term = { searchexclude = false }
							}
						}
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
						term = { categoryid = "*#arguments.categoryid#*" }
					}
				}
				, false);
			};

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
						terms = {field = "tags"}
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
					{releasedate = {order = "asc", ignore_unmapped = true}},
					{lastupdate = {order = "asc", ignore_unmapped = true}},
					"_score"
				]
			}, false);

			// execute query
			result = variables.wrapper._call(
				  uri    = "/#arguments.siteid#/content/_search"
				, method = "POST"
				, body   = serializeJson( body )
			);

			writeDump(var=result, abort=1);
		</cfscript>

	</cffunction>


	<cffunction name="getPrivateSearchReplacement" returntype="query" access="public" output="false">
		<cfargument name="siteid" type="string" required="true">
		<cfargument name="keywords" type="string" required="true">
		<cfargument name="tag" type="string" required="true" default="">
		<cfargument name="sectionID" type="string" required="true" default="">
		<cfargument name="searchType" type="string" required="true" default="default" hint="Can be default or image">

		<cfreturn arrayOfStructsToQuery(variables.wrapper.search(argumentCollection=arguments)) />
	</cffunction>		

</cfcomponent>