/**
 * ArangoDBRestClient
 * 
 * @author jesse.shaffer
 * @date 11/30/13
 **/
component accessors=true output=false persistent=false {

	property string BaseUrl;
	property any ErrorHandler;
	property Credentials Credentials;
	
	this.setErrorHandler(variables.errorHandler);
	
	private function doRequest(required string verb, string resource="", any data="") {
		var svcRequest = new Http();
		var svcUrl = this.getBaseUrl() & (len(resource) ? "/" & resource : ""); 
		
		svcRequest.setMethod(verb)
		
		if (arrayFindNoCase(["POST","PUT","PATCH"],verb)) {
			svcRequest.addParam(type="body",value=serializeJson(data));
			svcRequest.addParam(type="header",name="Content-Type",value="application/json");
		} else if (isStruct(data)) {
			svcUrl &= "?";
			var paramlist="";
			for (var k in data)
				paramlist=listappend(paramlist,"#k#=#data[k]#","&");
			svcUrl &= paramlist;
		}
		
		svcRequest.setUrl(svcUrl);
		svcRequest.addParam(type="header",name="Accepts",value="application/json");
		
		if (!isNull(this.getCredentials()))
			this.getCredentials().bind(svcRequest);
		
		var svcResult = svcRequest.send().getPrefix();
		var responseData = deserializeJson(svcResult.filecontent);
		
		if (svcResult.statusCode >= 400) {
			if (!isNull(this.getErrorHandler()) && (isCustomFunction(this.getErrorHandler()) || structKeyExists(getMetaData(this.getErrorHandler()),"closure"))) {
				var eh = this.getErrorHandler();
				var ehrv = eh(svcUrl,svcResult,responseData);
				if (!isNull(ehret)) return ehrv;
			}
		}
		return responseData;
	}
	
	private function errorHandler(svcUrl,svcResult,responseData) {
		var ecode = isStruct(responseData) && structKeyExists(responseData,"errorNum") ? responseData.errorNum : svcResult.statusCode;
		throw(type="ArangoServiceException",message="Service responded with an error. Requested ""#svcUrl#""",detail=svcResult.filecontent,errorCode=ecode);
	}
	
	
	
	
	public function get(res,data) {
		if (isNull(res)) {
			res = "";
			data = "";
		} else if(!isValid("string",res) && isNull(data)) {
			data = res;
			res = "";
		} else if (isNull(data)) {
			data = "";
		}
		return doRequest("GET",res,data);
	}
	public function post(res,data) {
		if (isNull(res)) {
			res = "";
			data = "";
		} else if(!isValid("string",res) && isNull(data)) {
			data = res;
			res = "";
		} else if (isNull(data)) {
			data = "";
		}
		return doRequest("POST",res,data);
	}
	public function put(res,data) {
		if (isNull(res)) {
			res = "";
			data = "";
		} else if(!isValid("string",res) && isNull(data)) {
			data = res;
			res = "";
		} else if (isNull(data)) {
			data = "";
		}
		return doRequest("PUT",res,data);
	}
	public function patch(res,data) {
		if (isNull(res)) {
			res = "";
			data = "";
		} else if(!isValid("string",res) && isNull(data)) {
			data = res;
			res = "";
		} else if (isNull(data)) {
			data = "";
		}
		return doRequest("PATCH",res,data);
	}
	public function delete(res,data) {
		if (isNull(res)) {
			res = "";
			data = "";
		} else if(!isValid("string",res) && isNull(data)) {
			data = res;
			res = "";
		} else if (isNull(data)) {
			data = "";
		}
		return doRequest("DELETE",res,data);
	}
	
}