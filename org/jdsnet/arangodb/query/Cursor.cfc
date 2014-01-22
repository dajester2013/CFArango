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

import org.jdsnet.arangodb.model.Database;
import org.jdsnet.arangodb.model.Collection;

/**
 * Cursor - interface to read data from a statement's execution to a result set
 * 
 * @author jesse.shaffer
 * @date 12/7/13
 **/
component accessors=true output=false persistent=false {
	
	property string				Id;
	property AQLStatement		Statement;
	property Struct				Params;
	property Database			Database;
	property IDocumentFactory	DocumentFactory
	property numeric			CurrentCount;
	property numeric			FullCount;
	
	variables.eof=false;
	variables.svc = "";

	/**
	 * Constructor
	 * 
	 */
	public function init(struct batch) {
		if (!isNull(batch) && isStruct(batch)) {
			batch.batchSize					= arraylen(batch.result);
			variables._currentBatch			= batch;
			variables._currentBatch.curIdx	= 0;
			if (!isNull(batch.id)) {
				this.setId(batch.id);
			}
		} else {
			for (var k in arguments) if (!isNull(arguments[k])) {
				if (structKeyExists(this,"set#k#")) {
					this._setter = this["set#k#"];
					this._setter(arguments[k]);
					structDelete(this,"_setter");
				} else {
					variables[k] = arguments[k];
				}
			}
		}
		return this;
	}
	
	public Cursor function setStatement(required AQLStatement Statement) {
		variables.Statement = arguments.Statement;
		variables.Database = arguments.Statement.getDatabase();
		return this;
	}

	public numeric function getCurrentCount() {
		return variables._currentBatch.count;
	}

	/**
	 * Reads the data from the statement into a query object.
	 * @populateQuery An optional query object to populate.
	 */
	public query function toQuery(query populateQuery) {
		var cols={};
		
		while(this.hasNext()) {
			var doc = this.next(false);
			
			if (!IsStruct(doc)) {
				throw("Cannot convert to query - expected collection of objects");
			} else if (isInstanceOf(doc,"Document")) {
				doc = doc.get();
			}

			if (isNull(populateQuery)) {
				populateQuery = querynew(structkeylist(doc));
				for (k in doc) cols[k]=true;
			}

			queryAddRow(populateQuery);
			
			for (var k in doc) {
				if(!structKeyExists(cols,k)) {
					cols[k]=true;
					queryaddcolumn(populateQuery,k);
				}
				querysetcell(populateQuery,k,doc[k],populateQuery.recordcount);
			}
		}
		
		return populateQuery;
	}
	
	public array function toArray() {
		var res = [];
		while(this.hasNext()) {
			arrayappend(res,this.nextBatch(),true);
		}
		return res;
	}
	
	/**
	 * Iterate over all documents, calling @callable for each document.
	 * @callable A function, closure, or object that implements call()
	 */
	public function each(required callable, boolean allowDocumentFetch=true) {
		var idx=0;
		while(this.hasNext()) {
			if (applyToCallback(callable,[this.next(),++idx]) === false) {
				return false;
			}
		}
	}
	
	/**
	 * Iterate over each batch, calling @callable for the batch.
	 * @callable A function, closure, or object that implements call()
	 */
	public function eachBatch(required callable) {
		var idx=0;
		while(this.hasNext()) {
			if (applyToCallback(callable,[this.nextBatch(),++idx]) === false) {
				return false;
			}
		}
	}
	
	/**
	 * Returns whether or not there is another record available.
	 */
	public boolean function hasNext() {
		var curBatch = this.getCurrentBatch();
		eof = eof || !(curBatch.curIdx < curBatch.batchSize || curBatch.hasMore);
		return !eof;
	}
	
	/**
	 * Returns the next available document.
	 */
	public any function next(boolean allowDocumentFetch=true) {
		if (eof) {
			throw("End of resultset has been reached");
		}

		var curBatch = this.getCurrentBatch();
		if (curBatch.curIdx == curBatch.count || curBatch.curIdx == curBatch.batchSize){
			readNextBatch();
			curBatch = this.getCurrentBatch();
		}
		
		var doc = curBatch.result[++curBatch.curIdx];
		
		if (allowDocumentFetch && !isNull(this.getDocumentFactory())) {
			doc =  this.getDocumentFactory().newDocument(doc);
		}
		
		return doc;
	}
	
	/**
	 * Returns the next available resultset.
	 */
	public any function nextBatch() {
		if (eof) {
			throw("End of resultset has been reached");
		}

		var curBatch = this.getCurrentBatch();
		if (curBatch.curIdx == curBatch.count) {
			readNextBatch();
			curBatch = this.getCurrentBatch();
		}
		curBatch.curIdx = curBatch.count;
		return curBatch.result;
	}
	

	public struct function getCurrentBatch() {
		if (isNull(variables._currentBatch)) {
			readInitial();
		}
		return variables._currentBatch;
	}
	
	
	private function applyToCallback(required cb, required args) {
		var _args = args;
		if (isArray(args)) {
			_args=[];
			for (var i=1; i<=arraylen(args); i++) _args[i]=args[i];
		} 

		if (IsCustomFunction(cb) || structKeyExists(getMetaData(cb),"closure")) {
			cb(argumentCollection=_args);
		}
		if (IsObject(cb) && StructKeyExists(cb,"call") && IsCustomFunction(cb.call)) {
			cb.call(argumentCollection=_args);
		}
	}
	


	private function setFullCount(required numeric count) {
		variables.FullCount = count;
	}

	private function getService() {
		if (isNull(variables._cursorService)) {
			variables._cursorService = this.getDatabase().getConnection().openService("cursor",this.getDatabase().getName());
		}
		return variables._cursorService;
	}

	private function readInitial() {
		variables._currentBatch = getService().post({
			 "query"		= this.getStatement().getStatement()
			,"batchSize"	= this.getStatement().getBatchSize()
			,"bindVars"		= this.getParams()
			,"count"		= this.getStatement().getShowCount()
			,"options"		= {
				"fullCount"	= this.getStatement().getShowFullCount()
			}
		});
		variables._currentBatch.curIdx=0;
		variables._currentBatch.batchSize = arraylen(variables._currentBatch.result);
		
		if (structKeyExists(variables._currentBatch,"id")) {
			this.setId(variables._currentBatch.id);
		}

		if (	structKeyExists(variables._currentBatch,"extra")
			&&	structKeyExists(variables._currentBatch.extra,"fullCount")) {
			setFullCount(variables._currentBatch.extra.fullCount);
		} else {
			setFullCount(variables._currentBatch.count);
		}
	}
	
	private function readNextBatch() {
		if (eof) {
			throw("End of resultset has been reached");
		}
		variables._currentBatch				= getService().put(variables._currentBatch.id);
		variables._currentBatch.curIdx		= 0;
		variables._currentBatch.batchSize	= arraylen(variables._currentBatch.result);
	}
	
}