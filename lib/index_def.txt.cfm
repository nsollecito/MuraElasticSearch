{
  "content": {
    "dynamic":  true,
    "properties": {
      "contentid": {
        "type": "string",
        "index": "not_analyzed"
      },
      "contenthistid": {
        "type": "string",
        "index": "not_analyzed"
      },
      "siteid": {
        "type": "string",
        "index": "not_analyzed"
      },
      "title": {
        "type": "string",
        "boost": "3",
        "store": "yes"
      },
      "menutitle": {
        "type": "string",
        "boost": "3",
        "store": "yes"
      },
      "categoryids": {
        "type": "string",
        "index": "not_analyzed"
      },
      "summary": {
        "type": "string",
        "boost": "3",
        "store": "yes"
      },
      "tags": {
        "type": "multi_field",
        "fields": {
          "tags": {
            "type": "string",
            "index": "analyzed"
          },
          "facet": {
            "type": "string",
            "index": "not_analyzed"
          }
        }
      },
      "type": {
        "type": "string",
        "store": "yes"
      },
      "subtype": {
        "type": "string",
        "store": "yes"
      },
      "urltitle": {
        "type": "string",
        "boost": "2",
        "store": "yes"
      },
      "restricted": {
        "type": "byte",
        "store": "yes",
        "null_value": "0"
      },
      "display": {
        "type": "byte",
        "store": "yes",
        "null_value": "0"
      },
      "active": {
        "type": "byte",
        "store": "yes",
        "null_value": "0"
      },
      "approved": {
        "type": "byte",
        "store": "yes",
        "null_value": "0"
      },
      "restrictgroups": {
        "type": "string",
        "index": "not_analyzed"
      },
      "displaystart": {
        "type": "date",
        "store": "yes",
        "format": "YYYY-MM-dd HH:mm:ss",
        "null_value": "0000-00-00 00:00:00",
        "ignore_malformed": "true"
      },
      "displaystop": {
        "type": "date",
        "store": "yes",
        "format": "YYYY-MM-dd HH:mm:ss",
        "null_value": "0000-00-00 00:00:00",
        "ignore_malformed": "true"
      },
      "remotesource": {
        "type": "string",
        "store": "yes"
      },
      "remotesourceurl": {
        "type": "string",
        "store": "yes"
      },
      "remoteurl": {
        "type": "string",
        "store": "yes"
      },
      "fileid": {
        "type": "string",
        "index": "not_analyzed",
        "store": "yes"
      },
      "path": {
        "type": "string",
        "index": "not_analyzed",
        "store": "yes"
      },
      "body": {
        "type": "string"
      },
      "thumbnail": {
        "type": "string"
      },
      "isnav": {
        "type": "byte",
        "store": "yes",
        "index": "not_analyzed",
        "null_value": "0"
      },
      "searchexclude": {
        "type": "byte",
        "store": "yes",
        "null_value": "0"
      },
      "credits": {
        "type": "multi_field",
        "fields": {
          "credits": {
            "type": "string",
            "index": "analyzed"
          },
          "facet": {
            "type": "string",
            "index": "not_analyzed"
          }
        }
      },
      "filename": {
        "type": "string",
        "index": "not_analyzed"
      },
      "lastupdate": {
        "type": "string",
        "store": "yes",
        "format": "YYYY-MM-dd HH:mm:ss",
        "null_value": "0000-00-00 00:00:00"
      },
      "parentid": {
        "type": "string",
        "index": "not_analyzed"
      },
      "releasedate": {
        "type": "date",
        "store": "yes",
        "format": "YYYY-MM-dd HH:mm:ss",
        "null_value": "0000-00-00 00:00:00",
        "ignore_malformed": "true"
      },
      "created": {
        "type": "string",
        "store": "yes",
        "format": "YYYY-MM-dd HH:mm:ss",
        "null_value": "0000-00-00 00:00:00"
      },
      "expires": {
        "type": "string",
        "store": "yes",
        "format": "YYYY-MM-dd HH:mm:ss",
        "null_value": "0000-00-00 00:00:00"
      },
      "filesize": {
        "type": "integer",
        "index": "not_analyzed"
      },
      "fileext": {
        "type": "string",
        "index": "not_analyzed"
      },
      "assocfilename": {
        "type": "string",
        "store": "yes"
      }
    }
  }
}