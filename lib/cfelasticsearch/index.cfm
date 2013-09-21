<cfset $ = application.serviceFactory.getBean('$').init('sciam') />

<cfset rs = $.getBean('feed').loadBy(name='Global').setMaxItems(1000).getQuery()>

<cfcollection action="list" name="c" />
<cfdump var="#c#">

<cfflush interval="100">

<ol>
	<cfloop query="rs">	
		<cfindex action="update" 
			collection="testing" 
			key="contentID" 
			type="custom" 
			query="rs" 
			title="title" 
			body="summary"/>

		<cfoutput><li>#title#</li></cfoutput>
		<cfflush interval="100">
	</cfloop>
</ol>

<cfcollection action="list" name="c" />
<cfdump var="#c#">

<cfabort>

<cfscript>
	
	es = new cfelasticsearch.cfelasticsearch.api.Wrapper();

	// es.createIndex("test");

	/* es.addDoc(
		index="test",
		type="doc",
		id=createUUID(),
		doc={
			title="This is my title",
			subject="My cool subject",
			body="Test test test test test test test test. Test test test test test test test test Test test test test test test test test. Test test test test test test test test. Test test test test test test test test Test test test test test test test test Test test test test test test test test.",
			author="Testes McTestin",
			publishDate=now()
		}
	); */

	writeDump(var=es.Search(q=jsStringFormat('September'), index="test"));
</cfscript>

