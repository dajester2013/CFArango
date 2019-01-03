component {

	/**
	 * Discovers service meta locations in all available Lucee mappings/custom tag paths.
	 * @returns {Struct[]} array of location information
	 */
	private array function getLuceeMappingLocations() {
		var mappings = [];

		// get the application mappings
		mappings.addAll(getApplicationMetaData().componentPaths);
		mappings.addAll(getApplicationMetaData().customTagPaths);
		// get the named mappings
		mappings.addAll(getPageContext().getConfig().getMappings());
		// and the custom tag mappings
		mappings.addAll(getPageContext().getConfig().getCustomTagMappings());
		// and the component mappings
		mappings.addAll(getPageContext().getConfig().getComponentMappings());
		
		// convert mappings to paths
		return mappings.map(function(mapping) {
			if (isSimpleValue(mapping)) return {
				path: mapping
			};
			
			if (mapping.hasPhysical() || mapping.hasArchive()) {
				var mask = 0;
				
				mask = bitor(mask, mapping.isPhysicalFirst() ? 4 : 0);
				mask = bitor(mask, mapping.hasPhysical() ? 2 : 0);
				mask = bitor(mask, mapping.hasArchive() ? 1 : 0);
				
				var config = {
					componentPrefix : (
						mapping.ignoreVirtual() 
							? ""
							: mapping.getVirtual().replaceAll("^\/","").replaceAll("\/",".")
					)
				};
				
				if (config.componentPrefix.len()) config.componentPrefix &= ".";

				if (mask > 5) {
					config.path = mapping.getPhysical() & "/";
				} else if (mask > 0) {
					config.path = "zip://" & mapping.getArchive() & "!/";
				}

				return config;
			}
		// gather only service locations that actually exist
		}).reduce(function(locations=[], location) {
			if (DirectoryExists(location.path)) {
				locations.add(location);
			}
			return locations;
		});
	}

	/**
	 * Discovers service meta locations in all available Adobe ColdFusion mappings/custom tag paths.
	 */
	private array function getAcfMappingLocations() {
		var locations = [];
		
		// get application settings first
		var appMeta = getApplicationMetadata();

		var mappings = appMeta.mappings ?: structNew();
		for (var m in mappings) {
			locations.add({
				 componentPrefix: m.replaceAll("^\/","").replaceAll("\/",".") & "."
				,path: expandPath(m) & "/"
			});
		}

		var ctp = appMeta.customTagPaths ?: "";
		for (var p in ctp.split(",")) {
			locations.add({
				 componentPrefix=""
				,path: p & "/"
			});
		}

		// get server settings next
		try {
			var rs = CreateObject("java","coldfusion.server.ServiceFactory").getRuntimeService();

			for (var m in rs.getMappings()) {
				locations.add({
					 componentPrefix: m.replaceAll("^\/","").replaceAll("\/",".") & "."
					,path: expandPath(m) & "/"
				});
			}
			for (var p in rs.getCustomtags()) {
				locations.add({
					 componentPrefix=""
					,path: rs.getCustomtags()[p] & "/"
				});
			}
		} catch(any e) {
			// ignore
		}

		return locations.reduce(function(exists=[], location) {
			if(DirectoryExists(location.path)) {
				exists.add(location);
			}
			return exists;
		});
	}


	/**
	 * Scans all available component mappings
	 */
	public array function scanMappings(boolean forceRescan=false) {
		
		if (forceRescan || !variables.keyExists("$mappings")) {
			if (server.keyExists("lucee")) {
				variables.$mappings = getLuceeMappingLocations();
			} else {
				variables.$mappings = getAcfMappingLocations();
			}
		}
		
		return variables.$mappings;

	}
	
	variables.scanCache = {};
	
	public function find(string component, boolean ignoreCache=false) {
		if (ignoreCache || !scanCache.keyExists(component)) {
			scanCache[component] = {};
			
			var mappings = this.scanMappings();
			
			var componentFile = "/" & component.replaceAll("\.","/") & ".cfc";
			var classFile = "/" & component.replaceAll("\.","/") & "_cfc$cf.class";

			var expandedComponentFile = expandPath(componentFile);
			if (fileExists(expandedComponentFile)) {
				scanCache[component].discovered = {
					component:component
					,path:expandedComponentFile
				};
			} else {
				arrayEach(mappings,function(mapping) {
					if (fileExists(mapping.path & componentFile)) {
						scanCache[component].discovered = {
							component: component
							,path: mapping.path & componentFile
						};
					} else if (fileExists(mapping.path & classFile)) {
						scanCache[component].discovered = {
							component: component
							,path: mapping.path & classFile
						};
					}
					return !scanCache[component].keyExists("discovered");
				});
			}
		}
		
		if (scanCache[component].keyExists("discovered"))
			return scanCache[component].discovered;
	}

}