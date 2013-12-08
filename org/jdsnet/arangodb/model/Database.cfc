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
 * Database
 * 
 * @author jesse.shaffer
 * @date 11/30/13
 **/
component accessors=true output=false persistent=false {
	
	property Connection Connection;
	property string Name;
	
	public function init(required Connection connection, required string name) {
		this.setConnection(arguments.connection);
		this.setName(arguments.name);
		
		variables.dbService = this.getConnection().openService("database",this.getName());
		variables.cService = this.getConnection().openService("collection",this.getName());
		
		return this;
	}
	
	public function getCollections(string type="user") {
		
		var allCollections = cService.get();
		
		var retval = allCollections;
		switch(arguments.type) {
			case "user":
				var aclen = arraylen(allCollections.collections);
				for (var i=1; i <= aclen; i++) {
					if (left(allCollections.collections[i].name,1) == "_") {
						structDelete(allCollections.names,allCollections.collections[i].name);
						arrayDeleteAt(allCollections.collections,i);
						i--;
						aclen--;
					}
				}
			break;
			case "sys":
			case "system":
				var aclen = arraylen(allCollections.collections);
				for (var i=1; i <= aclen; i++) {
					if (left(allCollections.collections[i].name,1) != "_") {
						structDelete(allCollections.names,allCollections.collections[i].name);
						arrayDeleteAt(allCollections.collections,i);
						i--;
						aclen--;
					}
				}
			break;
		}
		return retval;
	}
	
	public  function createCollection(required string name, struct options) {
		if (isNull(options)) options={};
		var collection = {
			 "name"			= arguments.name
			,"waitForSync"	= false
			,"doCompact"	= true
		//	,"journalSize"	= << default is configured in arangod.conf >>
			,"isVolatile"	= false
			,"keyOptions"	= {
				 "type"				= "traditional"
				,"allowUserKeys"	= true
			}
		};
		structAppend(collection,options);
		options["isSystem"]=false;
		options["type"]=2;
		writedump(cService.post(collection));
		
	}
	
	public  function dropCollection(required string name) {
		return cService.delete(name);
	}
	
	public  function getCollection(required string name) {
		return new Collection(name=name, database=this);
	}
	
	public Document function getDocumentById(required string id) {
		var parts = id.split("/");
		return this.getCollection(parts[1]).getDocumentByKey(parts[2]);
	}
	
}