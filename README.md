CFArango
========

CFML client library for ArangoDB.

master: [![Build Status: master](https://travis-ci.org/dajester2013/CFArango.svg?branch=master)](https://travis-ci.org/dajester2013/CFArango?branch=master)

develop: [![Build Status: develop](https://travis-ci.org/dajester2013/CFArango.svg?branch=develop)](https://travis-ci.org/dajester2013/CFArango?branch=develop)

Requirements
===========
* Railo 4.1+, or Adobe ColdFusion 10+
* ArangoDB 1.4+, 2.0+

Installation:
=============

1. Clone the repository: 
    <pre>git clone https://github.com/dajester2013/CFArango.git</pre>
2. Add mapping to the code (not necessary if project is cloned into your project/webserver root).
   Use one of the following methods:
    1. Railo/ACF Application.cfc mapping:
    <pre>this.mappings["/org"] = [/path/to/CFArango]/org</pre>
    2. Railo Component resource mapping:
        * Navigate to the administrator page (server or web depending on how wide you desire access)
        * Under **Archives & Resources > Component**, add a resouce:
            * **Name** = cfarango
            * **Resource** = /path/to/CFArango (*NOTE: do not add the /org to the resource path!*)
r
    3. ACF custom tag path
        * Add /path/to/CFArango to the custom tags path
            * Can be set in the Administrator under **Extensions > Custom Tag Paths**
            * Can be set in Application.cfc
            <pre>this.customtagpaths="/path/to/CFArango";</pre>

Examples:
=========

```cfml
<cfscript>
// representative of the defaults
conn = new org.jdsnet.arangodb.Connection()
		.setHost("localhost")
		.setPort(8529)
		.setProtocol("http");

// representative of the defaults
conn.getCredentials()
	.setUsername("root")
	.setPassword("");

var database = conn.getDatabase("_system");

var collection = database.createCollection("test");
var relation = database.createEdgeCollection("relation");

doc1 = collection.save({
	"key" : "value" // use quotes around the key to preserve case
});

var doc2 = collection.newDocument({
	"key" : "value"
});
doc2.put("anotherKey","anotherValue");
doc2.putAll({});
doc2.save();


// different ways to create relations
doc1.createEdge("relation").to(doc2).save();	// creates an "outbound" relation from doc1 to doc2
doc1.createEdge("relation").from(doc2).save();	// creates an "inbound" relation from doc2 to doc1

relation.newDocument().from(doc1).to(doc2).save(); // same as first example of creating an edge.

// delete a document - note, any edges referencing this document are orphaned currently
doc1.delete();

// queries
  // AQL
  var stmt = database.prepareStatement("for document filter key == @key in collection return document")
            .setBatchSize(100);
  var cursor = stmt.execute({"key" : "value"});

  // reading the result set
    // option 1
    var result = cursor.toArray();
    // option 2
    var result = cursor.toQuery();
    // option 3
    while (cursor.hasNext()) {  // or hasNextBatch
        writedump(cursor.next()); // or nextBatch
    }
    // option 4
    cursor.each(function(doc) {  // or eachBatch
        writedump(doc); // or batch
    });
    
  // Read By Example
  var cursor = collection.queryByExample({"key":"value"});
  var cursor = collection.fullTextSearch("");
  
  // Update By Example
  var result = collection.updateByExample(example={}, update={});
  // Replace By Example
  var result = collection.replaceByExample(example={}, update={});
  
  // Delete By Example
  var result = collection.deleteByExample(example={});
  
</cfscript>
```
