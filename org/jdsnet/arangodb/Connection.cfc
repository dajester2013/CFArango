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
 * ArangoDB
 * 
 * @author jesse.shaffer
 * @date 11/30/13
 **/
component accessors=true output=false persistent=false {

	property string Protocol default="http";
	property string Host default="localhost";
	property string Port default=8529;
	property string Database default="_system";
	property Credentials Credentials;
	
	variables.serviceCache = {};
	
	this.setCredentials(new BasicCredentials());
	
	public string function getServerVersion() {
		return this.openService("version").get().version;
	}
	
	public ArangoDBRestClient function openService(string resource, string database=this.getDatabase()) {
		return new ArangoDBRestClient(
			 baseUrl = this.getProtocol() & "://" & this.getHost() & ":" & this.getPort() & "/_db/" & arguments.database & "/_api/" & arguments.resource
			,credentials = this.getCredentials()
		);
	}
	
	public array function getUserDatabases() {
		return this.openService("database/user","_system").get().result;
	}
	
	public struct function getDatabaseInfo() {
		return this.openService("database/current").get().result;
	}
	
	public model.Database function openDatabase(required string name) {
		return new model.Database(name=name, connection=this);
	}
	
	public query.AQLStatement function prepareStatement(required string aql) {
		return new query.AQLStatement(aql=aql,connection=this);
	}
	
}