/**
 * Document
 * 
 * @author jesse.shaffer
 * @date 11/30/13
 **/
component accessors=true output=false persistent=false {

	property string id;
	property string key;
	property string rev;
	property Collection collection;
	property struct originalDocument;
	property struct currentDocument;
	
	variables.currentDocument={};
	variables.docService="";
	variables.dirty=true;
	
	public Document function init(struct document={}, Collection collection) {
		if (!isNull(arguments.collection))
			this.setCollection(arguments.collection);
		
		this.setCurrentDocument(duplicate(arguments.document));
		
		if (structKeyExists(arguments.document,"_id")) {
			variables.id = arguments.document._id;
			this.setOriginalDocument(duplicate(arguments.document));
			variables.dirty=false;
		} else {
			this.setOriginalDocument({});
		}
		if (structKeyExists(arguments.document,"_key"))	this.setKey(arguments.document._key);
		if (structKeyExists(arguments.document,"_rev"))	this.setRev(arguments.document._rev);
		
		variables.COL_RES = "?collection="&collection.getName();
		variables.docService = collection.getDatabase().getConnection().openService("document");
		
		return this;
	}
	
	public Document function put(required string key, required any value) {
		if (key != '_id')
			variables.currentDocument[key] = value;
		
		variables.dirty = !structKeyExists(variables.originalDocument,key) || variables.currentDocument[key] != variables.originalDocument[key];
		
		return this;
	}
	
	public any function get(string key="") {
		var rv = variables.currentDocument;
		
		if (len(arguments.key))
			rv = rv[key];
			
		return duplicate(rv);
	}
	
	public Document function save(boolean force=false) {
		if (!force && !dirty) return this;
		
		if (!isNull(this.getId()))
			var res = variables.docService.put(this.getId(),variables.currentDocument);
		else
			var res = variables.docService.post(variables.COL_RES,variables.currentDocument)
		
		structappend(variables.currentDocument,res);
		structappend(variables.originalDocument,res);
		
		for (var k in res)
			variables[k.replace("_","")] = res[k];
		
		dirty=false;
		return this;
	}
	
	public boolean function isDirty() {
		return dirty;
	}
	
	
	public boolean function delete() {
		var res = !variables.docService.delete(this.getId()).error;
		structclear(variables);
		return res;
	}
	
	public function setId() {}
	public function getCurrentDocument() {return this.get();}
	public function getOriginalDocument() {return duplicate(variables.originaldocument);}
	
}