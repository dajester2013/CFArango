/**
 * CollectionTests
 *
 * @author jesse.shaffer
 * @date 6/23/14
 **/
component extends="mxunit.framework.TestCase" accessors=true output=false persistent=false {

	public function beforeTests() {
		var conn = new org.jdsnet.arangodb.Connection();
		conn.setHost("localhost")
			.setPort(8529)
			.setDatabase("_system")
			.open()
			;

		variables.db = conn.getDatabase();

		variables.docCollection = db.createCollection("test_collections_docCollection#gettickcount()#");
		variables.edgeCollection = db.createEdgeCollection("test_collections_edgeCollection#gettickcount()#");

		variables.emptyCollection = db.createCollection("test_collections_emptyCollection#gettickcount()#");
		variables.sysCollection = db.createCollection("_test_collections_system#gettickcount()#", {
			 "isSystem"=true
		});

		// get an even number between 150-200 to use as the number of documents to create.
		do {
			variables.populatedSize = randrange(150,200);
		} while(variables.populatedSize mod 2 > 0);

		var docs=[];
		/* save method test - struct */
		for (var i=0; i<populatedSize; i++) {
			arrayappend(docs,docCollection.save({
				"uniqueId" = createuuid()
			}));
		}
		for (var i=0; i<populatedSize; i+=2) {
			docs[i+1].createEdge(edgeCollection).to(docs[i+2]).save();
		}
	}

	public function testChecksums() {
		assertNotEquals(docCollection.getChecksum(), edgeCollection.getChecksum());
		assertNotEquals(docCollection.getChecksum(), docCollection.getChecksum(false));
		assertNotEquals(docCollection.getChecksum(true,true), docCollection.getChecksum(false,false));
		assertNotEquals(docCollection.getChecksum(true,false), docCollection.getChecksum(false,true));
		assertNotEquals(docCollection.getChecksum(false,true), docCollection.getChecksum(true,false));
		assertEquals(emptyCollection.getChecksum(),0);
	}

	public function testProperties() {
		assertIsStruct(docCollection.getProperties());
		assertTrue(structCount(docCollection.getProperties()));

		// check for a known property key - type
		assertTrue(docCollection.getProperties().type);

		assertIsStruct(docCollection.getProperties().keyOptions);
	}

	public function testOtherProperties() {
		assertTrue(isValid("string",docCollection.getName()));
		assertTrue(sysCollection.getIsSystem());
	}

	public function testQBE() {
		var qbeall = docCollection.queryByExample({});

		assertIsTypeOf(qbeall, "org.jdsnet.arangodb.query.Cursor");
		assertEquals(qbeall.getCurrentCount(), populatedSize);
		assertEquals(qbeall.getFullCount(), populatedSize);

		assertIsTypeOf(docCollection.queryByExample(example={},limit="first"), "org.jdsnet.arangodb.model.Document");
		assertIsStruct(docCollection.queryByExample(example={},limit="first",raw=true));
	}

	public function afterTests() {
		docCollection.drop();
		edgeCollection.drop();
		emptyCollection.drop();
		sysCollection.drop();
	}
}