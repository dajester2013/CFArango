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
 * Collection
 * 
 * @author jesse.shaffer
 * @date 11/30/13
 **/
component accessors=true output=false persistent=false {

	property struct Properties;
	property string Name;
	property Database Database;
	
	public Document function newDocument(struct data={}) {
		return new Document(data,this);
	}
	
	public Document function save(required record) {
		if (isInstanceOf(record,"Document")) {
			record.save();
		} else if (isStruct(record) || isObject(record)) {
			record = this.newDocument(record).save();
		}
		
		return record;
	}
	
	public struct function load() {
		return openService("collection").put("#this.getName()#/load");
	}
	
	public struct function unload() {
		return openService("collection").put("#this.getName()#/unload");
	}
	
	public Document function getDocumentByKey(required string key) {
		return this.createDocument(openService("document").get("#this.getName()#/#key#"));
	}
	
	public function truncate() {
		return openService("collection").put("#this.getName()#/truncate");
	}
	
	public struct function drop() {
		return this.getDatabase().dropCollection(this.getName());
	}
	
	public boolean function rotate() {
		return openService("collection").put("#this.getName()#/rotate").result;
	}
	
	// TODO: fulltext query
	// TODO: query all by example
	// TODO: update all by example
	// TODO: replace all by example
	// TODO: remove all by example
	// TODO: create index
	// TODO: drop index
	
	
	public function getProperties() {
		if (!structKeyExists(variables,"properties"))
			variables.properties = openService("collection").get("#this.getName()#/properties");
		
		return variables.properties;
	}
	private function setProperties() {}

	private function openService(required string svc) {
		return this.getDatabase().getConnection().openService(svc,this.getDatabase().getName());
	}
}