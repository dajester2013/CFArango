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

		CollectionApi = driver.getApi("Collection");
		DatabaseApi = driver.getApi("Database");

		structAppend(variables, DatabaseApi.info());

		return this;
	}

	public Collection function createCollection(required string name, struct options={}) {
		options["name"] = name;
		options["type"] = options.type ?: CollectionApi.DOCUMENT_COLLECTION;

		if (!CollectionApi.create(options).error) {
			if (options.type == CollectionApi.DOCUMENT_COLLECTION)
				return new Collection(driver, name);
			else
				return new EdgeCollection(driver, name);
		}
	}

	public Collection function createEdgeCollection(required string name, struct options={}) {
		options["type"] = 3;
		return this.createCollection(name, options);
	}

	public boolean function dropCollection(required string name) {
		return CollectionApi.drop(name);
	}

	public struct function getCollections(type="user") {
		var collections = driver.getApi("Collection").list();

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
		var info = driver.getApi("Collection").get(name);

		if (!isNull(info))
			if (info.type == CollectionApi.DOCUMENT_COLLECTION)
				return new Collection(driver, name);
			else
				return new EdgeCollection(driver, name);
	}

}