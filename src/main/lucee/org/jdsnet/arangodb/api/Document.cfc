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

	public function batchCreate(required string collection, required array documents) {
		return callAPI("import?collection=#collection#", documents, "POST").data;
	}

	public function batchDelete(required string collection, required array toDelete) {
		return callAPI("document/#collection#", toDelete, "DELETE").data;
	}

	public function batchUpdate(required string collection, required array updates, struct options={}) {
		var api = "document/#collection#";
		var qry = options.reduce(function(qstr="?", key, value) {return qstr & key & value & "&";});

		return callAPI(api & qry, updates, "PATCH").data;
	}

	public function create(required string collection, required struct document) {
		return callAPI("document/#collection#", document, "POST").data;
	}

	public function batchReplace(required string collection, required array replacements, struct options={}) {
		var api = "document/#collection#";
		var qry = options.reduce(function(qstr="?", key, value) {return qstr & key & value & "&";});

		return callAPI(api & qry, replacements, "PUT").data;
	}

	public function delete(handle) {
		return callAPI("document/#handle#", "", "DELETE").status.code < 300;
	}

	public function read(required string handle) {
		return callAPI("document/#handle#", "", "GET").data;
	}

	public function header(required string handle) {
		return callAPI("document/#handle#", "", "HEAD");
	}

	public function update(required string handle, required struct updates) {
		return callAPI("document/#handle#", updates, "PATCH").data;
	}

	public function replace(required string handle, required struct replacements) {
		return callAPI("document/#handle#", replacements, "PUT").data;
	}

}