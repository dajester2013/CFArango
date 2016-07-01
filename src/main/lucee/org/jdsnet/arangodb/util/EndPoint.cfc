/*
 * The MIT License (MIT)
 * Copyright (c) 2016 Jesse Shaffer
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

import org.jdsnet.arangodb.driver;

/**
 * Base model
 **/
component accessors=true {
	
	property name="driver"	type="Driver" setter=false;
	property name="path"	type="string" setter=false;
	property name="methods"	type="array"  setter=false;
	
	public function init(Driver driver, string path, methods=["get","post","put","patch","delete"]) {
		variables.driver = arguments.driver;
		variables.path = arguments.path;
		variables.methods = arguments.methods;
		
		return this;
	}
	
	private struct function doRequest(params={}, struct data, method) {
		if (!variables.methods.findNoCase(method)) {
			throw("Invalid Method #method#");
		}
		
		var apiPath = this.getPath();
		
		if (isNull(data) && (!find(":", apiPath) || !isStruct(params))) {
			data = params;
			params = {};
		} else if (isStruct(params)) {
			for (var p in params) {
				apiPath = apiPath.replaceNoCase(":#p#", params[p]);
			}
		}
		
		return driver.executeApiRequest(apiPath, data ?: "", method);
	}
	
	public struct function get		(params, struct data) { arguments.method = "GET";	return doRequest(argumentCollection=arguments); }
	public struct function post		(params, struct data) { arguments.method = "POST";	return doRequest(argumentCollection=arguments); }
	public struct function put		(params, struct data) { arguments.method = "PUT";	return doRequest(argumentCollection=arguments); }
	public struct function patch	(params, struct data) { arguments.method = "PATCH";	return doRequest(argumentCollection=arguments); }
	public struct function delete	(params, struct data) { arguments.method = "DELETE";	return doRequest(argumentCollection=arguments); }
	
}