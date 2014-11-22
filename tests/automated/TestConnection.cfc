/**
 *
 **/
component extends="mxunit.framework.TestCase" {

	public function beforeTests() {
		this.conn = new org.jdsnet.arangodb.Connection()
			.setHost("127.0.0.1")
			.setPort(8529)
			.setDatabase("_system")
			;
		this.conn.open();

		assertEquals(this.conn.getState(), this.conn.OPENED, "Expected the connection to be in an OPENED state.");
	}

	public function testReadVersion() {
		assertFalse(isNull(this.conn.getServerVersion(true)));
	}

	public function testOpenService() {
		var svc = this.conn.openService("database");
		assertFalse(isNull(svc));
		assertTrue(isInstanceOf(svc,"org.jdsnet.arangodb.ArangoDBRestClient"));
	}

	public function testCurrentDatabase() {
		var svc = this.conn.openService("database/current");
		assertEquals(svc.get().result.name, this.conn.getDatabase().getName());
	}

	public function testGetDatabase() {
		assertTrue(isInstanceOf(this.conn.getDatabase(), "org.jdsnet.arangodb.model.Database"));
	}

	public function testGetUserDatabases() {
		var userdbs = this.conn.getUserDatabases();
		assertTrue(isArray(userdbs));
	}

}