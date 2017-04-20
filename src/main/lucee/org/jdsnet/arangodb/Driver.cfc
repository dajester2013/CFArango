
component accessors=true {

	property type="boolean"	name="useSSL" setter=false;
	property type="string"	name="Host" setter=false;
	property type="numeric"	name="Port" setter=false;
	property type="string"	name="Database" setter=false;
	property type="string"	name="Username" setter=false;
	property type="string"	name="ThrowHttpError" setter=false;
	property type="string"	name="Password" setter=false getter=false;

	public Driver function init(
		Host				= "localhost",
		Port				= 8529,
		UseSSL				= false,

		Database			= "_system",

		Username			= "root",
		Password			= "",

		ThrowOnHttpError	= true
	) {
		structAppend(variables, arguments);

		return this;
	}

	public struct function executeApiRequest(string api, any data="", string method="GET") {
		_databaseLocked = true;
		var rawResult = {};

		var urlData = "";
		var bodyData = "";

		// data goes into the body for POST/PUT/PATCH requests
		if (arrayFindNoCase(["POST","PUT","PATCH"],method)) {
			bodyData = serializeJson(data);

		// otherwise, serialize struct into url key-value pairs
		} else if (isStruct(data)) {
			urlData = "?";
			for (var key in data) urlData = listAppend(urlData, key & "=" & urlencodedFormat(data[key]), "&");

		// or positional params for array data
		} else if (isArray(data)) {
			for (var item in data) api = listAppend(api, urlEncodedFormat(item), "/");

		// finally, if it's a string/number, tack it on as a positional param
		} else if (isSimpleValue(data)) {
			api = listAppend(api, urlEncodedFormat(data), "/");

		}

		cfhttp(
			 result			= "rawResult"
			,url			= "http" & (UseSSL ? "s" : "") & "://" & Host & "/_db/" & Database & "/_api/" & api & urlData
			,port			= getPort()
			,method 		= method
//			,throwOnError	= getThrowHttpError()
			,username		= Username
			,password		= Password
		) {
			cfhttpparam (type="header", name="Content-Type", value="application/json");

			if (len(bodyData))
				cfhttpparam (type="body", value=bodyData);
		}

		return {
			 "data"		: deserializeJSON(rawResult.FileContent)
			,"headers"	: rawResult.responseHeader
			,"rawBody"	: rawResult.FileContent
			,"status"	: {
				 "code":	rawResult.status_code
				,"text":	rawResult.status_text
			}
		};
	}

	public function getDatabase() {
		return new model.Database(this, Database);
	}

}