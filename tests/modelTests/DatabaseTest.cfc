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

		this.db = this.conn.getDatabase();
	}

	public function testGetInfo() {
		var dbinfo = this.db.getInfo();
		assertEquals(dbinfo.name, this.db.getName());
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

}