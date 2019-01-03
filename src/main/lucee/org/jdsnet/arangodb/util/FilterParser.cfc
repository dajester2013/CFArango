component {
	/**
	 * Convert a struct of filters into a set of filter statements for AQL
	 * @return Struct containing "stmt" and "params"
	 */
	public struct function parseStruct(required struct filters, required string docStr) {
		var result = {
			 params	= {}
			,stmt	= createObject("java","java.lang.StringBuilder")
		};
		
		if (structCount(filters)) {
			result.stmt.append(" filter ");
			var key		= "";
			var paramNm	= "p";
			var paramId	= 0;
			var first = true;
			for (key in filters) {
				var value = filters[key];
				if (isStruct(value) && value.keyExists("value"))
					value = value.value;
				
				if (isBoolean(value))
					value = !!value;
				else if (isStruct(value) || find(".",key))
					value = [value];
					
				if (first) first=false;
				else result.stmt.append(" && ");
				
				if (isArray(value)) {
					result.stmt.append("MATCHES(#docStr#,[");
					for (var j=1; j<=arraylen(value); j++) {
						if (j > 1) result.stmt.append(",");
						paramNm = "p" & (paramId++);
						
						if (isNull(value[j])) {
							result.stmt.append("{'#key#':null}");
						} else {
							result.params[paramNm] = value[j];
							result.stmt.append("{'#key#':@#paramNm#}");
						}
					}
					result.stmt.append("])");
				} else {
					var param = "p"&(paramId++);
					if(toString(value).matches(".*[%_].*")) {
						// case insensitive like
						result.stmt.append("LIKE(#docStr#.#key#,@").append(param).append(",true)");
					} else {
						result.stmt.append(docStr).append(".").append(key).append(" == @").append(param);
					}
					result.params[param] = value;
				}
				
			}
		}
		
		result.stmt = result.stmt.toString();

		return result;
	}
}