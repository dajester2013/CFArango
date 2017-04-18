
component accessors=true {

	property type="boolean"	name="useSSL";
	property type="string"	name="Host";
	property type="numeric"	name="Port";
	property type="string"	name="Database";
	property type="string"	name="Username";
	property type="string"	name="ThrowHttpError";
	property type="string"	name="Password" getter=false;

	useSSL				= false;
	Host				= "localhost";
	Port				= 8529;
	Database			= "_system";
	Username			= "";
	Password			= "";
	ThrowOnHttpError	= true;

	public struct function executeApiRequest(string api, any data="", string method="GET") {
		writedump(arguments);

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
			,url			= "http" & (getUseSSL() ? "s" : "") & "://" & getHost() & "/_db/" & getDatabase() & "/_api/" & api & urlData
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

	public struct function getDatabaseInfo() {
		return this.executeApiRequest("database/current").data;
	}

	public struct function getCollections(type="user") {
		var collections = this.executeApiRequest("collection").data.result;

		return collections.reduce(function(result={}, c) {
			if (
					(c.isSystem && (type == "sys"||type == "all"))
				||	(!c.isSystem && (type == "user"||type == "all"))
			) {
				result[c.name] = this.getCollection(c.name);
			}
			return result;
		});
	}

	public Collection function getCollection(required string name) {
		return new model.Collection(this, name);
	}

}