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

import org.jdsnet.arangodb.driver;

/**
 * Collection model
 **/
component extends=BaseModel accessors=true {

	property name="Id" setter=false;
	property name="Name" setter=false;
	property name="IsSystem" setter=false;

	public function init(Driver driver, string name) {
		super.init(driver);

		defineEndpoints({
			"DatabaseInfo"		: "get@/database/current",
			"Collection"		: "post,delete@/collection/:name"
		});

		structAppend(variables, endpoints.DatabaseInfo.get().data.result);

		return this;
	}

	public Collection function createCollection(required string name, struct options={}) {
		options["name"] = name;
		options["type"] = options.type ?: 2;

		endpoints.Collection.post({name:""}, options);

		return this.getCollection(name);
	}

	public Collection function createEdgeCollection(required string name, struct options={}) {
		options["type"] = 3;
		return this.createCollection(name, options);
	}

	public boolean function dropCollection(required string name) {
		return !endpoints.Collection.delete({name:name}).data.error;
	}

	public struct function getCollections(type="user") {
		var collections = driver.executeApiRequest("collection").data.result;

		return collections.reduce(function(result={}, c) {
			if (
					(c.isSystem && (type == "sys"||type == "all"))
				||	(!c.isSystem && (type == "user"||type == "all"))
			) {
				result[c.name] = this.getCollection(c.name);
			}
			return result;
		});
	}

	public function getCollection(required string name) {
		var result = driver.executeApiRequest("collection/#name#");

		if (result.status.code < 300)
			if (result.data.type == 2)
				return new Collection(driver, name);
			else
				return new EdgeCollection(driver, name);
	}

	public function getGraph(required string name) {
		var result = driver.executeApiRequest("gharial/#name#");

		if (result.status.code < 300) {
			return new Graph(driver,name);
		}
	}

	public function read(required handle) {
		return this.getDriver().getApi("Document").read(handle);
	}

	/**
	 * Writes a document to the database
	 *
	 * @data struct or object to write to the database.  must be serializable to json.
	 * @collection specify the collection name if the data does not have an _id key, or @DocumentId property
	 * @merge in case of an update, whether to merge the data with the existing document or replace.  defaults to replace
	 */
	public function write(data, string collection, boolean merge=false) {
		var docApi = this.getDriver().getApi("Document");

		if (isObject(data)) {
			var document = deserializeJson(serializeJSON(data));
			var metadata = getMetadata(data);
			var collectionName = metadata.collection ?: metadata.name.listLast(".");
			
			/* check for a key first */
			if (!document.keyExists("_key")) {
				var props = metadata.properties ?: arraynew(1);

				for (var p in props) {
					if (p.keyExists("DocumentKey")) {
						document._key = document[p.name];
						structDelete(document, p.name);
						break;
					}
				}
			}

			structDelete(document,"_id");

			this.write(document, collectionName);
		} else if (isStruct(data)) {
			var action = "create";

			if (data.keyExists("_id")) {
				action = merge ? "update" : "replace";
			} else {
				if (isNull(collection)) {
					cfthrow(message="Collection name required.");
				}
				
				// if theres a key, and the document exists, set the i
				if (data.keyExists("_key")) {
					if (docApi.header("#collection#/#data._key#").status.code < 300) {
						data.id = "#collection#/#data._key#";
						action = merge ? "update":"replace";
					}
				}
			}

			switch(action) {
				case "create": return docApi.create(collection, data);
				case "update": return docApi.update(data._id, data);
				case "replace": return docApi.replace(data._id, data);
			}
		} else {
			cfthrow(message="can only insert objects or structs");
		}
	}

	public function delete(required string handle) {
		return this.getDriver().getApi("Document").delete(handle);
	}

	

	public function search(required string collection, limit=0,skip=0, struct filters={}) {
		var filterUtil = new org.jdsnet.arangodb.util.FilterParser();

		var params = {
			"@collection":collection
		};
		
		var filterStmt = "";
		if (structCount(filters)) {
			var parsed = filterUtil.parseStruct(filters, "$doc");
			filterStmt = parsed.stmt;
			structAppend(params, parsed.params);
		}

		var limitStmt = "";

		if (limit+skip > 0) {
			if(skip) params["skip"]=skip;
			
			params["limit"] = limit;

			limitStmt = "LIMIT " & (skip ? "@skip, " : "") & "@limit";
		}

		var readStatement = this.prepareStatement("for $doc in @@collection #filterStmt# #limitStmt# return $doc");

		return readStatement.execute(params).getData();
	}


	public function prepareStatement(required string aql) {
		return new AQLQuery(this.getDriver(), aql);
	}


	public function documentExists(required string handle) {
		return this.getDriver().getApi("Document").header(handle).status.code < 300;
	}

}