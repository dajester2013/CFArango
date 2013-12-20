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

import org.jdsnet.arangodb.query.Cursor;

/**
 * Collection
 * 
 * @author jesse.shaffer
 * @date 11/30/13
 **/
component accessors=true output=false persistent=false {

	property struct Properties;
	property string Name;
	property Database Database;
	
	/**
	 * Creates a document interface.  May be an existing document or a new document - the latter not being created until the save() method is called on the returned Document.
	 **/
	public Document function newDocument(struct data={}) {
		var type = this.getProperties().type;
		if (type == 2) {
			return new Document(data,this);
		} else if (type == 3) {
			return new Edge(data,this);
		}
	}
	
	/**
	 * Creates a new document in the collection
	 **/
	public Document function save(required record) {
		if (isInstanceOf(record,"Document")) {
			record.save();
		} else if (isStruct(record) || isObject(record)) {
			record = this.newDocument(record).save();
		}
		
		return record;
	}
	
	/**
	 * Load this collection into server memory
	 **/
	public struct function load() {
		return openService("collection").put("#this.getName()#/load");
	}
	
	/**
	 * Unload this collection from server memory
	 **/
	public struct function unload() {
		return openService("collection").put("#this.getName()#/unload");
	}
	
	/**
	 * Get a document by id/key
	 **/
	public Document function getDocument(required string key) {
		return this.newDocument(openService("document").get("#this.getName()#/#key.replaceAll("[^\/]+\/","")#"));
	}
	
	/**
	 * Delete all documents
	 **/
	public function truncate() {
		return openService("collection").put("#this.getName()#/truncate");
	}
	
	/**
	 * Destroys this collection
	 **/
	public struct function drop() {
		return this.getDatabase().dropCollection(this.getName());
	}
	
	/**
	 * Rotate the journal for this collection.  Flushes deleted documents.
	 **/
	public boolean function rotate() {
		return openService("collection").put("#this.getName()#/rotate").result;
	}
	
	/**
	 * Search for documents that match {example}
	 **/
	public any function queryByExample(required struct example, any limit, numeric skip=0, boolean raw=false) {
		var response = {};
		
		if (!isNull(limit) && limit == "first") {
			response = openService("simple/first-example").put({
				 "example"		= arguments.example
				,"collection"	= this.getName()
			});

			return raw ? response.document : this.newDocument(response.document);
		} else {
			var sreq = {
				 "example"		= arguments.example
				,"collection"	= this.getName()
				,"skip"			= arguments.skip
			};
			
			if (!isNull(arguments.limit) && isNumeric(arguments.limit))
				sreq["limit"] = arguments.limit;
			
			response = openService("simple/by-example").put(sreq);
			
			if (!raw) {
				for (var i=1; i<=arraylen(response.result); i++) {
					response.result[i] = this.newDocument(response.result[i]);
				}
			}
			
			return new Cursor(response);
		}
	}
	
	/**
	 * Perform a full text search
	 **/
	public array function fullTextSearch(required string attribute, required string searchText, boolean raw=false) {
		var response = openService("simple/fulltext").put({
			 "collection"	= this.getName()
			,"attribute"	= arguments.attribute
			,"query"		= arguments.searchText
		});
		
		if (!raw) {
			for (var i=1; i<=arraylen(response.result); i++) {
				response.result[i] = this.newDocument(response.result[i]);
			}
		}

		return new Cursor(response);
	}
	
	/**
	 * Adds/updates keys set in {update} to all documents matched by {example}, up to {limit}
	 **/
	public struct function updateByExample(required struct example, required struct update, numeric limit, boolean keepNull=true, boolean waitForSync) {
		var srequest = {
			 "example"		= arguments.example
			,"collection"	= this.getName()
			,"newValue"		= update
			,"keepNull"		= arguments.keepNull
		};
		if (!isNull(arguments.limit))
			srequest["limit"] = arguments.limit;
		
		if (!isNull(waitForSync))
			srequest["waitForSync"] = arguments.waitForSync;
		
		var response = openService("simple/update-by-example").put(srequest);
		
		return response;
	}
	
	/**
	 * Replaces all keys in documents matched by {example} with the keys set in {update}, up to {limit}
	 **/
	public struct function replaceByExample(required struct example, required struct update, numeric limit, boolean waitForSync) {
		var srequest = {
			 "example"		= arguments.example
			,"collection"	= this.getName()
			,"newValue"		= update
		};
		if (!isNull(arguments.limit))
			srequest["limit"] = arguments.limit;
		if (!isNull(waitForSync))
			srequest["waitForSync"] = arguments.waitForSync;
		
		var response = openService("simple/replace-by-example").put(srequest);
		
		return response;
	}
	
	/**
	 * Deletes all documents matching the {example}, up to {limit}
	 **/
	public struct function deleteByExample(required struct example, numeric limit, boolean waitForSync) {
		var srequest = {
			 "example"		= arguments.example
			,"collection"	= this.getName()
		};
		if (!isNull(arguments.limit))
			srequest["limit"] = arguments.limit;
		if (!isNull(waitForSync))
			srequest["waitForSync"] = arguments.waitForSync;
		
		var response = openService("simple/replace-by-example").put(srequest);
		
		return response;
	}
	
	/**
	 * Create an index on this collection
	 **/
	public struct function createIndex(required struct indexParams) {
		return openService("index").post("?collection=#this.getName#",indexParams);
	}
	
	/**
	 * Drops an index - enforces this collection as the owner of the index.
	 **/
	public struct function dropIndex(required string indexId) {
		return openService("index").delete(this.getName() & "/" & indexId.replaceAll("^[^\/]+\/",""));
	}
	
	/**
	 * Get properties about this Collection
	 **/
	public function getProperties() {
		if (!structKeyExists(variables,"properties"))
			variables.properties = openService("collection").get("#this.getName()#/properties");
		
		return variables.properties;
	}
	
	// disable setter
	private function setProperties() {}
	// to reduce typing...
	private function openService(required string svc) {
		return this.getDatabase().getConnection().openService(svc,this.getDatabase().getName());
	}
}