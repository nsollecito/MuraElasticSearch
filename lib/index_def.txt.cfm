/* Define ElasticSearch Index*/

curl -XPUT 'localhost:9200/default/content/_mapping?pretty=true' -d '
{
  "content" : {
    "properties" : {
      "contentid" : {
        "type" : "string", "index" : "not_analyzed"
      },
      "contenthistid" : {
        "type" : "string", "index" : "not_analyzed"
      },
      "siteid" : {
        "type" : "string", "index" : "not_analyzed"
      },
      "title" : {
        "type" : "string", "boost" : "3", "store" : "yes"
      },
      "menutitle" : {
        "type" : "string", "boost" : "3", "store" : "yes"
      },
      "categoryids" : {
        "type" : "string", "index" : "not_analyzed"
      },
      "summary" : {
        "type" : "string", "boost" : "3", "store" : "yes"
      },
      "tags" : {
        "type" : "multi_field", 
        "fields" : {
        	"tags" : { "type" : "string", "index" : "analyzed" },
        	"facet" : { "type" : "string", "index" : "not_analyzed" }
        }
      },
      "type" : {
        "type" : "string", "store" : "yes"
      },
      "subtype" : {
        "type" : "string", "store" : "yes"
      },
      "urltitle" : {
        "type" : "string", "boost" : "2", "store" : "yes"
      },
      "restricted" : {
        "type" : "byte", "store" : "yes", "null_value" : "0"
      },
      "restrictgroups" : {
        "type" : "string", "index" : "not_analyzed"
      },
      "displaystart" : {
        "type" : "string", "store" : "yes", "format" : "YYYY-MM-dd HH:mm:ss", "null_value":"0000-00-00 00:00:00"
      },
      "displaystop" : {
        "type" : "string", "store" : "yes", "format" : "YYYY-MM-dd HH:mm:ss", "null_value":"0000-00-00 00:00:00"
      },
      "remotesource" : {
        "type" : "string", "store" : "yes"
      },
      "remotesourceurl" : {
        "type" : "string", "store" : "yes"
      },
      "remoteurl" : {
        "type" : "string", "store" : "yes"
      },
      "fileid" : {
        "type" : "string", "index" : "not_analyzed", "store" : "yes"
      },
      "path" : {
        "type" : "string", "index" : "not_analyzed", "store" : "yes"
      },
      "body" : {
        "type" : "string"
      },
      "thumbnail" : {
      	"type" : "string"
      },
      "isnav" : {
        "type" : "byte", "store" : "yes", "index" : "not_analyzed", "null_value" : "0"
      },
      "searchexclude" : {
        "type" : "byte", "store" : "yes", "null_value" : "0"
      },
      "credits" : {
        "type" : "multi_field", 
        "fields" : {
        	"credits" : { "type" : "string", "index" : "analyzed" },
        	"facet" : { "type" : "string", "index" : "not_analyzed" }
        }
      },
      "filename" : {
        "type" : "string", "index" : "not_analyzed"
      },
      "lastupdate" : {
        "type" : "string"
      },
      "parentid" : {
        "type" : "string", "index" : "not_analyzed"
      },
      "releasedate" : {
        "type" : "string", "store" : "yes", "format" : "YYYY-MM-dd HH:mm:ss", "null_value":"0000-00-00 00:00:00"
      },
      "lastupdate" : {
        "type" : "string", "store" : "yes", "format" : "YYYY-MM-dd HH:mm:ss", "null_value":"0000-00-00 00:00:00"
      },
      "created" : {
        "type" : "string", "store" : "yes", "format" : "YYYY-MM-dd HH:mm:ss", "null_value":"0000-00-00 00:00:00"
      },
      "expires" : {
        "type" : "string", "store" : "yes", "format" : "YYYY-MM-dd HH:mm:ss", "null_value":"0000-00-00 00:00:00"
      }
    }
  }
}'


<!---


curl -XGET 'http://localhost:9200/default/content/_search?pretty=true' -d '
{
 "query": {
  "filtered" : {
   "query" : {
    "field" : { "contentid" : "F90364B7-6F7D-48DE-AA296B6F3DEA9717"}
   },
   "query" : {
    "field" : { "siteid" : "default"}
   },
   "filter" : {
     "term" : { "searchexclude" : 0 }
   }
  }
 }
}'


curl -XGET 'http://localhost:9200/default/content/_search?pretty=true' -d '{
    "query": {
        "filtered" : {
            "query" : {
                "query_string" : {
                    "query" : "Lorem"
                }
            }
        }
    }
}'

--->