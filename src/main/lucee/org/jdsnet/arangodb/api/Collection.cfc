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

	this.DOCUMENT_COLLECTION = 2;
	this.EDGE_COLLECTION = 3;

	public array function list(boolean includeSystem=false) {
		return callApi("collection", {"excludeSystem": (!includeSystem)}, "GET").data.result;
	}

	public struct function create(options={}) {
		// required options.name
		param name="options.name"			type="string";
		param name="options.type"			type="numeric" default=this.DOCUMENT_COLLECTION;

		return callApi("collection", options, "POST").data;
	}

	public boolean function drop(required string name) {
		return callApi("collection/#name#", "", "DELETE").status.code == 200;
	}

	public struct function info(required string name) {
		var result = callApi("collection/#name#", "", "GET");

		if (result.status.code < 300)
			return result.data;
	}

	public numeric function getChecksum(required string name) {
		return callApi("collection/#name#/checksum", "", "GET").data.checksum;
	}

	public struct function getCount(required string name) {
		return callApi("collection/#name#/count", "", "GET").data.count;
	}

	public struct function getFigures(required string name) {
		return callApi("collection/#name#/figures", "", "GET").data;
	}

	public struct function load(required string name, boolean count=false) {
		return callApi("collection/#name#/load", {"count":count}, "PUT").data;
	}

	public struct function getProperties(required string name) {
		return callApi("collection/#name#/figures", "", "GET").data;
	}

	public struct function setProperties(required string name, boolean waitForSync, numeric journalSize) {
		return callApi("collection/#name#/properties", {"waitForSync": waitForSync, "journalSize":journalSize}, "PUT").data;
	}

	public struct function rename(required string name, required string newName) {
		return callApi("collection/#name#/rename", {"name":newName}, "PUT").data;
	}

	public any function getRevision(required string name) {
		return callApi("collection/#name#/revision", "", "GET").data.revision;
	}

	public struct function rotate(required string name) {
		return callApi("collection/#name#/rotate", "", "PUT").data;
	}

	public struct function truncate(required string name) {
		return callApi("collection/#name#/rotate", "", "PUT").data;
	}

	public struct function unload(required string name) {
		return callApi("collection/#name#/unload", "", "PUT").data;
	}


	public array function listIndexes(required string name) {
		return callApi("index?collection=#name#", "", "GET").data.indexes;
	}

	public struct function createIndex(required string name, required string type, required array fields, minLength) {
		var data = {"type":type, "fields": fields};
		if (!isNull(minLength)) data["minLength"] = minLength;
		return callApi("index", data, "POST").data;
	}

	public boolean function dropIndex(required string indexId) {
		return callApi("index/#indexId#", "", "DELETE").status.code < 300;
	}

	public struct function getIndex(required string indexId) {
		return callApi("index/#indexId#", "", "GET").data;
	}

	public array function getEdges(required string edgeCollection, required string vertexHandle, string direction) {
		var params = {
			"vertex":vertexHandle
		};

		if (!isNull(direction))
			params["direction"] = direction;

		return callApi("edges/#edgeCollection#", params, "GET").data.edges;
	}

}