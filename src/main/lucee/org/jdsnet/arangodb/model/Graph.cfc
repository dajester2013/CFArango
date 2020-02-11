/**
 * Graph
 *
 * @author jesse.shaffer
 **/
 component	extends		= BaseModel
			accessors	= true
			output		= false
			persistent	= false
{

	property name="Id" setter=false;
	property name="Name" setter=false;
	property name="SmartGraphAttribute" setter=false;
	property name="ReplicationFactor" setter=false;
	property name="OrphanColletions" setter=false;
	property name="Revision" setter=false;
	property name="NumberOfShards" setter=false;
	property name="IsSmart" setter=false;
	property name="EdgeDefinitions" setter=false;

	public function init(Driver driver, string name) {
		super.init(driver);
		variables.api = driver.getApi("Graph");
		
		structAppend(variables, api.get(name));

		Id = _id;
		Revision = _rev;

		return this;
	}

	public function addEdge(required string fromHandle, required string toHandle, string collection, struct data={}) {
		structAppend(data, {
			 "_from": fromHandle
			,"_to": toHandle
		});

		if (isNull(collection)){
			var fromC = fromHandle.replaceAll("\/.*","");
			var toC = toHandle.replaceAll("\/.*","");

			var _edgedef = this.getEdgeDefinitions().filter(function(def) {
				return def.from.find(fromC) && def.to.find(toC);
			});

			if (_edgedef.len()) {
				collection = _edgedef[1].collection;
			} else {
				cfthrow(message="Cannot create an edge between the specified objects in the graph because no valid edge definition could be found.");
			}
		}

		return api.createEdge(Name, collection, data);
	}

	public function modifyEdge(data, collection, merge=false) {
		var handle = "";

		if (data.keyExists("_id")) {
			collection = collection ?: data._id.replaceAll("\/.*$");
			handle = data._id;
		}
		else if (isNull(collection))		cfthrow(message="No collection specified.");
		else if (data.keyExists("_key"))	handle = "#collection#/#data._key#";

		var result = "";

		if (merge)
			result = api.updateEdge(getName(), collection, handle, data);
		else
			result = api.replaceEdge(getName(), collection, handle, data);
		
		return result;
	}

	public function writeVertex(struct data, collection, merge=false) {
		if (isObject(data)) {
			var meta = getMetaData(data);
			collection = meta.collection ?: meta.fullname.listLast(".");
			
			data = deserializeJson(serializeJson(data));
			var props = meta.properties ?: arraynew(1);
			for (var p in props) {
				if (p.keyExists("DocumentKey")) {
					data._key = data[p.name];
					structDelete(data, p.name);
					break;
				}
			}
			
		}
		var handle = "";

		if (data.keyExists("_id")) {
			collection = collection ?: data._id.replaceAll("\/.*$");
			handle = data._id;
		}
		else if (isNull(collection))		cfthrow(message="No collection specified.");
		else if (data.keyExists("_key"))	handle = "#collection#/#data._key#";

		var result = "";

		if (driver.getApi("Document").header(handle).status.code < 300) {
			if (merge)
				result = api.updateVertex(getName(), handle, data);
			else
				result = api.replaceVertex(getName(), handle, data);
		} else {
			result = api.createVertex(getName(), collection, data);
		}

		return result;
	}

	public function traverse(struct traversal={}) {
		traversal["graphName"] = Name;

		return api.traverse(traversal);
	}

	/**
	 * Safely drops an edge
	 */
	public function dropEdge(required string handle) {
		return api.dropEdge(Name, handle);
	}

	/**
	 * Safely drops a vertex and related edges
	 */
	public function dropVertex(required string handle) {
		return api.dropVertex(Name, handle);
	}
}