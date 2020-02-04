component extends=BaseModel accessors=true {

	property string Statement;
	property struct Parameters;

	DEFAULT_OPTIONS={
		batchSize: 100
	};

	public function init(Driver driver, string aql="") {
		super.init(driver);

		this.setStatement(aql);
	}

	public function execute(struct parameters=this.getParameters(), struct options={}) {
		var api = driver.getApi("Cursor");

		parameters = parameters?:structnew();

		structAppend(options, DEFAULT_OPTIONS);

		options.query = this.getStatement();
		options.bindVars = parameters;
		
		var cursor = api.createCursor(argumentCollection=options);

		if (cursor.error) {
			cfthrow(message=cursor.errorMessage, errorCode=cursor.errorNum);
		}
		
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