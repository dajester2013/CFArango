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

	public array function list() {
		return callAPI("gharial", "", "GET").data.graphs;
	}

	public struct function create(required string name, required array orphanCollections, required array edgeDefinitions, required boolean isSmart, smartGraphAttribute, numberOfShards) {
		var options = {};
		if (!isNull(smartGraphAttribute)) options.smartGraphAttribute = smartGraphAttribute;
		if (!isNull(numberOfShards)) options.numberOfShards = numberOfShards;

		return callAPI("gharial", {
			 "name"					: name
			,"orphanCollections"	: orphanCollections
			,"edgeDefinitions"		: edgeDefinitions
			,"isSmart"				: isSmart
			,"options"				: options
		}, "POST").data;
	}

	public boolean function drop(graphName) {
		return callAPI("gharial/#graphName#", "", "DELETE").status.code < 300;
	}

	public struct function get(graphName) {
		return callAPI("gharial/#graphName#", "", "GET").data.graph;
	}

	public array function listEdgeCollections() {
		return callAPI("gharial/#graphName#/edge", "", "GET").data.collections;
	}

	public struct function createEdgeDefinition(required string graphName, required string collection, required array to, required array from) {
		return callAPI("gharial/#graphName#/edge", {"collection":collection, "to":to, "from":from}, "POST").data;
	}

	public struct function createEdge(required string graphName, required string collection, required struct document) {
		return callAPI("gharial/#graphName#/edge/#collection#", document, "POST").data;
	}

	public boolean function dropEdge(required string graphName, required string handle) {
		return callAPI("gharial/#graphName#/edge/#handle#", "", "DELETE").status.code < 300;
	}

	public struct function getEdge(required string graphName, required string handle) {
		return callAPI("gharial/#graphName#/edge/#handle#", "", "GET").data.edge;
	}

	public struct function updateEdge(required string graphName, required string handle, required struct update) {
		return callAPI("gharial/#graphName#/edge/#handle#", update, "PATCH").data.edge;
	}

	public struct function replaceEdge(required string graphName, required string handle, required struct update) {
		return callAPI("gharial/#graphName#/edge/#handle#", update, "PUT").data.edge;
	}

	public boolean function removeEdgeDefinition(required string graphName, required string edgeName) {
		return callAPI("gharial/#graphName#/edge/#edgeName#", "", "DELETE").status.code < 300;
	}

	public struct function replaceEdgeDefinition(required string graphName, required string collection, required array to, required array from) {
		return callAPI("gharial/#graphName#/edge/#collection#", {"collection":collection, "to":to, "from":from}, "PUT").data;
	}

	public array function listVertexCollections(required string graphName) {
		return callAPI("gharial/#graphName#/vertex", "", "GET").data.collections;
	}

	public struct function addVertexCollection(required string graphName, required string collection) {
		return callAPI("gharial/#graphName#/vertex", {"collection":collection}, "GET").data.graph;
	}

	public boolean function removeVertexCollection(required string graphName, required string collection) {
		return callAPI("gharial/#graphName#/vertex/#collection#", "", "DELETE").status.code < 300;
	}

	public struct function createVertex(required string graphName, required string collection, required struct document) {
		return callAPI("gharial/#graphName#/vertex/#collection#", document, "POST").data.vertex;
	}

	public boolean function dropVertex(required string graphName, required string handle) {
		return callAPI("gharial/#graphName#/vertex/#handle#", "", "DELETE").status.code < 300;
	}

	public struct function getVertex(required string graphName, required string handle) {
		return callAPI("gharial/#graphName#/vertex/#handle#", "", "GET").data.vertex;
	}

	public struct function updateVertex(required string graphName, required string handle, required struct update) {
		return callAPI("gharial/#graphName#/vertex/#handle#", update, "PATCH").data.vertex;
	}

	public struct function replaceVertex(required string graphName, required string handle, required struct update) {
		return callAPI("gharial/#graphName#/vertex/#handle#", update, "PUT").data.vertex;
	}

	public struct function traverse(required struct traversal) {
		return callAPI("traversal", traversal, "POST").data;
	}

}