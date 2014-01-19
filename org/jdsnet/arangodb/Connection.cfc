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

	property string Protocol;
	property string Host;
	property string Port;
	property Credentials Credentials;
	
	this.setProtocol("http");
	this.setHost("localhost");
	this.setPort(8529);
	
	variables.serviceCache = {};
	
	this.setCredentials(new BasicCredentials());
	
	public string function getServerVersion() {
		return this.openService("version").get().version;
	}
	
	public ArangoDBRestClient function openService(string resource, string database="_system") {
		return new ArangoDBRestClient(
			 baseUrl = this.getProtocol() & "://" & this.getHost() & ":" & this.getPort() & "/_db/" & arguments.database & "/_api/" & arguments.resource
			,credentials = this.getCredentials()
		);
	}
	
	public array function getUserDatabases(primaryDatabase="_system") {
		return this.openService("database/user",primaryDatabase).get().result;
	}

	public model.Database function getDatabase(required string name) {
		return new model.Database(name=name, connection=this);
	}
	
}