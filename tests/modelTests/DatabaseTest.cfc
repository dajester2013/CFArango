/**
 * DatabaseTest
 *
 * @author jesse.shaffer
 * @date 6/14/14
 **/
component extends="mxunit.framework.TestCase" accessors=true output=false persistent=false {

	public function beforeTests() {
		this.conn = new org.jdsnet.arangodb.Connection()
			.setHost("127.0.0.1")
			.setPort(8529)
			.setDatabase("_system")
			;
		this.conn.open();

		assertEquals(this.conn.getState(), this.conn.OPENED, "Expected the connection to be in an OPENED state.");

		variables.db = this.conn.getDatabase();
	}

	public function testGetInfo() {
		var dbinfo = db.getInfo();
		assertEquals(dbinfo.name, db.getName());
		assertTrue(dbinfo.isSystem);
	}

	public function testGetNonExistentDatabase() {
		try {
			this.conn.getDatabase("doesntexist");
			assertTrue(false, "The connection should have thrown an exception before reaching this test.");
		} catch (any e) {
			assertEquals(e.errorCode,1228);
		}
	}

	public function testCreateDocumentCollection() {
		var collection = db.createCollection("test_createdoccollection");
		assertIsTypeOf(collection,"org.jdsnet.arangodb.model.Collection");
		collection.drop();
	}

	public function testCreateEdgeCollection() {
		var collection = db.createEdgeCollection("test_createdoccollection");
		assertEquals(collection.getProperties().type,3);
		collection.drop();
	}

}