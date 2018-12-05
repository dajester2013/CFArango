component extends=BaseModel accessors=true {

	property array data;

	public function init(required query, required array data) {
		super.init(query.getDriver());
		variables.data = arguments.data;
	}

	public function toDocuments(string type) {
		return arrayMap (data, function(record) {
			if (isNull(type)) {
				return new Document(driver, record);
			} else {
				var obj = createObject(type);
				obj.init(record);
				return obj;
			}
		});
	}

}