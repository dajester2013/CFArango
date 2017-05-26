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
	property name="WaitForSync" setter=false;
	property name="IndexBuckets" setter=false;
	property name="Figures" setter=false;
	property name="Status" setter=false;
	property name="Type" setter=false;
	property name="TypeName" setter=false;

	public function init(Driver driver, string name) {
		super.init(driver);

		CollectionApi = driver.getApi("Collection");

		structAppend(variables, CollectionApi.getProperties(name));

		TypeName = Type == CollectionApi.DOCUMENT_COLLECTION ? "Document" : "Edge";

		return this;
	}

	public function newDocument(struct data={}) {
		return type == CollectionApi.DOCUMENT_COLLECTION ? new Document(data, driver, this) : new Edge(data, driver, this);
	}

	/**
	 * Rename this collection
	 * @newName The new name for the collection
	 **/
	public Collection function rename(required string newName) {
		structAppend(variables, CollectionApi.rename(getName(), newName));
		return this;
	}

	/**
	 * Alter the waitForSync flag
	 * @waitForSync Whether Arango should wait until documents are synchronized to disk
	 **/
	public function setWaitForSync(boolean waitForSync) {
		structAppend(variables, CollectionApi.setProperties(getName(), waitForSync, getJournalSize()));
		return this;
	}

	/**
	 * Alter the collection's journal size
	 * @journalSize
	 **/
	public function setJournalSize(number journalSize) {
		structAppend(variables, CollectionApi.setProperties(getName(), getWaitForSync(), journalSize));
		return this;
	}

	/**
	 * Read the checksum of the collection
	 **/
	public numeric function readChecksum() {
		Checksum = CollectionApi.getChecksum(this.getName());
		return Checksum;
	}
	/**
	 * Read the number of documents in this collection
	 **/
	public function readCount() {
		Count = CollectionApi.getCount(this.getName());
		return Count;
	}
	/**
	 * Read the figure information from the collection
	 **/
	public function readFigures() {
		Figures = CollectionApi.getFigures(this.getName());
		return Figures;
	}
	/**
	 * Read the current revision of the collection
	 **/
	public function readRevision() {
		Revision = CollectionApi.getRevision(this.getName());
		return Revision;
	}

	/**
	 * Request Arango to load the collection into memory
	 **/
	public struct function load() {
		return CollectionApi.load(getName());
	}
	/**
	 * Request Arango to unload the collection from memory
	 **/
	public struct function unload() {
		return CollectionApi.unload(getName());
	}

	/**
	 * Rotate the collection's journal
	 **/
	public struct function rotate() {
		return CollectionApi.rotate(getName());
	}

	/**
	 * Delete all documents from the collection
	 **/
	public struct function truncate() {
		return CollectionApi.truncate(getName());
	}

	public struct function getIndexes() {
		return CollectionApi.listIndexes(getName());
	}

	public boolean function dropIndex(required string indexId) {
		return CollectionApi.dropIndex(indexId);
	}

	public boolean function createIndex(required string type, required array fields, minLength) {
		arguments["name"] = getName();
		return CollectionApi.createIndex(argumentCollection=arguments);
	}
}