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

import org.jdsnet.arangodb.Connection;
import org.jdsnet.arangodb.model.Database;

/**
 * Utility to create databases.
 * 
 * @author jesse.shaffer
 * @date 1/17/14
 **/
component accessors=true output=false persistent=false {

	property Connection connection;
	
	public function init(required Connection conn) {
		this.setConnection(conn);
		return this;
	}

	public Database function createDatabase(required string name, string username, string password) {
		var service = this.getConnection().openService("database","_system");
		var reuseConn = false;
		
		if (isNull(username)) {
			username = this.getConnection().getCredentials().getUsername();
			if (isNull(password)) {
				password = this.getConnection().getCredentials().getPassword();
			}
			reuseConn = true;
		} else if (isNull(password)) {
			password = "";
		}
		
		var response = service.post({
			 "name"		: name
			,"users"	: [
				{
					 "username" : username
					,"passwd"	: password
					,"active"	: true
				}
			]
		});
		
		if (response.result == true) {
			if (reuseConn) {
				return this.getConnection().getDatabase(name)
			} else {
				var conn = new Connection()
								.setProtocol(this.getConnection().getProtocol())
								.setHost(this.getConnection().getHost())
								.setPort(this.getConnection().getPort());
								
				conn.getCredentials()
					.setUsername(username)
					.setPassword(password);
				
				return conn.getDatabase(name);
			}
		}
	}
	
	public boolean function dropDatabase(name) {
		return !this.getConnection().openService("database","_system").delete(name).error;
	}
	
}