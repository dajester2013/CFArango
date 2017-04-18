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
			"Collection": "get,delete@/collection/:name",
			"Rename": "put@/collection/:originalName/rename",
			"Delete": "delete@/collection/:name",
			"Checksum": "get@/collection/:name/checksum",
			"Count": "get@/collection/:name/count",
			"Figures": "get@/collection/:name/figures",
			"Properties": "get,put@/collection/:name/properties",
			"Revision": "get@/collection/:name/revision",

			"Load":"put@/collection/:name/load",
			"Unload":"put@/collection/:name/unload",

			"Rotate":"put@/collection/:name/rotate",
			"Truncate":"put@/collection/:name/truncate"
		});

		structAppend(variables, endpoints.Properties.get({name:name}).data);

		return this;
	}

	public struct function getInfo() {
		return endpoints.Collection.get({name: this.getName()}).data;
	}

	public Collection function rename(required string newName) {
		result = endpoints.Rename.put({"originalName":getName()}, {"name":newName});

		if (!result.data.error) Name = newName;

		return this;
	}

	public boolean function drop() {
		return !endpoints.Collection.delete({name:getName()}).error;
	}


	public function setWaitForSync(boolean waitForSync) {
		if (!endpoints.Properties.put({name:getName()}, {waitForSync:arguments.waitForSync}).error) {
			variables.waitForSync = arguments.waitForSync;
		}
		return this;
	}

	public function setJournalSize(number journalSize) {
		if (!endpoints.Properties.put({name:getName()}, {journalSize:arguments.journalSize}).error) {
			variables.journalSize = arguments.journalSize;
		}
		return this;
	}


	public function getChecksum() {
		return endpoints.Checksum.delete({name:getName()}).data.checksum;
	}
	public function getCount() {
		return endpoints.Count.delete({name:getName()}).data.count;
	}
	public function getFigures() {
		return endpoints.Figures.delete({name:getName()}).data.figures;
	}
	public function getRevision() {
		return endpoints.Revision.delete({name:getName()}).data.revision;
	}

	public struct function load() {
		return endpoints.Load.put({name:getName()}).data;
	}
	public struct function unload() {
		return endpoints.Unload.put({name:getName()}).data;
	}


	public struct function rotate() {
		return endpoints.Rotate.put({name:getName()});
	}


	public struct function truncate() {
		return endpoints.Truncate.put({name:getName()}).data;
	}
}