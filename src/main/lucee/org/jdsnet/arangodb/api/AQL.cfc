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

component extends=AbstractAPI {

	public array function getFunctions(namespace) {
		return Driver.executeApiRequest("aqlfunction", arguments, "GET").data;
	}

	public boolean function createFunction(required string name, required string code, boolean isDeterministic=true) {
		return !Driver.executeApiRequest("aqlfunction", arguments, "POST").data.error;
	}

	public boolean function deleteFunction(required string name) {
		return !Driver.executeApiRequest("aqlfunction/#name#","", "DELETE").data.error;
	}

	public struct function explainQuery(required string query, struct bindVars={}, struct options={}) {
		return Driver.executeApiRequest("explain", arguments, "POST").data.plan;
	}

	public struct function parseQuery(required string query) {
		return Driver.executeApiRequest("query", arguments, "POST").data;
	}

	public boolean function clearQueryCache() {
		return !Driver.executeApiRequest("query-cache", "", "DELETE").data.error;
	}

	public struct function getCacheProperties() {
		var result = Driver.executeApiRequest("query-cache/properties", "", "GET").data;
		structDelete(result, "error");
		structDelete(result, "code");
		return result;
	}

	public boolean function setCacheProperties(mode, maxResults) {
		structAppend(arguments, getCacheProperties());
		return !Driver.executeApiRequest("query-cache/properties", arguments, "PUT").data.error;
	}

	public array function getRunningQueries() {
		return Driver.executeApiRequest("query/current", "", "GET").data;
	}

	public struct function getQueryProperties() {
		var result = Driver.executeApiRequest("query/properties", "", "GET").data;
		structDelete(result, "error");
		structDelete(result, "code");
		return result;
	}

	public boolean function setQueryProperties(slowQueryThreshold, enabled, maxSlowQueries, trackSlowQueries, maxQueryStringLength) {
		structAppend(arguments, getQueryProperties());
		return !Driver.executeApiRequest("query/properties", arguments, "PUT").data.error;
	}

	public boolean function clearSlowQueries() {
		return Driver.executeApiRequest("query/slow", "", "DELETE").status.code == 200;
	}

	public array function getSlowQueries() {
		return Driver.executeApiRequest("query/slow", "", "GET").data;
	}

	public boolean function killQuery(required id) {
		return Driver.executeApiRequest("query/#id#", "", "DELETE").status.code == 200;
	}

}