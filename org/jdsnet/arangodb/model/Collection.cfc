/**
 * Collection
 * 
 * @author jesse.shaffer
 * @date 11/30/13
 **/
component accessors=true output=false persistent=false {

	property struct Properties;
	property string Name;
	property Database Database;
	
	public Document function createDocument(struct data={}) {
		return new Document(data,this);
	}
	
	public Document function getDocumentByKey(required string key) {
		return this.createDocument(this.getDatabase().getConnection().openService("document").get("#this.getName()#/#key#"));
	}
	
	public function truncate() {
		this.getDatabase().getConnection().openService("collection").put("#this.getName()#/truncate");
	}
	
	public function getProperties() {
		if (!structKeyExists(variables,"properties"))
			variables.properties = this.getDatabase().getConnection().openService("collection").get("#this.getName()#/properties");
		
		return variables.properties;
	}
	public function setProperties() {}

}