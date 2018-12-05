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
 * Edge
 * 
 * @author jesse.shaffer
 * @date 12/11/13
 **/
component accessors=true output=false persistent=false extends="Document" {

	property any _to;
	property any _from;

	public Edge function init(struct document={}, Collection collection) {
		super.init(argumentCollection=arguments);
		if (structKeyExists(document,"_to")) this.to(document._to);
		if (structKeyExists(document,"_from")) this.from(document._from);
		return this;
	}

	package function setInitiator(Document doc) {
		variables.initiator = doc;
	}

	public function save() {
		if (isNull(this.getCollection())) {
			throw("No collection specified.");
		}
		
		if (isNull(this.get_to()) && isNull(this.get_from())) {
			throw(message="Connections not defined - must call both setTo() and setFrom().");
		} else if (isNull(this.get_to()) && !isNull(this.get_from()) && !isNull(variables.initiator)) {
			this.to(variables.initiator);
		} else if (!isNull(this.get_to()) && isNull(this.get_from()) && !isNull(variables.initiator)) {
			this.from(variables.initiator);
		}
		
		_to = isObject(_to) ? _to.getId() : _to;
		_from = isObject(_from) ? _from.getId() : _from;

		if (isNull(_to)||isNull(_from)) {
			throw(message="Invalid connections defined. Must either be existing saved documents or id's.");
		}

		this.put("_to",_to);
		this.put("_from",_from);

		// cannot update the document - can only 
		if (!isNull(this.getId())) {
			openService("document").delete(this.getId());
		}
		
		var res = openService("edge").post(variables.COL_RES&"&from=#_from#&to=#_to#",variables.currentDocument);
		
		structDelete(res,"error");
		structappend(variables.currentDocument,res);
		structappend(variables.originalDocument,variables.currentDocument);
		
		if (structKeyExists(res,"_id")) {
			variables.id=res._id;
		}
		if (structKeyExists(res,"_key")) {
			this.setKey(res._key);
		}
		if (structKeyExists(res,"_rev")) {
			this.setRev(res._rev);
		}
		
		dirty=false;
		return this;
	}
	
	public function to(_to) {
		variables._to=_to;
		return this;
	}
	public function from(_from) {
		variables._from=_from;
		return this;
	}

	private function set_to() {}
	private function set_from() {}

}