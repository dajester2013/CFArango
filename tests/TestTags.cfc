/**
 *
 **/
<cfcomponent extends="mxunit.framework.TestCase">

	<cfimport taglib="/cfarango/taglib" prefix="adb">

	<cffunction name="beforeTests">
		<cfset this.conn = new org.jdsnet.arangodb.Connection()
			.setHost("127.0.0.1")
			.setPort(8529)
			.setDatabase("_system")
			>
		<cfset this.conn.open()>
<cftry><cfset aftertests()><cfcatch></cfcatch></cftry>
		<cfset variables.testCollection = this.conn.getDatabase().createCollection("testdata")>

		<cfset assertEquals(this.conn.getState(), this.conn.OPENED, "Expected the connection to be in an OPENED state.")>
	</cffunction>


	<cffunction name="testDataQuery">
		<cfset var rCount = 50>
		<cfloop from="1" to="#rCount#" index="i">
			<cfset variables.testCollection.newDocument({"ts":now(), "rand":randrange(1,10)}).save()>
		</cfloop>

		<cfset assertEquals(rCount, testCollection.queryByExample({}).getFullCount())>

		<adb:query name="queryRes" database="#this.conn.getDatabase()#">
			for d in testdata return d
		</adb:query>
		<cfset assertTrue(isQuery(queryRes), "expected a query result")>
		<cfset assertEquals(rCount, queryRes.recordcount)>

		<adb:query name="arrayRes" returnType="array" database="#this.conn.getDatabase()#">
			for d in testdata return d
		</adb:query>
		<cfset assertTrue(isArray(arrayRes), "expected an array result")>

		<adb:query name="cursorRes" returnType="cursor" database="#this.conn.getDatabase()#">
			for d in testdata return d
		</adb:query>
		<cfset assertTrue(isObject(cursorRes) && isInstanceOf(cursorRes, "org.jdsnet.arangodb.query.Cursor"), "expected a cursor result")>


		<cfset local.top=7>
		<cfset local.bottom=3>
		<adb:query name="queryParamTest" returnType="cursor" database="#this.conn.getDatabase()#">
			for d in testdata
			filter d.rand > <adb:queryparam value="#bottom#"> && d.rand < <adb:queryparam value="#top#">
			return d
		</adb:query>
		<cfset assertTrue(isObject(queryParamTest) && isInstanceOf(queryParamTest, "org.jdsnet.arangodb.query.Cursor"))>
	</cffunction>

	<cffunction name="testDMLQuery">
		<cfset var list = [1,2,3,4,5,6,7,8,9,10]>
		<cfset var listln = arraylen(list)>

		<adb:query name="firstRemoveTest" database="#this.conn.getDatabase()#">
			for d in testdata
			remove d in testdata
		</adb:query>

		<adb:query name="insertTest" returnType="cursor" database="#this.conn.getDatabase()#">
			for i in <adb:queryparam value="#list#">
			insert {_key:concat("dml_insert_",to_string(i)), idx:i} into testdata
		</adb:query>
		<adb:query name="checkInsert" database="#this.conn.getDatabase()#">
			for d in testdata
			return 1
		</adb:query>
		<cfset assertTrue(isQuery(checkInsert), "expected a query result")>
		<cfset assertEquals(checkInsert.recordcount, listln, "expected a resultset with #listln# results")>

		<adb:query name="updateTest" returnType="cursor" database="#this.conn.getDatabase()#">
			for d in testdata
			update d with {wasUpdated:1} in testdata
		</adb:query>
		<adb:query name="checkupdate" database="#this.conn.getDatabase()#">
			for d in testdata
			filter d.wasUpdated == 1
			return 1
		</adb:query>
		<cfset assertEquals(listln, checkupdate.recordcount, "expected a resultset with #listln# results")>

		<adb:query name="lastRemoveTest" returnType="cursor" database="#this.conn.getDatabase()#">
			for d in testdata
			remove d in testdata
		</adb:query>
		<cfset assertEquals(0, testCollection.queryByExample({}).getFullCount(), "expected a zero-length resultset")>
	</cffunction>

	<cffunction name="afterTests">
		<cfset this.conn.getDatabase().getCollection("testdata").drop()>
	</cffunction>

</cfcomponent>