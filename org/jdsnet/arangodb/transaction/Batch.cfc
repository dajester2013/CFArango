/*
 * The MIT License (MIT)
 * Copyright (c) 2013 Jesse Shaffer
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import org.jdsnet.arangodb.model.Document;

/**
 * Batch
 * 
 * @author jesse.shaffer
 * @date 2/17/14
 **/
component extends="Transaction" accessors=true output=false persistent=false {
	
	property Collection Collection;
	property numeric Action;
	
	variables.documents=[];
	variables.documentStatementMap = {}; // index to index map of documents to statements
	
	this.SAVE=1;
	this.DELETE=2;

	this.setAction(this.SAVE);
	this.addStatement("var $batchresults=[];");

	public Batch function add(Document doc, required numeric action=this.getAction()) {
		var collectionName = "";
		if (!isNull(this.getCollection())) {
			collectionName = this.getCollection().getName();
		} else if (!isNull(doc.getCollection())) {
			collectionName = doc.getCollection().getName();
		} else {
			throw(message="No collection specified.",detail="The document must have a collection set, or a default collection may be set on this batch.");
		}

		this.lockCollection(collectionName, this.WRITE);

		var existing = arrayFind(documents,doc);
		if (existing > 0) {
			arrayDeleteAt(documents,existing);
			arrayDeleteAt(statements,documentStatementMap[existing]);
			structDelete(documentStatementMap,existing);
		}

		doc.$applyVars = $applyVars;
		doc.$clearVars = $clearVars;
		
		switch (action) {
			
			case this.SAVE : 
				_addSaveStatement(doc,collectionName);
			break;
			
			case this.DELETE : 
				_addDeleteStatement(doc,collectionName);
			break;
			
		}
		
		return this;
	}
	
	public Batch function addAll(array docs, required numeric action=this.SAVE) {
		for (d in docs) this.add(d,action);
		return this;
	}
	
	/**
	 * Execute the transaction.
	 * @params Execution params
	 * @waitForSync Whether or not to wait for the transaction to be synced to disk on the database.  This is not the same as asynchronous execution.
	 **/
	public Batch function execute(struct params={}, boolean waitForSync) {
		this.addStatement("return $batchresults;");
		
		super.execute(argumentCollection=arguments);

		if (isArray(this.getResult())) {
			for (var res in this.getResult()) {
				var doc = res.document = documents[res.docIdx];
				
				switch(res.action) {
					case this.SAVE : 
						var cur = doc.get();
						structAppend(cur,res.result);
						doc.$applyVars({
							 currentDocument	: cur
							,originalDocument	: cur
							,id					: cur._id
							,key				: cur._key
							,rev				: cur._rev
							,dirty				: false
						});
					break;
					case this.DELETE : 
						doc.$clearVars();
					break;
				}
				
				structDelete(doc,"$applyVars");
				structDelete(doc,"$clearVars");
			}
		}

		return this;
	}
	
	
	private void function _addSaveStatement(Document doc, string collectionName) {
		/* append the document so it can be updated later. the result mapping */
		arrayappend(documents,doc);
		var documentIndex = arraylen(documents);
		
		/* get the raw document info */
		var _doc = doc.get();
		structDelete(_doc,"_id");
		structDelete(_doc,"_rev");
		
		if (!isNull(doc.getId())) {
			/* update existing document (via replace) */
			this.addStatement("$batchresults.push({
				 result : db.#collectionName#.replace(""#doc.getId()#"",#SerializeJSON(_doc)#)
				,docIdx : #documentIndex#
				,action	: #this.SAVE#
			});");
		} else {
			/* insert new document */
			this.addStatement("$batchresults.push({
				 result : db.#collectionName#.save(#SerializeJSON(_doc)#)
				,docIdx : #documentIndex#
				,action	: #this.SAVE#
			});");
		}

		
	}
	
	private void function _addDeleteStatement(Document doc, string collectionName) {
		/* append the document so it can be updated later. the result mapping */
		arrayappend(documents,doc);
		var documentIndex = arraylen(documents);
		
		/* add a statement */
		this.addStatement("$batchresults.push({
			 result : db.#collectionName#.remove(""#doc.getId()#"")
			,docIdx : #documentIndex#
			,action	: #this.DELETE#
		});");
	}


	private function $applyVars(required struct vars) {
		structAppend(variables,vars);
	}
	private function $clearVars() {
		structClear(variables);
	}

}