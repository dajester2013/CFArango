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
 * User
 * 
 * @author jesse.shaffer
 * @date 1/17/14
 **/
component accessors=true output=false persistent=false extends=Document {
	
	property Database database;
	property string name;
	property string password;
	property boolean active;
	property boolean exists;
	
	// by default, try using the UPDATE mode
	this.setUpdateMode(this.MODE_UPDATE);
	
	public function init(string name, string password, struct extra={}, Database db) {
		if (!isNull(arguments.db))			this.setDatabase(arguments.db);
		if (!isNull(arguments.name)) {
			this.setId(arguments.name);
			this.setName(arguments.name);
			var result = openService().setErrorHandler(false).get(name);
			
			if (!result.error) {
				this.setExists(!result.error);
				structAppend(extra,result.extra);
			}
		}
		if (!isNull(arguments.password))	this.setPassword(password);
		
		super.init(extra);
		
		return this;
	}
	
	public function setId(required string id, boolean doSetName=true) {
		if (arguments.doSetName)
			this.setName(arguments.id,false);
		variables.id = arguments.id;
	}
	
	public function setName(required string name, boolean doSetId=true) {
		if (arguments.doSetId)
			this.setId(arguments.name,false);
		
		structDelete(variables,"exists");
		
		variables.name = arguments.name;
	}
	
	public boolean function getExists() {
		if (!isNull(this.getName())) {
			if (isNull(variables.exists)) {
				var result = openService().setErrorHandler(false).get(this.getName());
				variables.exists = !result.error;
				if (variables.exists) {
					structAppend(variables.currentDocument,result.extra);
					structAppend(variables.originalDocument,result.extra);
				}
			}
		} else {
			variables.exists = false;
		}
		return variables.exists;
	}
	
	public User function clear(string key) {
		if (!isNull(key)) {
			structDelete(variables.currentDocument,key);
		} else {
			structClear(variables.currentDocument);
		}
		return this;
	}
	
	public function save() {
		if (!this.getExists()) {
			openService().post({
				 "username"	: variables.name
				,"passwd"	: isNull(variables.password) ? "" : variables.password
				,"active"	: this.getActive()
				,"extra"	: this.get()
			});
		} else if (isNull(this.getPassword())) {
			var sReqDoc = {
				 "active"	: this.getActive()
				,"extra"	: this.get()
			};
			
			openService().patch(variables.name,sReqDoc);
		} else {
			var sReqDoc = {
				 "active"	: this.getActive()
				,"extra"	: this.get()
			};
			if (!isNull(this.getPassword())) {
				sReqDoc["passwd"] = this.getPassword
			}
			
			svc = openService();
			svc._updater = openService()[this.getUpdateMode()]
			svc._updater(variables.name,sReqDoc);
		}
		variables.originalDocument = duplicate(variables.currentDocument);
		
		return this;
	}
	
	public function delete() {
		return !openService().setErrorHandler(false).delete(this.getName()).error;
	}
	
	private function getPassword() {}
	
	private function openService() {
		return this.getDatabase().getConnection().openService("user",this.getDatabase().getName());
	}
	
}