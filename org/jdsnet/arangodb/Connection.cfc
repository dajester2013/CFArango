/**
 * ArangoDB
 * 
 * @author jesse.shaffer
 * @date 11/30/13
 **/
component accessors=true output=false persistent=false {

	property string Protocol default="http";
	property string Host default="localhost";
	property string Port default=8529;
	property string Database default="_system";
	property Credentials Credentials;
	
	variables.serviceCache = {};
	
	this.setCredentials(new BasicCredentials());
	
	public string function getServerVersion() {
		return this.openService("version").get().version;
	}
	
	public ArangoDBRestClient function openService(string resource, string database=this.getDatabase()) {
		return new ArangoDBRestClient(
			 baseUrl = this.getProtocol() & "://" & this.getHost() & ":" & this.getPort() & "/_db/" & arguments.database & "/_api/" & arguments.resource
			,credentials = this.getCredentials()
		);
	}
	
	public array function getUserDatabases() {
		return this.openService("database/user","_system").get().result;
	}
	
	public struct function getDatabaseInfo() {
		return this.openService("database/current").get().result;
	}
	
	public model.Database function openDatabase(required string name) {
		return new model.Database(name=name, connection=this);
	}
	
	public query.AQLStatement function prepareStatement(required string aql) {
		return new query.AQLStatement(aql=aql,connection=this);
	}
	
}