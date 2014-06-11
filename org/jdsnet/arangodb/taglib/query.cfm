<cfsilent>
	<cfif not thistag.hasEndTag>
		<cfthrow type="MissingTagException" message="The query tag requires a closing tag.">
	</cfif>

	<cfswitch expression="#thistag.ExecutionMode#">
		<cfcase value="start">
			<!--- connection params --->
			<cfif structKeyExists(attributes,"connection")>
				<cfparam name="attributes.database" type="string">

				<cfset attributes.database = attributes.connection.getDatabase(attributes.database)>
			<cfelseif not structKeyExists(attributes,"database")>
				<cfthrow type="MissingAttribute" message="This tag requires the connection and/or database attributes to be set." detail="If you pass a connection, you must set the database attribute to the database name.  Otherwise, you can just set the database to an instance of the CFArango Database model.">
			</cfif>

			<!--- result params --->
			<cfparam name="attributes.name">
			<cfparam name="attributes.result"		default="">
			<cfparam name="attributes.returnType"	default="query"					type="string">
			<cfparam name="attributes.start"		default="0"						type="numeric">
			<cfparam name="attributes.maxrows"		default="0"						type="numeric">
			<cfparam name="attributes.limit"		default="#attributes.maxrows#"	type="numeric">


			<!--- internal data structures --->
			<cfset thistag.queryparams = {}>
		</cfcase>

		<cfcase value="end">
			<!--- surround with a limit clause if needed --->
			<cfif attributes.start+attributes.limit gt 0>
				<cfset thistag.generatedContent = 'for ADB_RECORD in (#thistag.generatedContent#) limit #attributes.start#,#attributes.limit# return ADB_RECORD'>
			</cfif>

			<!--- execute the query --->
			<cfset thistag.result = attributes.database.prepareStatement(thistag.generatedContent).execute(thistag.queryparams)>

			<!--- send back a cursor or query object, default is a query object --->
			<cfswitch expression="#attributes.returnType#">
				<cfcase value="cursor">
					<cfset caller[attributes.name] = thistag.result>
				</cfcase>

				<cfcase value="array">
					<cfset caller[attributes.name] = thistag.result.toArray()>
				</cfcase>

				<cfcase value="query">
					<cfset caller[attributes.name] = thistag.result.toQuery()>
				</cfcase>
			</cfswitch>

			<!--- supply metadata params back to the caller based on the result attribute --->
			<cfif len(attributes.result)>
				<cfset caller[attributes.result] = {
					 "aql" 			= thistag.generatedContent.replaceAll("([\r\n]+\s+){2,}","")
					,"queryParams"	= thistag.queryParams
				}>
			</cfif>

			<cfset thistag.generatedcontent = "">
		</cfcase>
	</cfswitch>
</cfsilent>