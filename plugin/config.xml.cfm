<!---
    Mura ElasticSearch
    
    License:
    Apache License
    Version 2.0, January 2004
    http://www.apache.org/licenses/
--->
<plugin>
	<name>Mura ElasticSearch</name>
	<package>elasticSearch</package>
	<directoryFormat>packageOnly</directoryFormat>
	<provider></provider>
	<version>0.2</version>
	<providerURL></providerURL>
	<category>Application</category>
	<settings>
		<setting>
			<name>endpoint</name>
			<label>ElasticSearch Endpoint</label>
			<hint>This is the URL of your ElasticSearch instance. Default is 'http://localhost:9200'</hint>
			<type>text</type>
			<required>false</required>
			<validation></validation>
			<regex></regex>
			<message></message>
			<defaultvalue>http://localhost:9200/</defaultvalue>
			<optionlist></optionlist>
			<optionlabellist></optionlabellist>
		</setting>
	</settings>
	<eventHandlers>
		<eventHandler event="onApplicationLoad" component="eventHandler" persist="false"/>	
	</eventHandlers>
	<displayobjects location="global"></displayobjects>
</plugin>