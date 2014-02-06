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
 * This object wraps a document stored within an ArangoDB database.
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
	property string updateMode;
	
	this.MODE_UPDATE = "patch";
	this.MODE_REPLACE = "put";
	
	this.setUpdateMode(this.MODE_REPLACE);
	
	variables.currentDocument	= {};
	variables.dirty				= true;
	
	/**
	 * Constructor
	 * @document The initial set of data to wrap.  If an _id is set, this document is assumed to exist in the database already.
	 * @collection (Optional) The collection model representative of where this document is stored.
	 **/
	public Document function init(struct document={}, Collection collection) {
		if (!isNull(arguments.collection)) {
			this.setCollection(arguments.collection);
		}
		
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
	
	/**
	 * Change the collection for this document.  Changing the collection of an existing document does not remove the document from the previous collection automatically.
	 * @collection The new collection to save this document to.
	 **/
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
	
	/**
	 * Put a value into this document.
	 * @key Key name
	 * @value Value
	 **/
	public Document function put(required string key, required any value) {
		if (key != '_id') {
			var putinto = variables.currentDocument;
			var keyparts = key.split("\.");
			var keypartslen = arraylen(keyparts);
			for(var i=1; i<keypartslen; i++) {
				if (isNull(putinto[keyparts[i]])) {
					putinto = putinto[keyparts[i]] = isNumeric(keyparts[i+1])?[]:{};
				} else if (isStruct(putinto[keyparts[i]]) || isArray(putinto[keyparts[i]])) {
					putinto = putinto[keyparts[i]];
				} else {
					throw(type="InvalidDestinationException",message="Cannot put value at the key requested - it is assigned a simple value already.");
				}
			}
			
			if (isArray(putinto) && !isNumeric(keyparts[i])) {
				throw(type="InvalidDestinationException",message="Cannot put value at the key requested - attempted to use a string for an array index.");
			}
			
			putinto[keyparts[i]] = value;
		
			variables.dirty = true;
		}
		
		return this;
	}
	
	/**
	 * Appends a struct of values into this document.
	 * @values The values to add
	 **/
	public Document function putAll(required struct values) {
		StructAppend(variables.currentDocument,values);
		
		variables.dirty = true;
		
		return this;
	}

	/**
	 * Delete a key from the document.  This automatically switches save mode to MODE_REPLACE.
	 * @key The key to delete
	 **/
	public Document function clear(string key) {
		if (!isNull(key)) {
			structDelete(variables.currentDocument,key);
		} else {
			structClear(variables.currentDocument);
		}
		this.setUpdateMode(this.MODE_REPLACE);
		return this;
	}
	
	/**
	 * Get a value from the current document
	 * @key (Optional) Which key to retrieve. If left blank the entire contents of the currentdocument is returned.
	 **/
	public any function get(string key="") {
		var rv = variables.currentDocument;
		
		if (len(arguments.key)) {
			var keyparts = key.split("\.");
			var keypartslen = arraylen(keyparts);
			for(var i=1; i<=keypartslen; i++){
				if (!isNull(rv[keyparts[i]])) {
					rv = rv[keyparts[i]];
				} else {
					return; // could  not find at the requested level, return "null"
				}
			}
		}
			
		return duplicate(rv);
	}
	
	/**
	 * Save the document to the configured collection.
	 * @force Whether or not to ignore the dirty flag.
	 **/
	public Document function save(boolean force=false) {
		if (!force && !dirty) return this;
		
		if (isNull(this.getCollection())) {
			throw("No collection specified.");
		}
		
		if (isNull(this.getId())) {
			var res = openService("document").post(variables.COL_RES,variables.currentDocument);
		} else {
			var svc = openService("document");
			svc._updater = svc[this.getUpdateMode()];
			var res = svc._updater(this.getId(),variables.currentDocument);
		}
		
		structDelete(res,"error");
		structappend(variables.currentDocument,res);
		structappend(variables.originalDocument,variables.currentDocument);
		
		if (structKeyExists(res,"_id")) {
			variables.id=res._id;
		}
		if (structKeyExists(res,"_key")) {
			this.setKey(res._key);
		}
		if (structKeyExists(res,"_rev")) {
			this.setRev(res._rev);
		}
		
		dirty=false;
		return this;
	}
	
	/**
	 * Determine whether or not the document is dirty - that is, it has been changed from the original document.
	 **/
	public boolean function isDirty() {
		return dirty;
	}
	
	/**
	 * Delete the document from the database.  This method is destructive to the database as well as this object.
	 * If successful, all keys in this document model will be cleared.
	 **/
	public boolean function delete() {
		var res = !openService("document").delete(this.getId()).error;
		if (res) structclear(variables);
		return res;
	}

	/**
	 * This creates an edge document in order to connect this document to another document.
	 * @collection An edge collection model or the name of the edge collection.
	 * @edgeData Extra information to track in the edge document (do not pass _to/_from in this struct)
	 **/
	public Edge function createEdge(required any collection, struct edgeData={}) {
		if (!isObject(arguments.collection)) {
			arguments.collection = this.getCollection().getDatabase().getCollection(arguments.collection);
		}

		var edge = new Edge(arguments.edgeData,arguments.collection);
		edge.setInitiator(this);
		return edge;
	}
	
	/**
	 * Get the current document (read only)
	 **/
	public function getCurrentDocument() {return this.get();}

	/**
	 * Get the original document (read only)
	 **/
	public function getOriginalDocument() {return duplicate(variables.originaldocument);}
	
	private function setId() {}
	private function openService(required string svc) {
		return this.getCollection().getDatabase().getConnection().openService(svc,this.getCollection().getDatabase().getName());
	}

}
