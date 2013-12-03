/**
 * Database
 * 
 * @author jesse.shaffer
 * @date 11/30/13
 **/
component accessors=true output=false persistent=false {
	
	property Connection Connection;
	property string Name;
	
	public function init(required Connection connection, required string name) {
		this.setConnection(arguments.connection);
		this.setName(arguments.name);
		
		variables.dbService = this.getConnection().openService("database");
		variables.cService = this.getConnection().openService("collection");
		
		return this;
	}
	
	public function getCollections(string type="user") {
		
		var allCollections = this.getConnection().openService("collection",this.getName()).get();
		
		var retval = allCollections;
		switch(arguments.type) {
			case "user":
				var aclen = arraylen(allCollections.collections);
				for (var i=1; i <= aclen; i++) {
					if (left(allCollections.collections[i].name,1) == "_") {
						structDelete(allCollections.names,allCollections.collections[i].name);
						arrayDeleteAt(allCollections.collections,i);
						i--;
						aclen--;
					}
				}
			break;
			case "sys":
			case "system":
				var aclen = arraylen(allCollections.collections);
				for (var i=1; i <= aclen; i++) {
					if (left(allCollections.collections[i].name,1) != "_") {
						structDelete(allCollections.names,allCollections.collections[i].name);
						arrayDeleteAt(allCollections.collections,i);
						i--;
						aclen--;
					}
				}
			break;
		}
		return retval;
	}
	
	public  function createCollection(required string name, struct options) {
		if (isNull(options)) options={};
		var collection = {
			 "name"			= arguments.name
			,"waitForSync"	= false
			,"doCompact"	= true
		//	,"journalSize"	= << configured in arangod.conf >>
			,"isVolatile"	= false
			,"keyOptions"	= {
				 "type"				= "traditional"
				,"allowUserKeys"	= true
			}
		};
		structAppend(collection,options);
		options["isSystem"]=false;
		options["type"]=2;
		writedump(cService.post(collection));
		
	}
	
	public  function dropCollection(required string name) {
		return cService.delete(name);
	}
	
	public  function getCollection(required string name) {
		return new Collection(name=name, database=this);
	}
	
	public Document function getDocumentById(required string id) {
		var parts = id.split("/");
		return this.getCollection(parts[1]).getDocumentByKey(parts[2]);
	}
	
}