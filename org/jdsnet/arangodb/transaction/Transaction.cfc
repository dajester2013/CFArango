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
 * Transaction - wrapper to the ArangoDB transaction API.
 * 
 * @author jesse.shaffer
 * @date 2/17/14
 **/
component accessors=true output=false persistent=false {

	property Database	Database			;
	property array		Statements			;
	property array		LockedCollections	;
	property any		Result				;
	property boolean 	IsError				default=false;

	this.READ	= new lock.ReadLock();
	this.WRITE	= new lock.WriteLock();

	public Transaction function init(string statement, Database database) {
		this.setStatements([]);
		this.setLockedCollections([]);

		if (!isNull(statement) && len(statement)) this.addStatement(statement);
		if (!isNull(database)) this.setDatabase(database);

		return this;
	}

	/**
	 * Add a statement to the transaction.
	 * @statement A javascript statement to add to this statement
	 **/
	public Transaction function addStatement(required string statement) {
		arrayappend(this.getStatements(),statement);
		return this;
	}

	/**
	 * Add a collection to be locked as part of this transaction.
	 * @collection A collection name or an instance of model.Collection
	 * @type The lock type - can be either Transaction.READ or Transaction.WRITE.
	 **/
	public Transaction function lockCollection(required collection, Lock type=this.READ) {
		if (isObject(collection))
			collection = collection.getName();
		
		arrayappend(this.getLockedCollections(),arguments);
		
		return this;
	}
	
	/**
	 * Assign a rollback handler
	 * @callable A function/closure.
	 **/
	public Transaction function onRollback(callable) {
		if (isCustomFunction(callable) || !isNull(getMetaData(callable).closure)) {
			variables.rollback = callable;
		}
		return this;
	}

	/**
	 * Execute the transaction.
	 * @params Execution params
	 * @waitForSync Whether or not to wait for the transaction to be synced to disk on the database.  This is not the same as asynchronous execution.
	 **/
	public Transaction function execute(struct params={}, boolean waitForSync) {
		var svcRequest = {
			 "collections"={"read":[],"write":[]}
			,"params"=params
		};
		
		if (!isNull(waitForSync)) {
			svcRequest["waitForSync"] = waitForSync;
		}

		for (var lc in this.getLockedCollections()) {
			if (!isNull(svcRequest.collections[lc.type.getType()])) {
				arrayappend(svcRequest.collections[lc.type.getType()],lc.collection);
			}
		}
		
		var _stmts = ArrayToList(this.getStatements(),chr(13));
		svcRequest["action"] = "function(params) {var db = require('internal').db; for (var p in params) this['$'+p] = params[p]; " & chr(13) & _stmts & chr(13) & "}";

		var result = getService().setErrorHandler(false).post(svcRequest);

		if (result.error) {
			rollback(result);
			this.setResult(result);
			variables.IsError = true;
		} else {
			this.setResult(result.result);
		}

		return this;
	}


	private function getService() {
		return this.getDatabase().getConnection().openService("transaction",this.getDatabase().getName());
	}

	private function rollback() {}

	private function setIsError() {}
	
}