/*
 * The MIT License (MIT)
 * Copyright (c) 2013 Jesse Shaffer
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

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

	_returnAll=false;

	private function doRequest(required string verb, string resource="", any data="") {
		var svcRequest = new Http();
		var svcUrl = this.getBaseUrl() & (len(resource) ? "/" & resource : "");

		svcRequest.setMethod(verb);

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

		if (!isNull(this.getCredentials())) {
			this.getCredentials().bind(svcRequest);
		}

		var svcResult = svcRequest.send().getPrefix();
		var responseData = isJson(svcResult.filecontent) ? deserializeJson(svcResult.filecontent) : svcResult.filecontent;
		if (_returnAll) {
			svcResult.responseData = responseData;
			return svcResult;
		} else {
			if (svcResult.statusCode >= 300) {
				if (!isNull(this.getErrorHandler()) && (isCustomFunction(this.getErrorHandler()) || structKeyExists(getMetaData(this.getErrorHandler()),"closure"))) {
					var eh = this.getErrorHandler();
					var ehrv = eh(svcUrl,svcResult,responseData);
					if (!isNull(ehrv)) return ehrv;
				} else {
					return svcResult;
				}
			}
			return responseData;
		}
	}

	private function errorHandler(svcUrl,svcResult,responseData) {
		var ecode = isStruct(responseData) && structKeyExists(responseData,"errorNum") ? responseData.errorNum : svcResult.statusCode;
		throw(type="ArangoServiceException",message="Service responded with an error. Requested ""#svcUrl#""",detail=svcResult.filecontent,errorCode=ecode);
	}


	public function returnAll() {
		_returnAll=true;
		return this;
	}

	private void function prepareHelperArgs(required struct args) {
		if (isNull(args.res)) {
			args.res = "";
			args.data = "";
		} else if(!isValid("string",args.res) && isNull(args.data)) {
			args.data = args.res;
			args.res = "";
		} else if (isNull(args.data)) {
			args.data = "";
		}
	}

	/**
	 * GET request - read data from a service
	 **/
	public function get(res,data) {
		prepareHelperArgs(arguments);
		return doRequest("GET",arguments.res,arguments.data);
	}
	/**
	 * POST request - create new record (typical use case)
	 **/
	public function post(res,data) {
		prepareHelperArgs(arguments);
		return doRequest("POST",arguments.res,arguments.data);
	}
	/**
	 * PUT request - update entire record (typical use case)
	 **/
	public function put(res,data) {
		prepareHelperArgs(arguments);
		return doRequest("PUT",arguments.res,arguments.data);
	}
	/**
	 * PATCH request - update record with delta (typical use case)
	 * NOTE: this does not work in CF10-, and is redirected to PUT
	 **/
	public function patch(res,data) {
		prepareHelperArgs(arguments);

		// CF10 does not support PATCH requests???
		if (isNull(server.railo) && val(server.coldfusion.productversion) == 10) {
			return doRequest("PUT",arguments.res,arguments.data);
		} else {
			return doRequest("PATCH",arguments.res,arguments.data);
		}
	}
	/**
	 * DELETE request - delete a record
	 **/
	public function delete(res,data) {
		prepareHelperArgs(arguments);
		return doRequest("DELETE",arguments.res,arguments.data);
	}
	/**
	 * HEAD request - metadata request
	 **/
	public function head(res,data) {
		prepareHelperArgs(arguments);
		return doRequest("HEAD",arguments.res,arguments.data);
	}

}
