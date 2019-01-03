component extends=BaseModel accessors=true {
	
	property array data;


	parser = new org.jdsnet.arangodb.util.JSONParser();

	parser.setGenerator(function(type, args, meta, rawData={}) { //return new "#type#"(argumentCollection=args?:rawData);
		var instance="";

		var docIdProperty = arrayReduce(meta.properties, function(last, cur) {
			if (!isNull(last)) return last;

			param name="cur.setter" default="#meta.accessors#";

			if (cur.keyExists("DocumentId") && cur.DocumentId) {
				return cur;
			}
		});

		var docKeyProperty = arrayReduce(meta.properties, function(last, cur) {
			if (!isNull(last)) return last;

			param name="cur.setter" default="#meta.accessors#";

			if (cur.keyExists("DocumentKey") && cur.DocumentKey) {
				return cur;
			}
		});

		var instance = new "#type#"(argumentCollection=args?:rawData);

		if (rawData.keyExists("_key") && !isNull(docKeyProperty) && (docKeyProperty.setter?:true)) {
			cfinvoke(component=instance,method="set#docKeyProperty.name#", argumentCollection={1:rawData["_key"]});
		}

		return instance;
	});

	public function init(required query, required array data) {
		super.init(query.getDriver());
		variables.data = arguments.data;
	}

	public function toDocuments(string type) {
		return arrayMap (data, function(record) {
			if (isNull(type)) {
				return new Document(driver, record);
			} else {
				return parser.fromParsed(record, type);
			}
		});
	}

}