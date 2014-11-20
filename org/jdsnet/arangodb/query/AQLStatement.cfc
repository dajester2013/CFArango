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
 * AQLStatement
 * 
 * @author jesse.shaffer
 * @date 12/7/13
 **/
component accessors=true output=false persistent=false {
	
	property string								Statement;
	property org.jdsnet.arangodb.model.Database	Database;
	property numeric							BatchSize;
	property boolean							ShowCount;
	property boolean							ShowFullCount;
	
	variables.boundParams	= {};
	variables.batchSize		= 0;
	variables.showCount		= true;
	variables.showFullCount	= false;
	
	variables._services		= {};
	
	/**
	 * Execute the statement.
	 * @boundParams A struct of named params to bind to the execution
	 */
	public Cursor function execute(struct boundParams=variables.boundParams) {
		return new Cursor(Statement=this, Params=arguments.boundParams);
	}
	
	/**
	 * Execute the statement as a DML statement (insert/update/remove).
	 * At the moment, DML statements do not appear to support return values, 
	 * so this method only returns true on successful execution, otherwise
	 * an exception will be thrown.
	 * 
	 * @boundParams A struct of named params to bind to the execution
	 **/
	public boolean function executeUpdate(struct boundParams=variables.boundParams) {
		getService("cursor").post({
			 "query"	: this.getStatement()
			,"bindVars"	: arguments.boundParams
		});
		
		return true;
	}
	
	/**
	 * Retrieve the query plan for the current statement.  If the statement uses bound params, you must supply these values also.
	 * @boundParams The params you would use to execute the statement with.
	 **/
	public struct function explain(struct boundParams=variables.boundParams) {
		return getService("explain").post({
			 "query"	: this.getStatement()
			,"bindVars"	: boundParams
		});
	}
	
	/**
	 * Validate the statement's syntax.
	 **/
	public boolean function validate() {
		return getService("query")
			.setErrorHandler(false)
			.post({
				 "query"	: this.getStatement()
			})
			.error;
	}
	
	/**
	 * Bind a named param to a value.
	 * @name Param name
	 * @value Param value
	 */
	public AQLStatement function bind(required string name, any value) {
		boundParams[name] = value;
		return this;
	}

	/**
	 * Execute and return an array immediately from this statement
	 **/
	public array function toArray() {
		return this.execute().toArray();
	}

	/**
	 * Execute and return a query immediately from this statement
	 **/
	public query function toQuery() {
		return this.execute().toQuery();
	}
	
	/**
	 * Execute and return an array immediately from this statement
	 **/
	public array function each(cb) {
		return this.execute().each(cb);
	}

	/**
	 * Execute and return a query immediately from this statement
	 **/
	public query function eachBatch(cb) {
		return this.execute().eachBatch(cb);
	}
	
	/**
	 * Gets the requested service proxy from the current connection
	 **/
	private function getService(required string name) {
		if (isNull(_services[name]))
			_services[name] = this.getDatabase().getConnection().openService(arguments.name,this.getDatabase().getName());
		return _services[name];
	}
	
}