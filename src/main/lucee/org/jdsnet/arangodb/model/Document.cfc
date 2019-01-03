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
component	extends		= BaseModel
			accessors	= true
			output		= false
			persistent	= false
{

	property type="string" name="id" setter=false;
	property type="string" name="key";
	property type="string" name="rev" setter=false;
	property type="string" name="collection";

	property type="struct" name="data";

	property type="string" name="updateMode";

	key = createuuid();

	this.UpdateModes = {
		 REPLACE	= "replace"
		,MERGE		= "update"
	};

	updateMode = "replace";

	function init(driver, data={}, org.jdsnet.arangodb.model.Collection collectionModel) {
		super.init(driver);

		this.setData(data);
		if (data.keyExists("_id")){
			id = data._id;

			var parts = id.split("/");
			key = parts[2];
			collection = parts[1];
		}
		else if (data.keyExists("_key")) {
			this.setKey(data._key);
		}

		if (data.keyExists("_rev")) rev = data._rev;

		if (!isNull(collectionModel)) {
			collection = collectionModel.getName();
			structDelete(this, "setCollection");
		}

		variables.data.delete("_id");
		variables.data.delete("_key");
		variables.data.delete("_rev");
	}


	public function save() {
		var _data = this.getData() ?: structNew();
		
		structAppend({
			_key: this.getKey() ?: javacast("null","")
		}, _data);

		_data.delete("_id");
		_data.delete("_rev");

		// create
		if (isNull(this.getId())) {
			if (isNull(this.getCollection())){
				cfthrow(message="New documents require a collection to be set.");
			}

			var newDoc = driver.getApi("Document").create(this.getCollection(), _data);

			id = newDoc._id;
			key = newDoc._key;
			rev = newDoc._rev;

			writedump(newDoc);
		} else {
			var update = invoke(driver.getApi("Document"), this.getUpdateMode(), {
				handle: this.getId(), data: _data
			});

			writedump(update);

		}

		abort;
	}

	/**
	 * Put a value into this document.
	 * @key Key name
	 * @value Value
	 **/
	public Document function put(required string key, required any value) {
		if (key != '_id') {
			var putinto = data;
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

}