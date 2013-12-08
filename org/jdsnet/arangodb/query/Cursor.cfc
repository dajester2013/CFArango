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
 * Cursor
 * 
 * @author jesse.shaffer
 * @date 12/7/13
 **/
component accessors=true output=false persistent=false {
	
	property string Id;
	
	variables.eof=false;
	variables.svc = "";
	variables.curBatch = {};
	
	package function init(org.jdsnet.arangodb.Connection connection, AQLStatement statement) {
		svc = connection.openService("cursor");
		
		readInitial(statement);
		
		return this;
	}
	
	public query function toQuery() {
		var q = querynew("_id");
		var cols={_id=true};
		
		/*for (var doc in curBatch.result) {
			queryAddRow(q);
			for (var k in doc) {
				if(!structKeyExists(cols,k)) {
					cols[k]=true;
					queryaddcolumn(q,k);
				}
				querysetcell(q,k,doc[k],q.recordcount);
			}
		}
		if (curBatch.hasMore) {
			curBatch = svc.put(curBatch.id);
			this.toQuery(q,cols);
		}*/
		
		while(this.hasNext()) {
			queryAddRow(q);
			var doc = this.next();
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
	
	private function readInitial(AQLStatement stmt) {
		curBatch = svc.post({
			 "query"		= stmt.getStatement()
			,"batchSize"	= stmt.getBatchSize()
			,"bindVars"		= stmt.getBoundParams()
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
		curBatch = svc.put(curBatch.id);
		curBatch.curIdx=0;
		curBatch.rCount=arraylen(curBatch.result);
		eof=!curBatch.hasMore;
	}
	
	public function forEach(required callable) {
		
	}
	
	public function forEachBatch(required callable) {
		
	}
	
	private function applyToCallback(required cb, required args) {
		
	}
	
	public boolean function hasNext() {
		return curBatch.curIdx < curBatch.rCount || curBatch.hasMore;
	}
	
	public any function next() {
		/*if (eof)
			readInitial();
		else*/ if (curBatch.curIdx == curBatch.rCount)
			readNextBatch();
		return curBatch.result[++curBatch.curIdx];
	}
	
}