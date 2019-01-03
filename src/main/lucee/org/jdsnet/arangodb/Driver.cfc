
component accessors=true {

	property type="boolean"	name="useSSL" setter=false;
	property type="string"	name="Host" setter=false;
	property type="numeric"	name="Port" setter=false;
	property type="string"	name="Database" setter=false;
	property type="string"	name="Username";
	property type="string"	name="Password";
	property type="struct"	name="Api" setter=false;
	property type="string"	name="ThrowHttpError" setter=false;

	/** hide credentials */
	function getUsername() {
		return "******";
	}
	/** hide credentials */
	function getPassword() {
		return "******";
	}


	public Driver function init(
		string	Host			= "localhost",
		numeric	Port			= 8529,
		boolean	UseSSL			= false,

		string	Database		= "_system",

		string	Username		= "root",
		string	Password		= "",

		boolean	ThrowHttpError	= false
	) {
		structAppend(variables, arguments);

		_Api = {
			 "Admin"			: new org.jdsnet.arangodb.api.Admin(this)
			,"AQL"				: new org.jdsnet.arangodb.api.AQL(this)
			,"Collection"		: new org.jdsnet.arangodb.api.Collection(this)
			,"Cursor"			: new org.jdsnet.arangodb.api.Cursor(this)
			,"Database"			: new org.jdsnet.arangodb.api.Database(this)
			,"Document"			: new org.jdsnet.arangodb.api.Document(this)
			,"Graph"			: new org.jdsnet.arangodb.api.Graph(this)
			,"Simple"			: new org.jdsnet.arangodb.api.Simple(this)
			,"Transaction"		: new org.jdsnet.arangodb.api.Transaction(this)
			,"WriteAheadLog"	: new org.jdsnet.arangodb.api.WriteAheadLog(this)
		};

		Api = createObject("java", "java.util.Collections").unmodifiableMap(_Api);

		return this;
	}

	public function setConnectionString(string connStr) {
		var uri = createObject("java","org.apache.commons.httpclient.URI").init(connStr, false);
		var data = {
			host = uri.getHost()
			,port = uri.getPort() > -1 ? uri.getPort() : 8529
			,useSSL = uri.getScheme() == "adbs"
			,database = uri.getPath() ?: Database ?: "_system"
		};

		data.database = data.database.listFirst('/');

		if (!isNull(uri.getEscapedUserInfo())) {
			parts = uri.getEscapedUserInfo().split(":");
			data.Username = parts[1];
			data.Password = parts[2] ?: Password;
		}

		this.init(argumentCollection=data);

		return this;
	}

	public function getConnectionString() {
		return "adb#useSSL?"s":""#://#Host#:#Port#/#Database#";
	}

	public function getApi(string key) {
		if (!isNull(key))
			return Api[key] ?: Api.get(key) ?: cfthrow(type="org.jdsnet.arangodb.InvalidKey", message="API ""#key#"" does not exist");

		return Api;
	}

	public struct function executeApiRequest(string api, any data="", string method="GET", struct headers={}) {
		return executeRequest("/_api/#api.replaceAll('^/','')#", data, method, headers);
	}

	public struct function executeAdminRequest(string api, any data="", string method="GET", struct headers={}) {
		return executeRequest("/_admin/#api.replaceAll('^/','')#", data, method, headers);
	}

	public struct function executeRequest(string api, any data="", string method="GET", struct headers={}) {
		var rawResult = {};

		var urlData = "";
		var bodyData = "";

		// data goes into the body for POST/PUT/PATCH/DELETE requests
		if (method != "GET") { //arrayFindNoCase(["POST","PUT","PATCH","DELETE"],method)
			bodyData = serializeJson(data);

		// otherwise, serialize struct into url key-value pairs
		} else if (isStruct(data)) {
			urlData = "?";
			for (var key in data) urlData = listAppend(urlData, key & "=" & urlencodedFormat(data[key]), "&");

		// or positional params for array data
		} else if (isArray(data)) {
			for (var item in data) api = listAppend(api, urlEncodedFormat(item), "/");

		// finally, if it's a string/number, tack it on as a positional param
		} else if (isSimpleValue(data) && len(data)) {
			api = listAppend(api, urlEncodedFormat(data), "/");

		}

		headers["Content-Type"] = "application/json";

		cfhttp(
			 result			= "rawResult"
			,url			= "http" & (UseSSL ? "s" : "") & "://" & Host & "/_db/" & Database & api & urlData
			,port			= getPort()
			,method 		= method
			,throwOnError	= getThrowHttpError()
			,username		= Username
			,password		= Password
		) {
			/*cfhttpparam (type="header", name="Content-Type", value="application/json");*/

			for (var header in headers) {
				cfhttpparam (type="header", name=header, value=headers[header]);
			}

			if (len(bodyData))
				cfhttpparam (type="body", value=bodyData);
		}

		if (!rawResult.responseHeader.keyExists("status_code")) {
			cfthrow(message=rawResult.FileContent, detail=rawResult.errorDetail,type="org.jdsnet.arangodb.ConnectionFailureException");
		}
		
		if (rawResult.responseHeader.status_code == 401)
			throw(type="org.jdsnet.arangodb.UnauthenticatedRequestException", message="Invalid credentials were supplied for this request.", detail=serializeJSON({
				 url			= "http" & (UseSSL ? "s" : "") & "://" & Host & "/_db/" & Database & api & urlData
				,port			= getPort()
				,method 		= method
			}));

		return {
			 "data"		: isJson(rawResult.FileContent) ? deserializeJSON(rawResult.FileContent) : (rawResult.FileContent?:javacast("null",""))
			,"headers"	: rawResult.responseHeader
			,"rawBody"	: rawResult.FileContent
			,"status"	: {
				 "code":	rawResult.responseHeader.status_code
				,"text":	rawResult.responseHeader.explanation
			}
		};
	}

	public function getDatabase() {
		return new model.Database(this, Database);
	}

	public function prepareStatement(required string aql) {
		return new model.AQLQuery(this, aql);
	}

}