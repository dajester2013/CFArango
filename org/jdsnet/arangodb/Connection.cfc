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
 * ArangoDB Connection
 * 
 * @author jesse.shaffer
 * @date 11/30/13
 **/
component accessors=true output=false persistent=false {

	property string Protocol;
	property string Host;
	property string Port;
	property number State;
	property Credentials Credentials;
	property string Database;
	property boolean CacheServices default=false;
	
	this.setDatabase("_system");
	
	this.UNOPENED	= 0;
	this.OPENED		= 1;
	this.CLOSED		= 2;
	this.ERROR		= 3;
	
	variables.state = this.UNOPENED;
	
	this.setProtocol("http");
	this.setHost("localhost");
	this.setPort(8529);
	
	variables.serviceCache = {};
	
	this.setCredentials(new BasicCredentials());
	
	/**
	 * Open the connection immediately (verifies the connection by reading version information)
	 **/
	public Connection function open() {
		if (this.getState() == this.OPENED) {
			return this;
		} else if (this.getState() > this.CLOSED) {
			invalidState("Cannot open this connection - it is in an error state.");
		}
		
		variables.state = this.OPENED;
		try {
			this.getServerVersion(true);
		} catch(any e) {
			variables.state = this.ERROR;
			throw(object=e);
		}
		
		return this;
	}
	
	/**
	 * Close the connection.
	 **/
	public Connection function close() {
		variables.state = this.CLOSED;
		return this;
	}
	
	/**
	 * Clears out an error state by forcing closed then returning to an UNOPENED state.
	 **/
	public Connection function clearErrorState() {
		this.close();
		variables.state = this.UNOPENED;
		return this;
	}
	
	/**
	 * Returns the current server version
	 * @force Whether or not to force a read from the server.
	 **/
	public string function getServerVersion(boolean force=false) {
		if (isNull(variables.serverVersion) || force)
			variables.serverVersion = this.openService("version").get().version;
		return variables.serverVersion;
	}
	
	/**
	 * Opens a service client for a specific resource/database.  This will automatically open the connection if it is in an UNOPENED state.
	 * @resource The ArangoDB API resource (the url portion following /_api/, ex. "document", or "collection")
	 * @database The specific database to execute the service against, ex. "_system".
	 * @cacheServices Whether or not to create a new service client or not.  Defaults to this.getCacheServices()
	 **/
	public ArangoDBRestClient function openService(string resource, string database=variables.database, boolean cacheServices=this.getCacheServices()) {
		if (this.getState() < this.OPENED) {
			this.open();
		} else if (this.getState() > this.OPENED) {
			invalidState("The connection is not open.");
		}

		var svcKey = resource & "@" & arguments.database;
		var svc = "";

		if (!cacheServices || isNull(serviceCache[svcKey])) {
			svc = new ArangoDBRestClient(
				 baseUrl = this.getProtocol() & "://" & this.getHost() & ":" & this.getPort() & "/_db/" & arguments.database & "/_api/" & arguments.resource
				,credentials = this.getCredentials()
			);

		} else {
			svc = serviceCache[svcKey];
		}

		if (cacheServices && isNull(serviceCache[svcKey])) {
			serviceCache[svcKey] = svc;
		}

		return svc;
	}
	
	/**
	 * Returns a list of databases a user has access to.  This is somewhat tricky when the user does not have access to the _system database.  Therefore, in those situations, you must pass the user's primary database.
	 * @primaryDatabase The name of a database the user has read access to that is their "primary" database.
	 **/
	public array function getUserDatabases(database=variables.database) {
		return this.openService("database/user",database).get().result;
	}

	/**
	 * Returns a database model interface, which is the primary object used to interact with ArangoDB from a client standpoint.
	 * @name The database name
	 **/
	public model.Database function getDatabase(string name=variables.database) {
		return new model.Database(name=name, connection=this);
	}
	
	
	private function setState() {}
	
	private function invalidState(required string detail) {
		throw(type="InvalidStateException",message="Connection is in an invalid state.",detail=detail,errorCode=this.getState());
	}
}