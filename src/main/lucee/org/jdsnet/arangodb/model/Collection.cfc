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
	property name="DoCompact" setter=false;
	property name="IsVolatile" setter=false;
	property name="JournalSize" setter=false;
	property name="KeyOptions" setter=false;
	property name="IndexBuckets" setter=false;
	property name="Status" setter=false;
	property name="Type" setter=false;

	public function init(Driver driver, string name) {
		super.init(driver);

		defineEndpoints({
			"Collection"	: "get,delete@/collection/#name#",
			"Rename"		: "put@/collection/:originalName/rename",
			"Delete"		: "delete@/collection/#name#",

			"Details"		: "get@/collection/#name#/:type",

			"Load"			: "put@/collection/#name#/load",
			"Unload"		: "put@/collection/#name#/unload",

			"Rotate"		: "put@/collection/#name#/rotate",
			"Truncate"		: "put@/collection/#name#/truncate"
		});

		structAppend(variables, endpoints.Details.get({name:name, type:"properties"}).data);

		return this;
	}

	/**
	 * Get collection information
	 **/
	public struct function getInfo() {
		return endpoints.Collection.get().data;
	}

	/**
	 * Rename this collection
	 * @newName The new name for the collection
	 **/
	public Collection function rename(required string newName) {
		result = endpoints.Rename.put({"originalName":getName()}, {"name":newName});

		if (!result.data.error) Name = newName;

		return this;
	}

	/**
	 * Alter the waitForSync flag
	 * @waitForSync Whether Arango should wait until documents are synchronized to disk
	 **/
	public function setWaitForSync(boolean waitForSync) {
		if (!endpoints.Properties.put({waitForSync:arguments.waitForSync}).error) {
			variables.waitForSync = arguments.waitForSync;
		}
		return this;
	}

	/**
	 * Alter the collection's journal size
	 * @journalSize
	 **/
	public function setJournalSize(number journalSize) {
		if (!endpoints.Properties.put({journalSize:arguments.journalSize}).error) {
			variables.journalSize = arguments.journalSize;
		}
		return this;
	}

	/**
	 * Read the checksum of the collection
	 **/
	public function getChecksum() {
		return endpoints.Details.get({type:"checksum"}).data.checksum;
	}
	/**
	 * Read the number of documents in this collection
	 **/
	public function getCount() {
		return endpoints.Details.get({type:"count"}).data.count;
	}
	/**
	 * Read the figure information from the collection
	 **/
	public function getFigures() {
		return endpoints.Details.get({type:"figures"}).data.figures;
	}
	/**
	 * Read the current revision of the collection
	 **/
	public function getRevision() {
		return endpoints.Details.get({type:"revision"}).data.revision;
	}

	/**
	 * Request Arango to load the collection into memory
	 **/
	public struct function load() {
		return endpoints.Load.put().data;
	}
	/**
	 * Request Arango to unload the collection from memory
	 **/
	public struct function unload() {
		return endpoints.Unload.put().data;
	}

	/**
	 * Rotate the collection's journal
	 **/
	public struct function rotate() {
		return endpoints.Rotate.put({name:getName()});
	}

	/**
	 * Delete all documents from the collection
	 **/
	public struct function truncate() {
		return endpoints.Truncate.put({name:getName()}).data;
	}
}