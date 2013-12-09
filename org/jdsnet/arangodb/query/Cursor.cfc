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
 * Cursor - interface to read data from a statement's execution to a result set
 * 
 * @author jesse.shaffer
 * @date 12/7/13
 **/
component accessors=true output=false persistent=false {
	
	property string Id;
	
	variables.eof=false;
	variables.svc = "";
	variables.curBatch = {};
	
	/**
	 * Constructor
	 * @connection Connection.
	 * @statement The statement that initiated this cursor
	 * @params The params bound to the statement
	 */
	package function init(org.jdsnet.arangodb.model.Database db, AQLStatement statement, struct params) {
		svc = db.getConnection().openService("cursor",db.getName());
		
		readInitial(statement,params);
		
		return this;
	}
	
	/**
	 * Reads the data from the statement into a query object.
	 */
	public query function toQuery() {
		var q = "";
		var cols={};
		
		while(this.hasNext()) {
			var doc = this.next();
			if (!IsStruct(doc))
				throw("Cannot convert to query - expected collection of objects");
			if (!isQuery(q)) {
				q = querynew(structkeylist(doc));
				for (k in doc) cols[k]=true;
			}
			queryAddRow(q);
			for (var k in doc) {
				if(!structKeyExists(cols,k)) {
					cols[k]=true;
					queryaddcolumn(q,k);
				}
				querysetcell(q,k,doc[k],q.recordcount);
			}
		}
		
		return q;
	}
	
	/**
	 * Iterate over all documents, calling @callable for each document.
	 * @callable A function, closure, or object that implements call()
	 */
	public function forEach(required callable) {
		while(this.hasNext()) {
			if (applyToCallback(callable,this.next()) === false) {
				return false;
			}
		}
	}
	
	/**
	 * Iterate over each batch, calling @callable for the batch.
	 * @callable A function, closure, or object that implements call()
	 */
	public function forEachBatch(required callable) {
		if (applyToCallback(callable,curBatch) === false) {
			return false;
		}
		if (curBatch.hasMore) {
			readNextBatch();
			forEachBatch(callable);
		}
	}
	
	/**
	 * Returns whether or not there is another record available.
	 */
	public boolean function hasNext() {
		eof = !eof && !(curBatch.curIdx < curBatch.rCount || curBatch.hasMore);
		return !eof;
	}
	
	/**
	 * Returns the next available document.
	 */
	public any function next() {
		if (eof)
			throw("End of resultset has been reached");
		else if (curBatch.curIdx == curBatch.rCount)
			readNextBatch();
		return curBatch.result[++curBatch.curIdx];
	}
	
	
	
	private function applyToCallback(required cb, required appliedValue) {
		if (IsCustomFunction(cb) || structKeyExists(getMetaData(cb),"closure"))
			cb(appliedValue);
		if (IsObject(cb) && StructKeyExists(cb,"call") && IsCustomFunction(cb.call))
			cb.call(appliedValue);
	}
	
	private function readInitial(AQLStatement stmt, struct params) {
		curBatch = svc.post({
			 "query"		= stmt.getStatement()
			,"batchSize"	= stmt.getBatchSize()
			,"bindVars"		= params
			,"count"		= stmt.getShowCount()
			,"options"		= {
				"fullCount"	= stmt.getShowFullCount()
			}
		});
		curBatch.curIdx=0;
		curBatch.rCount=arraylen(curBatch.result);
		eof=!curBatch.hasMore;
		
		if (structKeyExists(curBatch,"id"))
			this.setId(curBatch.id);
	}
	
	private function readNextBatch() {
		if (eof)
			throw("End of resultset has been reached");
		
		curBatch = svc.put(curBatch.id);
		curBatch.curIdx=0;
		curBatch.rCount=arraylen(curBatch.result);
		eof=!curBatch.hasMore;
	}
	
}