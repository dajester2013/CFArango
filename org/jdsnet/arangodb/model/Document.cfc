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
 * Document
 * 
 * @author jesse.shaffer
 * @date 11/30/13
 **/
component accessors=true output=false persistent=false {

	property string id;
	property string key;
	property string rev;
	property Collection collection;
	property struct originalDocument;
	property struct currentDocument;
	property string updateMode default="patch";
	
	this.MODE_UPDATE = "patch";
	this.MODE_REPLACE = "put";
	
	variables.currentDocument	= {};
	variables.dirty				= true;
	
	public Document function init(struct document={}, Collection collection) {
		if (!isNull(arguments.collection))
			this.setCollection(arguments.collection);
		
		this.setCurrentDocument(duplicate(arguments.document));
		
		if (structKeyExists(arguments.document,"_id")) {
			variables.id = arguments.document._id;
			this.setOriginalDocument(duplicate(arguments.document));
			variables.dirty=false;
		} else {
			this.setOriginalDocument({});
		}
		if (structKeyExists(arguments.document,"_key"))	this.setKey(arguments.document._key);
		if (structKeyExists(arguments.document,"_rev"))	this.setRev(arguments.document._rev);
		
		return this;
	}
	
	public Document function setCollection(Collection collection) {
		variables.COL_RES = "?collection="&collection.getName();
		variables.collection=collection;
		
		if (!isNull(this.getId()) && listFirst(this.getId(),"/") != collection.getName()) {
			StructDelete(variables,"id");
			StructDelete(variables,"_id");
			StructDelete(variables.currentDocument,"_id");
			StructDelete(variables.originalDocument,"_id");
		}
		
		return this;
	}
	
	public Document function put(required string key, required any value) {
		if (key != '_id')
			variables.currentDocument[key] = value;
		
		variables.dirty = !structKeyExists(variables.originalDocument,key) || (!isObject(variables.currentDocument[key]) && variables.currentDocument[key] != variables.originalDocument[key]);
		
		return this;
	}
	
	public Document function putAll(required struct values) {
		StructAppend(variables.currentDocument,values);
		
		variables.dirty = true;
		
		return this;
	}
	
	public Document function clear(string key) {
		if (!isNull(key)) {
			structDelete(variables.currentDocument,key);
		} else {
			structClear(variables.currentDocument);
		}
		this.setUpdateMode(this.MODE_REPLACE);
		return this;
	}
	
	public any function get(string key="") {
		var rv = variables.currentDocument;
		
		if (len(arguments.key))
			rv = rv[key];
			
		return duplicate(rv);
	}
	
	public Document function save(boolean force=false) {
		if (!force && !dirty) return this;
		
		if (isNull(this.getCollection()))
			throw("No collection specified.");
		
		if (isNull(this.getId()))
			var res = openService("document").post(variables.COL_RES,variables.currentDocument)
		else
			var res = openService("document")[this.getUpdateMode()](this.getId(),variables.currentDocument);
		
		
		structDelete(res,"error");
		structappend(variables.currentDocument,res);
		structappend(variables.originalDocument,variables.currentDocument);
		
		if (structKeyExists(res,"_id"))
			variables.id=res._id;
		if (structKeyExists(res,"_key"))
			this.setKey(res._key);
		if (structKeyExists(res,"_rev"))
			this.setRev(res._rev);
		
		dirty=false;
		return this;
	}
	
	public boolean function isDirty() {
		return dirty;
	}
	
	
	public boolean function delete() {
		var res = !openService("document").delete(this.getId()).error;
		structclear(variables);
		return res;
	}

	public Edge function createEdge(required any collection, struct edgeData={}) {
		if (!isObject(arguments.collection))
			arguments.collection = this.getCollection().getDatabase().getCollection(arguments.collection);

		var edge = new Edge(arguments.edgeData,arguments.collection);
		edge.setInitiator(this);
		return edge;
	}
	
	public function setId() {}
	public function getCurrentDocument() {return this.get();}
	public function getOriginalDocument() {return duplicate(variables.originaldocument);}
	
	private function openService(required string svc) {
		return this.getCollection().getDatabase().getConnection().openService(svc,this.getCollection().getDatabase().getName());
	}
}