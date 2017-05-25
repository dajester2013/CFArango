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

	public struct function all(required string collection, numeric batchSize=100, numeric skip, numeric limit) {
		var opts = {"collection":collection, "batchSize":batchSize};
		if (!isNull(skip) && !isNull(limit)) {
			structAppend(opts, {"skip":skip, "limit":limit});
		}
		return callApi("simple/all", opts, "PUT").data;
	}

	public function allKeys(required string collection, required string type) {
		return callAPI("simple/all-keys", {"collection":collection, "type":type}, "PUT").data;
	}

	public struct function any(required string collection) {
		return callApi("simple/any", "", "PUT").data;
	}

	public struct function byExample(required string collection, required struct example, numeric batchSize=100, numeric skip, numeric limit) {
		var opts = {"collection":collection, "batchSize":batchSize, "example":example};
		if (!isNull(skip) && !isNull(limit)) {
			structAppend(opts, {"skip":skip, "limit":limit});
		}
		return callApi("simple/by-example", "", "PUT").data;
	}

	public struct function firstExample(required string collection, required struct example) {
		return callApi("simple/first-example", arguments, "PUT").data;
	}

	public struct function lookupByKeys(required string collection, required array keys) {
		return callApi("simple/lookup-by-keys", arguments, "PUT").data;
	}

	public struct function removeByExample(required string collection, required struct example, struct options) {
		return callApi("simple/remove-by-example", arguments, "PUT").data;
	}

	public struct function removeByKeys(required string collection, required array keys, struct options) {
		return callApi("simple/remove-by-keys", arguments, "PUT").data;
	}

	public struct function replaceByExample(required string collection, required struct example, required struct newValue, struct options) {
		return callApi("simple/replace-by-example", arguments, "PUT").data;
	}

	public struct function updateByExample(required string collection, required struct example, required struct newValue, struct options) {
		return callApi("simple/update-by-example", arguments, "PUT").data;
	}

}