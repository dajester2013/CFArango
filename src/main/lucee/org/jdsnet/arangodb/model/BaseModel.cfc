/*
 * The MIT License (MIT)
 * Copyright (c) 2016 Jesse Shaffer
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

import org.jdsnet.arangodb.Driver;
import org.jdsnet.arangodb.util.EndPoint;

/**
 * Base model
 **/
component accessors=true {
	
	property name="driver"		type="Driver";
	property name="endpoints"	type="struct" setter=false getter=false;
	
	public function init(Driver driver) {
		this.setDriver(driver);
		endpoints = {};
		return this;
	}
	
	
	private function defineEndpoint(name, path) {
		var methods = javacast("null","");
		var pathparts = path.split("@");
		
		if (arrayLen(pathparts) > 1) {
			methods = [pathparts[1]];
			path = pathparts[2]; 
		}
		
		endpoints[name] = new EndPoint(driver, path, methods);
	}
	
	function defineEndpoints(struct endpoints) {
		for (var endpointName in arguments.endpoints) {
			defineEndpoint(endpointName, arguments.endpoints[endpointName]);
		}
	}
	
}