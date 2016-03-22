<cfcomponent extends="mura.cfobject" output="false">

<cfscript>	
	function init(string siteId) {
		variables.$ = application.serviceFactory.getBean('$').init(arguments.siteId);
		variables.configBean = $.globalConfig();
		variables.pluginConfig = $.getPlugin('ElasticSearch');
		variables.dbType = variables.configBean.getDbType();

		// ElasticSearch server URL
		this.endPoint = "http://localhost:9200";

		if ( len(variables.pluginConfig.getSetting('endpoint')) ) {
			this.endPoint = variables.pluginConfig.getSetting('endpoint');
		}


		variables.wrapper = new cfelasticsearch.cfelasticsearch.api.Wrapper().init(this.endPoint);
		variables.siteId = arguments.siteId;
		variables.indexName = arguments.siteId;

		// make sure ElasticSearch is running
		if (!checkService()) {
			writeLog(text="Can't find ElasticSearch", file="Application");
			// throw "Can't find ElasticSearch. Please check to make sure the service is running and your Endpoint setting is correct in the plugin.";
		}

		// make sure index exists
		try {
			variables.wrapper.createIndex(variables.indexName);
		} 
		catch(any e){};

		return this;
	}


	function purgeIndex(string index) {
		return variables.wrapper.deleteIndex(arguments.index);
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
		
		var thisDoc = {
			categoryids = listToArray(valueList(arguments.contentBean.getCategoriesQuery().categoryid)),
			contentid = arguments.contentBean.getContentId(),
			contenthistid = arguments.contentBean.getContentHistId(),
			siteid = arguments.contentbean.getSiteId(),
			title = arguments.contentBean.getTitle(),
			menutitle = arguments.contentBean.getMenuTitle(),
			summary = reReplace(arguments.contentBean.getSummary(),"[[:cntrl:]]","","all"),
			body = reReplace(arguments.contentBean.getBody(),"[[:cntrl:]]","","all"),
			tags = listToArray(arguments.contentBean.getTags()),
			type = arguments.contentBean.getType(),
			subtype = arguments.contentBean.getSubtype(),
			urltitle = arguments.contentBean.getUrlTitle(),
			restricted = arguments.contentBean.getRestricted(),
			restrictgroups = arguments.contentBean.getRestrictGroups(),
			display = arguments.contentBean.getDisplay(),
			displaystart = dateFormat(arguments.contentBean.getDisplayStart(), "YYYY-mm-dd") & " " & timeFormat(arguments.contentBean.getDisplayStart(), "HH:mm:ss"),
			displaystop = dateFormat(arguments.contentBean.getDisplayStop(), "YYYY-mm-dd") & " " & timeFormat(arguments.contentBean.getDisplayStop(), "HH:mm:ss"),
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
			releasedate = dateFormat(arguments.contentBean.getReleaseDate(), "YYYY-mm-dd") & " " & timeFormat(arguments.contentBean.getReleaseDate(), "HH:mm:ss"),
			lastupdate = dateFormat(arguments.contentBean.getLastUpdate(), "YYYY-mm-dd") & " " & timeFormat(arguments.contentBean.getLastUpdate(), "HH:mm:ss"),
			created = dateFormat(arguments.contentBean.getCreated(), "YYYY-mm-dd") & " " & timeFormat(arguments.contentBean.getCreated(), "HH:mm:ss"),
			filesize = arguments.contentBean.getFileSize(),
			fileext = arguments.contentBean.getFileExt(),
			active = arguments.contentBean.getActive(),
			approved = arguments.contentBean.getApproved(),
			assocfilename = arguments.contentBean.getAssocFilename()
		}

		var extAttributes = contentBean.getExtendedAttributesQuery();

		for (thisAtt in extAttributes) {
			if (len(trim(thisAtt.name))) {
				structInsert(thisDoc, thisAtt.name, thisAtt.attributevalue, true);
			}
		}

		return variables.wrapper.addDoc(
			index=arguments.index,
			type="content",
			id=arguments.contentBean.getContentId(),
			doc=thisDoc
		);
	}



	function indexByRecordset(numeric startRow=1, numeric maxRows=1) {
		var queryService = new query();
		var result = "";
		var aDocs = [];
		var aDateFields = listToArray(uCase("releasedate,lastupdate,created,displaystart,displaystop"));
		var $ = application.serviceFactory.getBean('$').init(variables.siteId);

	    /* set properties using implict setters */ 
	    queryService.setDatasource(variables.configBean.getDatasource()); 
	    queryService.setName("rsContent"); 
	    queryService.setMaxRows(arguments.maxRows);
	    queryService.addParam(name="siteid", value=variables.siteId, CFSQLTYPE="cf_sql_varchar");

	    savecontent variable="myQuery" {
		    writeOutput("
		      SELECT 
				tcontent.contentid, tcontent.contenthistid, tcontent.siteid, tcontent.title, tcontent.menutitle, 
				tcontent.summary, tcontent.tags, tcontent.type, tcontent.subtype, tcontent.urltitle, 
				tcontent.restricted, tcontent.restrictgroups, tcontent.displaystart, tcontent.displaystop, 
				tcontent.remotesource, tcontent.remotesourceurl, tcontent.remoteurl, tcontent.fileid, tcontent.path, 
				tcontent.body, tcontent.isnav, tcontent.searchexclude, tcontent.credits, tcontent.filename,
				tcontent.parentid, tcontent.releasedate, tcontent.lastupdate, tcontent.created, tcontent.changesetid, 
				tcontent.active, tcontent.approved,
				tcontent.mobileexclude, tcontent.display, tfiles.filesize, tfiles.fileext, 
				tfiles.filename as assocfilename
		      FROM tcontent
		      	LEFT OUTER JOIN tfiles ON (tcontent.fileid=tfiles.fileid)
		      WHERE 
				  tcontent.active = 1
				  and tcontent.type in ('Page','Folder','Portal','Calendar','Gallery','Link','File')
				  and tcontent.siteID = :siteid
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
	    	// fetch extended attributes
	    	thisContentHistId = row['contentHistId'];
	    	result = queryService.execute(sql="
				SELECT tclassextendattributes.name, tclassextenddata.attributevalue
					FROM tclassextenddata
				INNER JOIN tclassextendattributes ON (tclassextenddata.attributeID=tclassextendattributes.attributeID)
					WHERE tclassextendattributes.siteid='#variables.siteid#'
					AND tclassextenddata.baseID = '#thisContentHistId#'
	    	");

	    	rsExtData = result.getResult();

	    	for (extRow in rsExtData) {
	    		row[extRow.name] = extRow.attributevalue;
	    	}

	    	// format date fields
	    	for (thisField in aDateFields) {
    			formattedDate = dateFormat(row[thisField], "YYYY-mm-dd") & " " & timeFormat(row[thisField], "HH:mm:ss");
    			row[thisField] = trim(formattedDate);
	    	}
	    	
	    	// get thumbnail image url
	    	if ( len(row['fileid']) ) {
	    		row['thumbnail'] = $.getContentRenderer().createHREFForImage(siteId=variables.siteId, fileid=row['fileid'], size="small", complete=true);
	    	}
	    	else {
				row['thumbnail'] = "";
			}

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
			idfield="contentid"
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


	function generateMapping(string index) {
		savecontent variable="jsMapping" {
			include template="index_def_json.cfm"
		}
		return variables.wrapper.createMapping(arguments.index, "content", jsMapping);
	}
</cfscript>


	<cffunction name="quickSearch" returntype="any" access="public" output="false">
		<cfargument name="siteid" type="string" required="true">
		<cfargument name="keywords" type="string" required="true">
		<cfargument name="startdate" type="date" required="false" default="#createDate(1845,1,1)#">
		<cfargument name="enddate" type="date" required="false" default="#now()#">

		<cfscript>
			variables.pluginConfig = application.serviceFactory.getBean('$').getPlugin('ElasticSearch');
			variables.wrapper = new cfelasticsearch.cfelasticsearch.api.Wrapper().init(variables.pluginConfig.getSetting('endpoint'));
			var result = "";
			var qResult = queryNew("contentid,contenthistid,title,summary,display,filename,urltitle,type,subtype,tags,credits,releasedate");

			// escape any special characters
			listfrom = '+,-,&&,||,!,(,),{,},[,],^,",~,*,?,\';
			listto = '\+,\-,\&&,\||,\!,\(,\),\{,\},\[,\],\^,\",\~,\*,\?,\\';

			var keywords = replaceList(arguments.keywords, listfrom, listto);
			//arguments.keywords = replace(arguments.keywords,"/","","all");

			if (!len(trim(keywords))) {
				keywords = "*";
			}

			// search criteria
			body = {
			    query = {
			    	match_phrase_prefix = {
				        title = {
				            query = arguments.keywords
				        }
				    }
			    }, 
				filter = {
					"and" = [
						{ 
							bool = {
								must = {
									term = {
										searchexclude = 0,
										approved = 1
									}
								}
							} 
						},
						{
							range = {
								display = {
									"gt" = 0
								}
							}
						},
						{
							range = {
								releasedate = {
									"gte" = dateFormat(arguments.startDate, 'YYYY-MM-DD') & ' ' & timeFormat(arguments.startDate, 'hh:mm:ss'),
									"lte" = dateFormat(arguments.endDate, 'YYYY-MM-DD') & ' ' & timeFormat(arguments.endDate, 'hh:mm:ss')
								}
							}
						}
					]
				}
			}

			// execute query
			result = variables.wrapper._call(
				  uri    = "/#arguments.siteid#/content/_search"
				, method = "POST"
				, body   = serializeJson( body )
			);

			// convert results to query
			if (result.hits.total > 0) {
				qResult = queryNew( structKeyList(result.hits.hits[1]._source ));
				i = 1;
				aExts = [];

				for (hit in result.hits.hits) {
					if (StructKeyExists(hit, "highlight")) {
						if (StructKeyExists(hit.highlight, "summary")) {
							hit._source.summary = hit.highlight.summary[1];
						}
						if (StructKeyExists(hit.highlight, "title")) {
							hit._source.title = hit.highlight.title[1];
						}

					}
					thisRow = hit._source;
					queryAddRow(qResult);

					for ( thisCol in listToArray(structKeyList(thisRow)) ) {
						try {
							// handle array values
							if ( listFindNoCase("tags,path,credits,categoryids", thisCol) )
								querySetCell(qResult, thisCol, arrayToList(thisRow[thisCol]));
							else
								querySetCell(qResult, thisCol, thisRow[thisCol]);
						} catch (any e) {}
					}
					i++
				}
			}
		</cfscript>

		<cfreturn qResult>
	</cffunction>


	<cffunction name="getPublicSearchReplacement" returntype="any" access="public" output="false">
		<cfargument name="siteid" type="string" required="true">
		<cfargument name="keywords" type="string" required="true">
		<cfargument name="author" type="string" required="false" default="">
		<cfargument name="source" type="string" required="false" default="">
		<cfargument name="category" type="string" required="false" default="">
		<cfargument name="section" type="string" required="false" default="">
		<cfargument name="tag" type="string" required="false" default="">
		<cfargument name="startdate" type="date" required="false" default="#createDate(1845,1,1)#">
		<cfargument name="enddate" type="date" required="false" default="#now()#">
		<cfargument name="from" type="numeric" required="false" default="0">
		<cfargument name="size" type="numeric" required="false" default="20">
		<cfargument name="sortby" type="string" required="false" default="score">
		<cfargument name="returnFacets" type="boolean" required="false" default="false">

		<cfscript>
			variables.pluginConfig = application.serviceFactory.getBean('$').getPlugin('ElasticSearch');
			variables.wrapper = new cfelasticsearch.cfelasticsearch.api.Wrapper().init(variables.pluginConfig.getSetting('endpoint'));
			var result = "";
			var qResult = queryNew("contentid,contenthistid,title,summary,display,filename,urltitle,type,subtype,tags,credits,releasedate");

			// escape any special characters
			listfrom = '+,-,&&,||,!,(,),{,},[,],^,",~,*,?,\,/';
			listto = '\+,\-,\&&,\||,\!,\(,\),\{,\},\[,\],\^,\",\~,\*,\?,\\,\/';

			var keywords = replaceList(arguments.keywords, listfrom, listto);
			//arguments.keywords = replace(arguments.keywords,"/","","all");

			// search criteria
			body = {
				filtered = {
					filter = {
						"and" = [
							{
								bool = {
									must = {
										term = {
											searchexclude = 0,
											approved = 1
										}
									}
								}
							},
							{
								range = {
									display = {
										"gt" = 0
									}
								}
							},
							{
								range = {
									releasedate = {
										"gte" = dateFormat(arguments.startDate, 'YYYY-MM-DD') & ' ' & timeFormat(arguments.startDate, 'hh:mm:ss'),
										"lte" = dateFormat(arguments.endDate, 'YYYY-MM-DD') & ' ' & timeFormat(arguments.endDate, 'hh:mm:ss')
									}
								}
							}
						]
					}
				}
			};

			// keyword serach
			if ( len(trim(keywords)) ) {
				structAppend(body.filtered, 
					{
						query = {
							query_string = { 
								query = keywords,
								default_operator = "AND"
							}
						}
					}
				);
			}

			// Filtering...
			if (len(arguments.section)) {
				arrayAppend(body.filtered.filter.and,
				{
					term = { parentid = arguments.section }
				}
				, false);
			}

			if ( len(arguments.category) ) {
				arrayAppend(body.filtered.filter.and, 
				{ 
					term = { categoryids = arguments.category }
				}
				, false);
			}

			if (len(arguments.author)) {
				arrayAppend(body.filtered.filter.and, 
				{
					term = { "credits.facet" = arguments.author }
				}
				, false);
			}
			if (len(arguments.source)) {
				arrayAppend(body.filtered.filter.and,
				{
					terms = { subtype = listToArray(lcase(arguments.source)) }
				}
				, false);
			}

			if (len(arguments.tag)) {
				arrayAppend(body.filtered.filter.and,
				{
					terms = {
						"tags.facet" = listToArray("#arguments.tag#,#lcase(arguments.tag)#,#ucase(arguments.tag)#,#ucFirst(lcase(arguments.tag))#"),
						execution = "bool",
						_cache = true
					}
				}
				, false);
			}

			// wrap query
			body = { query = body };

			// pagination
			body.from = arguments.from;
			body.size = arguments.size;

			// highlight
			// TO-DO: Don't highlight on fields that can contain markup or bad things happen
			/*
			structAppend(body, {
				highlight = {
					pre_tags = ["<strong>"],
			        post_tags = ["</strong>"],
					fields = {
						title = {},
						summary = {}
					}
				}
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
					},
					categoryids = {
						terms = {field = "categoryids"}	
					}
				}
			}, false);

			// sorting 
			if (arguments.sortBy == 'releasedate') {
				sort = {releasedate = {order = "desc", ignore_unmapped = true}};
			} else {
				sort = "_score";
			}

			structAppend(body, {
				sort = [ sort ]
			}, false);

			// execute query
			result = variables.wrapper._call(
				  uri    = "/#arguments.siteid#/content/_search"
				, method = "POST"
				, body   = serializeJson( body )
			);

			// convert results to query
			if (result.hits.total > 0 && isDefined('result.hits.hits') && arrayLen(result.hits.hits)) {
				qResult = queryNew( structKeyList(result.hits.hits[1]._source ));
				i = 1;
				aExts = [];

				for (hit in result.hits.hits) {
					if (StructKeyExists(hit, "highlight")) {
						if (StructKeyExists(hit.highlight, "summary")) {
							hit._source.summary = hit.highlight.summary[1];
						}
						if (StructKeyExists(hit.highlight, "title")) {
							hit._source.title = hit.highlight.title[1];
						}

					}
					thisRow = hit._source;
					queryAddRow(qResult);

					for ( thisCol in listToArray(structKeyList(thisRow)) ) {
						try {
							// handle array values
							if ( listFindNoCase("tags,path,credits,categoryids", thisCol) )
								querySetCell(qResult, thisCol, arrayToList(thisRow[thisCol]));
							else {
								querySetCell(qResult, thisCol, thisRow[thisCol]);
							}
						} catch (any e) {}
					}
					i++
				}
			}
		</cfscript>

		<cfif arguments.sortby eq 'date'>
			<cfset querysort(qResult, 'releasedate', 'desc')>
		</cfif>

		<!--- add query to result --->
		<cfif arguments.returnFacets>
			<cfset result.query = qResult>
			<cfreturn result>
		<cfelse>
			<cfreturn qResult>
		</cfif>

	</cffunction>


	<cffunction name="getPrivateSearchReplacement" returntype="query" access="public" output="false">
		<cfargument name="siteid" type="string" required="true">
		<cfargument name="keywords" type="string" required="true">
		<cfargument name="tag" type="string" required="true" default="">
		<cfargument name="sectionID" type="string" required="true" default="">
		<cfargument name="searchType" type="string" required="true" default="default" hint="Can be default or image">

		<cfscript>
			variables.pluginConfig = application.serviceFactory.getBean('$').getPlugin('ElasticSearch');
			variables.wrapper = new cfelasticsearch.cfelasticsearch.api.Wrapper().init(variables.pluginConfig.getSetting('endpoint'));
			var result = "";
			var qResult = queryNew("contentid,contenthistid,title,summary,display,filename,urltitle,type,subtype,tags,credits");

			// escape any special characters
			listfrom = '+,-,&&,||,!,(,),{,},[,],^,",~,*,?,\';
			listto = '\+,\-,\&&,\||,\!,\(,\),\{,\},\[,\],\^,\",\~,\*,\?,\\';

			arguments.keywords = replaceList(arguments.keywords, listfrom, listto);

			if (!len(arguments.keywords))
				arguments.keywords = "*";

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


			if ( arguments.searchType == 'Image' ) {
				structAppend(body.filtered, 
				{
					filter = {
						term = { type = "File" }
					},
					filter = {
						term = { fileext = "jpg" }
					}
				}
				, false);
			}

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
						try {
							// handle array values
							if ( listFindNoCase("tags,path,credits,categoryids", thisCol) )
								querySetCell(qResult, thisCol, arrayToList(thisRow[thisCol]));
							else
								querySetCell(qResult, thisCol, thisRow[thisCol]);
						} catch (any e) {}
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