CFArango
========

CFML client library for ArangoDB.

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

relation.newDocument().to(doc1).from(doc2).save(); // same as first example of creating an edge.
</cfscript>
```
