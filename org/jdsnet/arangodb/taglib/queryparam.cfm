<cfsilent>
	<cfparam name="attributes.value">
	<cfparam name="attributes.type" default="any" type="string"><!--- ignored presently --->
	<cfparam name="attributes.list" default="false" type="boolean">
	<cfparam name="attributes.delimiters" default="," type="string">
	<cfparam name="attributes.includeEmptyFields" default="false" type="boolean">
	<cfparam name="attributes.multiCharacterDelimiter" default="false" type="boolean">
</cfsilent>
<cfif thistag.executionMode == "end" or not thistag.hasEndTag>
	<cfsilent>
		<cfif attributes.list and not isArray(attributes.value)>
			<cfset attributes.value = listToArray(attributes.value,attributes.delimiters,attributes.includeEmptyFields,attributes.multiCharacterDelimiter)>
		</cfif>

		<cfset thistag.parent = GetBaseTagData("cf_query").thistag>

		<cfset thistag.name = "adbqparam#structCount(thistag.parent.queryparams)+1#">
		<cfset thistag.parent.queryparams[thistag.name] = attributes.value>
	</cfsilent>
	<cfoutput>@#thistag.name#</cfoutput>
</cfif>