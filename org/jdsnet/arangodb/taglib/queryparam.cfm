<!--- Example usage:
  --- <cfset conn = new Connection()>
  --- <cfset db = conn.getDatabase("_system")>
  --- <cfimport taglib="/org/jdsnet/arangodb/taglib" prefix="adb">
  ---
  --- <adb:query database="#db#" name="result">
  ---    for doc in Collection
  ---    filter doc.key = <adb:queryparam value="simplevalue">
  ---    return doc
  --- </adb:query>
  ---
  --- Alternatively, you can pass the params in the query tag, and use the AQL param placeholders:
  --- <adb:query database="#db#" name="result" params="#{keyfilter: 'simplevalue'}#">
  ---    for doc in Collection
  ---    filter doc.key = @keyfilter
  ---    return doc
  --- </adb:query>
  ---
  --- "result" is, by default, a CFQuery object.  You can can set the "type" attribute of the query tag to cursor, array, or query.
  --- <cfdump var="#result#">
  --->
<cfsilent>
	<cfparam name="attributes.value">
	<cfparam name="attributes.type" 					default="any"	type="string"	><!--- ignored presently --->
	<cfparam name="attributes.list" 					default="false"	type="boolean"	>
	<cfparam name="attributes.delimiters" 				default=","		type="string"	>
	<cfparam name="attributes.includeEmptyFields"		default="false"	type="boolean"	>
	<cfparam name="attributes.multiCharacterDelimiter"	default="false"	type="boolean"	>
</cfsilent>

<cfif thistag.executionMode == "end" or not thistag.hasEndTag>
	<cfsilent>
		<cfset thistag.parent = GetBaseTagData("cf_query").thistag>

		<cfif not structKeyExists(thistag.parent,"$qpCount")>
			<cfset thistag.parent.$qpCount = 0>
		</cfif>
		<cfif attributes.list and not isArray(attributes.value)>
			<cfset attributes.value = listToArray(attributes.value,attributes.delimiters,attributes.includeEmptyFields,attributes.multiCharacterDelimiter)>
		</cfif>

		<cfset thistag.name = "adbqparam#++thistag.parent.$qpCount#">
		<cfset thistag.parent.queryparams[thistag.name] = attributes.value>
	</cfsilent>
	<cfoutput>@#thistag.name#</cfoutput>
</cfif>