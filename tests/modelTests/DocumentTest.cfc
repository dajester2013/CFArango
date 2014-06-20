/**
 * DocumentTest
 *
 * @author jesse.shaffer
 * @date 6/20/14
 **/
component accessors=true output=false persistent=false extends="mxunit.framework.TestCase"{

	public function testSetGetClearLocal() {
		var doc = new org.jdsnet.arangodb.model.Document();
		doc.put("testKey", "testVal");
		doc.put("testKey2", "testVal2");

		assertEquals(doc.get("testKey"), "testVal");
		assertEquals(doc.get("testKey2"), "testVal2");

		doc.clear("testKey");

		assertTrue(isNull(doc.get("testKey")));
		assertTrue(!isNull(doc.get("testKey2")));

		doc.clear();

		assertEquals(structCount(doc.get()),0);
	}

	public function testSetGetClearRemote() {
		var conn = new org.jdsnet.arangodb.Connection();
		conn.setHost("localhost")
			.setPort(8529)
			.setDatabase("_system")
			.open();

		var db = conn.getDatabase();
		var col = db.createCollection("test_document_setgetclear");
		var doc1 = col.newDocument();

		try {
			var id = doc1.save().getId();

			assertTrue(!isNull(id));

			doc1.put("testKey","testVal")
				.put("testKey2", "testVal2")
				.save();

			var doc2 = col.getDocument(id);

			assertEquals(doc1.get("testKey"), doc2.get("testKey"));

			doc1.clear("testKey");

			doc1.save();

			doc2 = col.getDocument(id);

			assertTrue(isNull(doc2.get("testKey")));

			col.drop();
		} catch(any e) {
			col.drop();
			throw(object=e);
		}

	}

}