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

		variables.wrapper = new cfelasticsearch.cfelasticsearch.api.Wrapper();
		variables.siteId = arguments.siteId;
		variables.indexName = arguments.siteId;

		// make sure ElasticSearch is running
		if (!checkService()) {
			startService();
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
				contentId = arguments.contentBean.getContentId(),
				type = arguments.contentBean.getType(),
				subtype = arguments.contentBean.getSubtype(),
				title = arguments.contentBean.getTitle(),
				body = arguments.contentBean.getBody(),
				summary = arguments.contentBean.getSummary(),
				tags = arguments.contentBean.getTags(),
				fileId = arguments.contentBean.getFileId(),
				parentId = arguments.contentBean.getParentId(),
				filename = arguments.contentBean.getFilename(),
				urlTitle = arguments.contentBean.getUrlTitle(),
				credits = arguments.contentBean.getCredits(),
				metadesc = arguments.contentBean.getMetaDesc(),
				metakeywords = arguments.contentBean.getMetakeywords(),
				parentId = arguments.contentBean.getParentId(),
				releaseDate = arguments.contentBean.getReleaseDate()
			},
			idField='contentId'
		);
	}



	function indexByRecordset(numeric startRow=1, numeric maxRows=1) {
		var queryService = new query();
		var result = "";
		var aDocs = [];
	    
	    /* set properties using implict setters */ 
	    queryService.setDatasource(variables.configBean.getDatasource()); 
	    queryService.setName("rsContent"); 
	    queryService.setMaxRows(arguments.maxRows);


	    savecontent variable="myQuery" {
		    writeOutput("
		      SELECT 
		          contentID, type, subtype, siteID, Title, Body, summary, tags, 
		          fileId, filename, urlTitle, credits, metadesc, metakeywords,
		          parentId, releaseDate
		      FROM tcontent
		      WHERE 
				  active = 1
				  and type in ('Page','Folder','Portal','Calendar','Gallery','Link')
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
	    	arrayAppend(aDocs, row);
		}

		result = variables.wrapper.addDocs(
			index=variables.indexName,
			type="content",
			docs=aDocs,
			idField='contentId'
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
</cfcomponent>