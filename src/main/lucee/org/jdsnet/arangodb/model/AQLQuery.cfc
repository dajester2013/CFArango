component extends=BaseModel accessors=true {

	property string Statement;
	property struct Parameters;

	public function init(Driver driver, string aql="") {
		super.init(driver);

		this.setStatement(aql);
	}

	public function execute(struct parameters=this.getParameters()) {
		var api = driver.getApi("Cursor");

		parameters = parameters?:structnew();

		var cursor = api.createCursor(
			query=this.getStatement()
			,bindVars=parameters
			,batchSize=3
			,count=true
		);

		var data = cursor.result;

		while(cursor.hasMore) {
			cursor = api.readNextBatch(cursor.id);
			data.addAll(cursor.result);
		}

		if (cursor.keyExists("id"))
			api.free(cursor.id);

		return new AQLQueryResult(this, data);
	}

}