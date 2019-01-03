/**
 * A JSON parser that has the ability to construct components.
 * 
 * <pre>
 * Examples:
 * 	// Widget.cfc
 * 	component accessors=true {
 * 	    property numeric id;
 * 	    property string name;
 * 	}
 * 
 *  Single instance:
 * 	
 *	 	var jsonData = '{"id":1,"name":"widget a"}';
 *	 	new json.Parser().fromJson(jsonData, "Widget");
 * 
 * 	Array in/out:
 * 
 *	 	var jsonData = '[{"id":1,"name":"widget a"}]';
 *	 	new json.Parser().fromJson(jsonData, "Widget[]"); // returns array of populated widget objects
 * </pre>
 * 	
 */
component {

	

	scanner = new ComponentScanner();

	generateComponent = function(type, args, meta) {
		if (!isNull(args))
			return new "#type#"(argumentCollection=args);

		return new "#type#"();
	};

	componentMetadataLookupStrategy = function(typeName, defaultPackage="") {
		var scanResult = scanner.find(typeName);
		
		if (isNull(scanResult) && defaultPackage.len())
			scanResult = scanner.find(defaultPackage & "." & typeName);

		if (!isNull(scanResult)) {
			return getComponentMetaData(scanResult.component);
		}
	};

	builtInTypes = [
		"any","array","struct","query","numeric","string","date","datetime"
	];


	public function setGenerator(required func) {
		if (isCustomFunction(func) || isClosure(func)) {
			var me = this;
			generateComponent = function() {
				arguments.this = me;
				arguments.componentMetadataLookupStrategy = componentMetadataLookupStrategy;

				return func(argumentCollection=arguments);
			};
		}
	}

	public function setMetadataLookupStrategy(required func) {
		if (isCustomFunction(func) || isClosure(func)) {
			var me = this;
			componentMetadataLookupStrategy = function() {
				arguments.this = me;
				return func(argumentCollection=arguments);
			};
		}
	}

	/**
	 * Parse a JSON string into the specified type
	 *
	 * @deprecated Use parse()
	 * 
	 * @json The JSON data
	 * @type The requested output type - defaults to built-in types.
	 */
	public function fromJson(string json, string type="any") {
		return fromParsed(deserializeJson(json), type);
	}

	/**
	 * Processes raw data, already deserialized, into the requested type.
	 *
	 * @deprecated Use parse()
	 * 
	 * @data String/Array/Struct data to process and produce a result
	 * @type The requested output type - defaults to built-in types
	 */
	public function fromParsed(any data, string type="any") {
		return coerce(data, type);
	}

	/**
	 * Parses data into the specified type.
	 * 
	 * @data JSON/Text/Array/Struct data to parse
	 * @type The requested output type - defaults to built-in types
	 */
	public function parse(any data, string type="any") {
		if (isJson(data)) data = deserializeJson(data);
		return coerce(data, type);
	}

	private function coerce(data, type, instance, prop, defaultPackage="") {
		//writedump(var=arguments,label="coerceargs");
		var _throwCoercionError = function() {
			if (isNull(instance))
				throw(type="DataCoercionException", message="Could not convert data to type #type#.", detail=serializejson(data ?: javaCast("null","")));
			else
				throw(type="DataCoercionException", message="Could not convert data to type #type# for property #getMetaData(instance).fullName#::#prop.name#", detail=serializejson(data ?: javaCast("null","")));
		};
		
		// coerce a typed array
		if (type.endsWith("[]") && isArray(data)) {
			try {
				return data.map(function(dataEl) {
					return coerce(dataEl, type.replaceAll("\[\]$", ""), instance?:javacast("null",""), prop?:javacast("null",""), defaultPackage?:javacast("null",""));
				});
			} catch(DataCoercionException e) {
				_throwCoercionError();
			}
		}

		// coerce single value
		switch(type) {
			case "any":			break;
			case "struct":		if (!isStruct(data))		_throwCoercionError(); break;
			case "array":		if (!isArray(data))			_throwCoercionError(); break;
			case "string":		if (!isSimpleValue(data))	_throwCoercionError(); else data = toString(data); break;
			case "numeric":		if (!isSimpleValue(data))	_throwCoercionError(); else data = val(data); break;
			case "boolean":		if (!isBoolean(data))		_throwCoercionError(); break;
			case "date":		data = parseDate(data); break;
			case "datetime":	data = parseDateTime(data); break;
			case "query":		
				try {
					data = toQuery(data);
				} catch (any e) {
					_throwCoercionError();
				}
			
			default:
				if (!builtInTypes.find(type)) {
					if (isNull(instance))
						data = populate(type, data, defaultPackage);
					else {
						var metadata = getMetaData(instance);
						var instancePackage = metadata.fullName.replaceAll("\.\w+$","");
						
						if (instancePackage == metadata.fullName) instancePackage = defaultPackage;
						
						data = populate(type, data, instancePackage);
					}
				}
		}
		
		if (isNull(data)) {
			_throwCoercionError();
		}
		
		return data;
	}

	private function toQuery(array data) {
		var q = queryNew("");
		var cols = {};
		var i=0;
		for (var row in data) {
			if (!isStruct(row)) throw;
			
			queryAddRow(q);
			i++;
			for (var k in row) {
				if (!cols.keyExists(k)) {
					cols[k]=true;
					queryAddColumn(q,k,[]);
				}
				querySetCell(q, k, i);
			}
		}
		return q;
	}

	private function populate(required type, any data, string package="") {
		//writedump(var=arguments,label="populateargs");
		var typeMeta = "";
		if (isObject(type)) {
			typeMeta = getMetaData(type);
			type = typeMeta.fullName;
		}

		if (type.endsWith("[]") && isArray(data)) {
			var rawType = type.replaceAll("\[\]$","");
			data.map(function(dataEl) {
				if (isStruct(dataEl)) {
					return populate(rawType, dataEl, package);
				}
			});
		} else if (!type.endsWith("\[\]") && isStruct(data)) {
			typeMeta = componentMetadataLookupStrategy(type, package);

			if (isNull(typeMeta)) {
				cfthrow(message="Could not locate type #type# in any known locations (#package#).");
			}
			
			type = scanner.find(type) ?: scanner.find(package &"."& type);
			
			type=type.component;

			var instance = "";
			var explicitConstructor = false;
			if (typeMeta.keyExists("functions")) {
				for (var i=1; i <= arraylen(typeMeta.functions); i++) {
					var f = typeMeta.functions[i];
					if (f.name == "init") {
						explicitConstructor = i;
						break;
					}
				}
			}

			var applyProperties = isNull(typeMeta.properties) ? [] : typeMeta.properties;

			if (explicitConstructor) {
				var conArgs = {};
				var conMeta = typeMeta.functions[explicitConstructor];
				var _applyProperties = [];
				
				if (conMeta.keyExists("parameters")) {
					var args = {};
					for (var p in conMeta.parameters) {
						if (data.keyExists(p.name)) {
							args[p.name] = data[p.name];
							structDelete(data, p.name);
						}
					}
					instance = generateComponent(type, args, typeMeta, data);
					
				} else {
					instance = generateComponent(type, javacast("null",""), typeMeta, data);
				}
			} else {
				
				instance = generateComponent(type, javacast("null",""), typeMeta, data);
				
			}
			
			applyInstanceProperties(instance, applyProperties, data, type.replaceAll("\.\w+$",""));

			return instance;
		}
	}


	private function applyInstanceProperties(instance, properties, data, defaultPackage) {
		//writedump(arguments);
		for (var p in properties) if (data.keyExists(p.name) && structKeyExists(instance, "set#p.name#")) {
			var toType = p.coercedType ?: p.type;
			if (toType == "array" && p.keyExists("populateType")) {
				toType = p.populateType & "[]";
			}
			var value = coerce(data[p.name], toType, instance, p, defaultPackage);
			var args = {"#p.name#":value};
			cfinvoke (component=instance, method="set#p.name#", argumentCollection=args);
		}
	}

}