// CyborgDesigner v20260512
// (c) 2026 Cyborg Unicorn Pty Ltd.
// This software is released under MIT License.

// JQuery Usage is minimal and for most part easily mocked by cbElement if you don't want JQuery:
// 	attributes:	attr, data, length, width
// 	binding: 	on
// 	classes:	addClass, hasClass, removeClass
// 	DOM:		[0], this, window
// 	HTML:		html, prepend
// 	selectors:	closest, each, find

function cyborgDesigner(objOptions_a)
{
	var DEBUG = true;
	var DRAG_DATATYPE = 'datatype:';
	var DRAG_NATIVE_DATATYPE = 'nativedatatype:';
	var DRAG_CONTAINER = 'container:';
	var DRAG_EXISTING_CONTAINER = 'existingcontainer:';
	var DRAG_FIELD = 'field:';
	var DRAG_SECTION = 'section:';

    var m_objThis = this;
    var m_objOptions = objOptions_a;
	var m_strCurrentTab = "";
	var m_strPropertyLayout = getGUID('proplayout-');
	var m_intNewIndex = 1; // unique row id for options
    
    if (m_objOptions.target === undefined) { m_objOptions.target = ""; }
    if (m_objOptions.datatypeTarget === undefined) { m_objOptions.datatypeTarget = ""; }
    if (m_objOptions.layoutEditorTarget === undefined) { m_objOptions.layoutEditorTarget = ""; }
	if (m_objOptions.propertyEditorTarget === undefined) { m_objOptions.propertyEditorTarget = ""; }
	if (m_objOptions.layoutPreviewTarget === undefined) { m_objOptions.layoutPreviewTarget = ""; }
	if (m_objOptions.layoutDataTarget === undefined) { m_objOptions.layoutDataTarget = ""; }

    if (m_objOptions.datatypes === undefined) { m_objOptions.datatypes = []; }
    if (m_objOptions.containers === undefined) { m_objOptions.containers = []; }
	if (m_objOptions.nativeDatatypes === undefined) { m_objOptions.nativeDatatypes = []; }
    if (m_objOptions.layoutSections === undefined) { m_objOptions.layoutSections = []; }

    // helpers

	function activateTab(strTabName_a) 
	{
		if (m_objOptions.target.length > 0)
		{
			m_objOptions.cbElement(m_objOptions.target, '.gecd-tabbutton').removeClass('active');
			m_objOptions.cbElement(m_objOptions.target, '.gecd-layouteditor, .gecd-propertyeditor, .gecd-layoutpreview, .gecd-layoutdata').removeClass('active');
			m_objOptions.cbElement(m_objOptions.target, '.gecd-tabbutton[data-tab=' + strTabName_a + ']').addClass('active');
			m_objOptions.cbElement(m_objOptions.target, '.gecd-' + strTabName_a).addClass('active');
			
			m_strCurrentTab = strTabName_a;
		}
	}
	
	function buildDefaultDescription(objField_a) 
	{
		var arrParts = [];
		var objSchema = findSchemaByType(objField_a.type);

		if (objSchema && objSchema.properties) 
		{
			for (var intI = 0; intI < objSchema.properties.length; intI++) 
			{
				var objProp = objSchema.properties[intI];
				if (objProp.showinbuilder && objField_a[objProp.name]) 
				{
					arrParts.push(objProp.label + ': ' + objField_a[objProp.name]);
				}
			}
		}

		return arrParts.join(' | ');
	}

	function createFieldFromDatatype(objDatatype_a) 
	{
		var objField = {
			id: getGUID('field-'),
			type: objDatatype_a.type,
			caption: objDatatype_a.caption,
			container: objDatatype_a.container || false
		};
		
		// Extract default values from properties schema
		if (objDatatype_a.properties) 
		{
			for (var intI = 0; intI < objDatatype_a.properties.length; intI++) 
			{
				var objProp = objDatatype_a.properties[intI];
				if (objProp.value !== undefined) 
				{
					objField[objProp.name] = objProp.value;
				}
			}
		}
		
		return objField;
	}

	function doNothing()
	{
	}
	
	function findSchemaByType(strType_a) 
	{
		var objResult = null;
		var intI;
		
		for (intI = 0; intI < m_objOptions.datatypes.length; intI++) 
		{
			if (m_objOptions.datatypes[intI].type === strType_a) 
			{
				objResult = m_objOptions.datatypes[intI];
				break;
			}
		}
		
		if (objResult === null)
		{
			if (m_objOptions.containers) 
			{
				for (intI = 0; intI < m_objOptions.containers.length; intI++) 
				{
					if (m_objOptions.containers[intI].type === strType_a) 
					{
						objResult = m_objOptions.containers[intI];
						break;
					}
				}
			}
			
			if (objResult === null)
			{
				for (intI = 0; intI < m_objOptions.nativeDatatypes.length; intI++) 
				{
					if (m_objOptions.nativeDatatypes[intI].type === strType_a) 
					{
						objResult = m_objOptions.nativeDatatypes[intI];
						break;
					}
				}
			}
		}
		
		return objResult;
	}

	function isFunction(fn_a)
	{
		var getType = {};
		return fn_a && getType.toString.call(fn_a) === '[object Function]';
	}

	function logConsole()
	{
		if (DEBUG)
		{
			// Convert arguments to array and join them with spaces
			var args = Array.prototype.slice.call(arguments);
			var message = "";
			for (var intI = 0; intI < args.length; intI++) 
			{
				if (intI > 0) message += " ";
				if (typeof args[intI] === 'object') 
				{
					message += JSON.stringify(args[intI]);
				} 
				else 
				{
					message += String(args[intI]);
				}
			}
			console.log(message);
		}
	}	

	function logLayoutStructure() 
	{
		logConsole("=== CURRENT LAYOUT STRUCTURE ===");
		
		for (var intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
		{
			var section = m_objOptions.layoutSections[intI];
			logConsole("SECTION[" + intI + "]: " + section.id + " (" + section.caption + ")");
			
			if (section.containers && section.containers.length > 0) 
			{
				for (var intJ = 0; intJ < section.containers.length; intJ++) 
				{
					var container = section.containers[intJ];
					logConsole("  CONTAINER[" + intJ + "]: " + container.id + " (" + container.type + ")");
					
					if (container.children && container.children.length > 0) 
					{
						for (var intK = 0; intK < container.children.length; intK++) 
						{
							var child = container.children[intK];
							logConsole("    CHILD[" + intK + "]: " + child.id + " (" + child.type + ") - " + (child.caption || "no caption"));
						}
					} 
					else 
					{
						logConsole("    (no children)");
					}
				}
			} 
			else 
			{
				logConsole("  (no containers)");
			}
		}
		
		logConsole("=== END LAYOUT STRUCTURE ===");
	}

	// initialisers
    
	function initDropZones() 
	{
		logConsole("=== Initializing Drop Zones ===");

		// Section-to-section drops (FIRST - highest priority for sections)
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget).on('dragover', '.gecd-layouteditor-section', onDragOver);
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget).on('drop', '.gecd-layouteditor-section', onDrop_Section);
		logConsole("Bound section drop handlers");

		// Field-to-field drops (SECOND - highest priority for fields)
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget).on('dragover', '.gecd-layouteditor-field', onDragOver);
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget).on('drop', '.gecd-layouteditor-field', onDrop_Field);
		logConsole("Bound field drop handlers");

		// Container content for fields (THIRD priority)
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget).on('dragover', '.gecd-vertical-content', onDragOver);
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget).on('drop', '.gecd-vertical-content', onDrop_Container);

		m_objOptions.cbElement(m_objOptions.layoutEditorTarget).on('dragover', '.gecd-horizontal-content', onDragOver);
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget).on('drop', '.gecd-horizontal-content', onDrop_Container);
		logConsole("Bound container content drop handlers");

		// Specific header handlers
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget).on('dragover', '.gecd-horizontal-header', onDragOver);
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget).on('drop', '.gecd-horizontal-header', onDrop_ContainerHeader);
		
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget).on('dragover', '.gecd-vertical-header', onDragOver);
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget).on('drop', '.gecd-vertical-header', onDrop_ContainerHeader);
		
		// Section content for fields and containers (FOURTH priority)
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget).on('dragover', '.gecd-section-content', onDragOver);
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget).on('drop', '.gecd-section-content', onDrop_SectionContent);
		logConsole("Bound section content drop handlers");

		// Layout area for sections (LOWEST priority)
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget).on('dragover', onDragOver_Layout);
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget).on('drop', onDrop_Layout);
		logConsole("Bound layout drop handlers");

		logConsole("=== Drop Zones Initialized ===");
	}

    function initialise()
    {
		initialiseTargets();
		initialiseTabs();
        renderDatatypes();
        renderLayout();
        initDropZones();
    }
	
	function initialiseTabs()
	{
		if (m_objOptions.target.length > 0)
		{
			// Default: show layout editor tab below 1920px
			if (m_objOptions.cbElement(window).width() <= 1920) 
			{
				activateTab('layouteditor');
			}
			
			m_objOptions.cbElement(m_objOptions.target, '.gecd-tabbutton').on('click', function() 
			{
				activateTab(m_objOptions.cbElement(this).data('tab'));
			});
			
			m_objOptions.cbElement(window).on('resize', function() 
			{
				activateTab(m_strCurrentTab);
			});
		}
	}
	
	function initialiseTargets()
	{
		var strHTML = "";
		
		if (m_objOptions.target.length > 0)
		{
			strHTML = '<div class="gscd-container">' +
				'<div class="gecd-datatypes gscd-datatypes"></div>' +
				'<div class="gscd-tabs">' +
					'<div class="gecd-tabbar gscd-tabbar">' +
						'<button class="gecd-tabbutton gscd-tabbutton" data-tab="layouteditor">Layout</button>' +
						'<button class="gecd-tabbutton gscd-tabbutton" data-tab="propertyeditor">Properties</button>';
						if (m_objOptions.cbPreviewRenderer)
						{
							strHTML += '<button class="gecd-tabbutton gscd-tabbutton" data-tab="layoutpreview">Preview</button>';
						}
						if (m_objOptions.cbDataRenderer)
						{
							strHTML += '<button class="gecd-tabbutton gscd-tabbutton" data-tab="layoutdata">Data</button>';
						}
					strHTML += '</div>' +
					'<div class="gecd-layouteditor gscd-layouteditor"></div>' +
					'<div class="gecd-propertyeditor gscd-propertyeditor">Property Editor</div>' +
					'<div class="gecd-layoutpreview gscd-layoutpreview">Layout Preview</div>' +
					'<div class="gecd-layoutdata gscd-layoutdata">Layout Data</div>' +
				'</div>' +
				'</div>';
				
			m_objOptions.cbElement(m_objOptions.target).html(strHTML);
		}

		if (m_objOptions.datatypeTarget.length === 0) { m_objOptions.datatypeTarget = m_objOptions.target + " .gecd-datatypes"; }
		if (m_objOptions.layoutEditorTarget.length === 0) { m_objOptions.layoutEditorTarget = m_objOptions.target + " .gecd-layouteditor"; }
		if (m_objOptions.propertyEditorTarget.length === 0) { m_objOptions.propertyEditorTarget = m_objOptions.target + " .gecd-propertyeditor"; }
		if (m_objOptions.layoutPreviewTarget.length === 0) { m_objOptions.layoutPreviewTarget = m_objOptions.target + " .gecd-layoutpreview"; }
		if (m_objOptions.layoutDataTarget.length === 0) { m_objOptions.layoutDataTarget = m_objOptions.target + " .gecd-layoutdata"; }
	}
	
	// privates

	function findContainerByID(strContainerID_a) 
	{
		var objResult = null;
		
		for (var intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
		{
			var objSection = m_objOptions.layoutSections[intI];
			
			if (objSection.containers) 
			{
				for (var intJ = 0; intJ < objSection.containers.length; intJ++) 
				{
					var objFound = findContainerRecursive(objSection.containers[intJ], strContainerID_a);
					if (objFound) 
					{
						objResult = objFound;
						break;
					}
				}
				
				if (objResult) 
				{
					break;
				}
			}
		}
		
		return objResult;
	}

	function findContainerRecursive(objContainer_a, strContainerID_a) 
	{
		var objResult = null;
		
		if (objContainer_a.id === strContainerID_a) 
		{
			objResult = objContainer_a;
		} 
		else if (objContainer_a.children) 
		{
			for (var intI = 0; intI < objContainer_a.children.length; intI++) 
			{
				if (objContainer_a.children[intI].type === 'verticalcontainer' || objContainer_a.children[intI].type === 'horizontalcontainer') 
				{
					var objFound = findContainerRecursive(objContainer_a.children[intI], strContainerID_a);
					if (objFound) 
					{
						objResult = objFound;
						break;
					}
				}
			}
		}
		
		return objResult;
	}

	function findFieldParentRecursive(objContainer_a, strFieldID_a) 
	{
		var intI;
		var objResult = null;
		
		if (objContainer_a.children) 
		{
			// Check if field is direct child
			for (intI = 0; intI < objContainer_a.children.length; intI++) 
			{
				if (objContainer_a.children[intI].id === strFieldID_a) 
				{
					objResult = objContainer_a; // This container is the parent
					break;
				}
			}
			
			// Check nested containers if not found as direct child
			if (!objResult) 
			{
				for (intI = 0; intI < objContainer_a.children.length; intI++) 
				{
					if (objContainer_a.children[intI].type === 'verticalcontainer' || objContainer_a.children[intI].type === 'horizontalcontainer') 
					{
						var objParent = findFieldParentRecursive(objContainer_a.children[intI], strFieldID_a);
						if (objParent) 
						{
							objResult = objParent;
							break;
						}
					}
				}
			}
		}
		
		return objResult;
	}

	function findParentContainerOfField(strFieldID_a) 
	{
		var objResult = null;
		
		for (var intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
		{
			var objSection = m_objOptions.layoutSections[intI];
			
			if (objSection.containers) 
			{
				for (var intJ = 0; intJ < objSection.containers.length; intJ++) 
				{
					var objContainer = findFieldParentRecursive(objSection.containers[intJ], strFieldID_a);
					if (objContainer) 
					{
						objResult = objContainer;
						break;
					}
				}
				
				if (objResult) 
				{
					break;
				}
			}
		}
		
		return objResult;
	}

	function findParentOfContainer(strContainerID_a) 
	{
		var intJ;
		var objResult = null;
		
		// Check layout sections
		for (var intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
		{
			var objSection = m_objOptions.layoutSections[intI];
			
			// Check if container is direct child of section
			if (objSection.containers) 
			{
				for (intJ = 0; intJ < objSection.containers.length; intJ++) 
				{
					if (objSection.containers[intJ].id === strContainerID_a) 
					{
						objResult = objSection; // Return section as parent
						break;
					}
				}
				
				// Check if container is child of horizontal container in section
				if (!objResult) 
				{
					for (intJ = 0; intJ < objSection.containers.length; intJ++) 
					{
						if (objSection.containers[intJ].type === 'horizontalcontainer') 
						{
							if (objSection.containers[intJ].children) 
							{
								for (var intK = 0; intK < objSection.containers[intJ].children.length; intK++) 
								{
									if (objSection.containers[intJ].children[intK].id === strContainerID_a) 
									{
										objResult = objSection.containers[intJ]; // Return horizontal container as parent
										break;
									}
								}
								
								if (objResult) 
								{
									break;
								}
							}
						}
					}
				}
			}
			
			if (objResult) 
			{
				break;
			}
		}
		
		return objResult;
	}

	function findSectionByID(strSectionID_a) 
	{
		var objResult = null;
		
		for (var intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
		{
			if (m_objOptions.layoutSections[intI].id === strSectionID_a) 
			{
				objResult = m_objOptions.layoutSections[intI];
				break;
			}
		}
		
		return objResult;
	}

	function getContainerPropertiesByDragData(strDragData_a) 
	{
		var objResult = null;
		
		for (var intI = 0; intI < m_objOptions.containers.length; intI++) 
		{
			if ("container:" + m_objOptions.containers[intI].type === strDragData_a) 
			{
				objResult = m_objOptions.containers[intI];
				break;
			}
		}
		
		return objResult;
	}

	function getDatatypePropertiesByDragData(strDragData_a) 
	{
		var objResult = null;
		
		for (var intI = 0; intI < m_objOptions.datatypes.length; intI++) 
		{
			if ("datatype:" + m_objOptions.datatypes[intI].type === strDragData_a) 
			{
				objResult = m_objOptions.datatypes[intI];
				break;
			}
		}
		
		return objResult;
	}

	function getNativeDatatypePropertiesByDragData(strDragData_a) 
	{
		var objResult = null;
		
		for (var intI = 0; intI < m_objOptions.nativeDatatypes.length; intI++) 
		{
			if ("nativedatatype:" + m_objOptions.nativeDatatypes[intI].type === strDragData_a) 
			{
				objResult = m_objOptions.nativeDatatypes[intI];
				break;
			}
		}
		
		return objResult;
	}

	function insertContainerAtPosition(objSource_a, objTarget_a, objParent_a) 
	{
		logConsole("=== insertContainerAtPosition called ===");
		logLayoutStructure();
		
		var intI;
		var arrContainers;
		var intSourceIndex = -1;
		var intTargetIndex;

		if (objParent_a.containers !== undefined) 
		{
			arrContainers = objParent_a.containers;
			logConsole("Using parent.containers, length:", arrContainers.length);
		} 
		else if (objParent_a.children !== undefined) 
		{
			arrContainers = objParent_a.children;
			logConsole("Using parent.children, length:", arrContainers.length);
		}
		else 
		{
			logConsole("ERROR: Parent has neither containers nor children!");
			return;
		}
		
		// Find source index BEFORE removing it
		for (intI = 0; intI < arrContainers.length; intI++) 
		{
			if (arrContainers[intI].id === objSource_a.id) 
			{
				intSourceIndex = intI;
				break;
			}
		}
		
		// Find target index BEFORE removing source
		intTargetIndex = -1;
		for (intI = 0; intI < arrContainers.length; intI++) 
		{
			if (arrContainers[intI].id === objTarget_a.id) 
			{
				intTargetIndex = intI;
				break;
			}
		}
		
		logConsole("Source index:", intSourceIndex);
		logConsole("Target index:", intTargetIndex);
		
		// Remove the source from the parent if present
		if (intSourceIndex !== -1) 
		{
			arrContainers.splice(intSourceIndex, 1);
			logConsole("Removed source from index:", intSourceIndex);
			
			// Adjust target index if source was removed before target
			if (intSourceIndex < intTargetIndex) 
			{
				intTargetIndex--;
				logConsole("Adjusted target index to:", intTargetIndex);
			}
		}

		if (intTargetIndex !== -1) 
		{
			arrContainers.splice(intTargetIndex, 0, objSource_a);
			logConsole("Inserted source at index:", intTargetIndex);
		} 
		else 
		{
			arrContainers.push(objSource_a);
			logConsole("Appended source to end");
		}
		
		logLayoutStructure(); // Log AFTER
		logConsole("=== insertContainerAtPosition complete ===");
	}

	function insertSectionAtPosition(objSource_a, objTarget_a) 
	{
		logConsole("=== insertSectionAtPosition called ===");
		logConsole("Source section:", objSource_a.id, objSource_a.caption);
		logConsole("Target section:", objTarget_a.id, objTarget_a.caption);
		logConsole("Total sections:", m_objOptions.layoutSections.length);
		
		var intI;
		var intSourceIndex = -1;
		var intTargetIndex = -1;
		
		// Log current order
		logConsole("Current section order:");
		for (intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
		{
			logConsole("  [" + intI + "]:", m_objOptions.layoutSections[intI].id, m_objOptions.layoutSections[intI].caption);
		}
		
		// Find source index BEFORE removing it
		for (intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
		{
			if (m_objOptions.layoutSections[intI].id === objSource_a.id) 
			{
				intSourceIndex = intI;
				break;
			}
		}
		
		// Find the index of the target section BEFORE removing source
		for (intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
		{
			if (m_objOptions.layoutSections[intI].id === objTarget_a.id) 
			{
				intTargetIndex = intI;
				break;
			}
		}
		
		logConsole("Source index:", intSourceIndex);
		logConsole("Target index:", intTargetIndex);
		
		// Remove source first
		if (intSourceIndex !== -1) 
		{
			m_objOptions.layoutSections.splice(intSourceIndex, 1);
			logConsole("Removed source from index:", intSourceIndex);
			
			// Adjust target index if source was removed before target
			if (intSourceIndex < intTargetIndex) 
			{
				intTargetIndex--;
				logConsole("Adjusted target index to:", intTargetIndex);
			}
		}
		
		if (intTargetIndex !== -1) 
		{
			// Insert the source section BEFORE the target (at target's index)
			m_objOptions.layoutSections.splice(intTargetIndex, 0, objSource_a);
			logConsole("Inserted source at index:", intTargetIndex);
		} 
		else 
		{
			// Fallback: add to end
			m_objOptions.layoutSections.push(objSource_a);
			logConsole("Appended source to end");
		}
		
		// Log final order
		logConsole("Final section order:");
		for (intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
		{
			logConsole("  [" + intI + "]:", m_objOptions.layoutSections[intI].id, m_objOptions.layoutSections[intI].caption);
		}
		logConsole("=== insertSectionAtPosition complete ===");
	}

	function removeContainerFromAnywhere(strContainerID_a) 
	{
		var objResult = null;
		
		for (var intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
		{
			if (m_objOptions.layoutSections[intI].containers) 
			{
				for (var intJ = 0; intJ < m_objOptions.layoutSections[intI].containers.length; intJ++) 
				{
					if (m_objOptions.layoutSections[intI].containers[intJ].id === strContainerID_a) 
					{
						objResult = m_objOptions.layoutSections[intI].containers.splice(intJ, 1)[0];
						break;
					} 
					else 
					{
						var objContainer = removeContainerRecursiveAndReturn(m_objOptions.layoutSections[intI].containers[intJ], strContainerID_a);
						if (objContainer) 
						{
							objResult = objContainer;
							break;
						}
					}
				}
				
				if (objResult) 
				{
					break;
				}
			}
		}
		
		return objResult;
	}

	function removeContainerRecursiveAndReturn(objContainer_a, strContainerID_a) 
	{
		var objResult = null;
		
		if (objContainer_a.children) 
		{
			for (var intI = 0; intI < objContainer_a.children.length; intI++) 
			{
				if (objContainer_a.children[intI].id === strContainerID_a) 
				{
					objResult = objContainer_a.children.splice(intI, 1)[0];
					break;
				} 
				else if (objContainer_a.children[intI].type === 'verticalcontainer' || objContainer_a.children[intI].type === 'horizontalcontainer') 
				{
					var objContainer = removeContainerRecursiveAndReturn(objContainer_a.children[intI], strContainerID_a);
					if (objContainer) 
					{
						objResult = objContainer;
						break;
					}
				}
			}
		}
		
		return objResult;
	}

	function removeFieldFromAnywhere(strFieldID_a) 
	{
		var intJ;
		var objResult = null;
		
		logConsole("removeFieldFromAnywhere called with:", strFieldID_a);
		logConsole("Total layout sections:", m_objOptions.layoutSections.length);
		
		try 
		{
			// Check section fields
			for (var intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
			{
				logConsole("Starting loop iteration", intI);
				logConsole("Section", intI, "object:", m_objOptions.layoutSections[intI]);
				
				if (m_objOptions.layoutSections[intI]) 
				{
					var strCount;
					if (m_objOptions.layoutSections[intI].fields)
					{
						strCount = m_objOptions.layoutSections[intI].fields.length;
					}
					else
					{
						strCount = "fields property missing";
					}
					logConsole("Checking section", intI, "fields - count:", strCount);
					
					if (m_objOptions.layoutSections[intI].fields) 
					{
						for (intJ = 0; intJ < m_objOptions.layoutSections[intI].fields.length; intJ++) 
						{
							if (m_objOptions.layoutSections[intI].fields[intJ].id === strFieldID_a) 
							{
								logConsole("Found field in section fields, removing");
								objResult = m_objOptions.layoutSections[intI].fields.splice(intJ, 1)[0];
								break;
							}
						}
					}
					
					// Check container fields recursively if not found in section fields
					if (!objResult) 
					{
						logConsole("About to check containers for section", intI);
						
						if (m_objOptions.layoutSections[intI].containers) 
						{
							logConsole("Section", intI, "has", m_objOptions.layoutSections[intI].containers.length, "containers");
							
							for (intJ = 0; intJ < m_objOptions.layoutSections[intI].containers.length; intJ++) 
							{
								logConsole("Calling removeFieldFromContainer on container", intJ, "with id:", m_objOptions.layoutSections[intI].containers[intJ].id);
								var objField = removeFieldFromContainer(m_objOptions.layoutSections[intI].containers[intJ], strFieldID_a);
								if (objField) 
								{
									logConsole("Found field in container, returning:", objField);
									objResult = objField;
									break;
								}
							}
						} 
						else 
						{
							logConsole("Section", intI, "has no containers property");
						}
					}
				} 
				else 
				{
					logConsole("Section", intI, "is null or undefined, skipping");
				}
				
				if (objResult) 
				{
					break;
				}
				
				logConsole("Finished checking section", intI);
			}
		} 
		catch (error) 
		{
			logConsole("Error in removeFieldFromAnywhere:", error);
		}
		
		if (!objResult) 
		{
			logConsole("Field not found, returning null");
		}
		
		return objResult;
	}

	function removeFieldFromContainer(objContainer_a, strFieldID_a) 
	{
		var objResult = null;
		
		logConsole("removeFieldFromContainer called, container type:", objContainer_a.type, "looking for:", strFieldID_a);
		
		if (objContainer_a.children) 
		{
			logConsole("Container has", objContainer_a.children.length, "children");
			
			for (var intI = 0; intI < objContainer_a.children.length; intI++) 
			{
				logConsole("Checking child", intI, "id:", objContainer_a.children[intI].id);
				
				if (objContainer_a.children[intI].id === strFieldID_a) 
				{
					logConsole("Found matching field, removing from position", intI);
					
					objResult = objContainer_a.children.splice(intI, 1)[0];
					break;
				} 
				else if (objContainer_a.children[intI].type === 'verticalcontainer' || objContainer_a.children[intI].type === 'horizontalcontainer') 
				{
					logConsole("Child is container, recursing");
					
					var objField = removeFieldFromContainer(objContainer_a.children[intI], strFieldID_a);
					if (objField) 
					{
						objResult = objField;
						break;
					}
				}
			}
		} 
		else 
		{
			logConsole("Container has no children");
		}
		
		return objResult;
	}

	function renderContainer(objContainer_a)
	{
		var intI;
		var objChild;
		var strContainerHtml = '';

		if (objContainer_a.type === 'horizontalcontainer') 
		{
			strContainerHtml = '<div class="gecd-horizontal-container gscd-horizontal-container" draggable="true" data-container-id="' + objContainer_a.id + '">' +
								'<div class="gecd-horizontal-header gscd-container-header">' +
								'<span>' + objContainer_a.caption + '</span>' +
								'<span class="gecd-remove-btn gscd-remove-btn" data-container-id="' + objContainer_a.id + '">×</span>' +
								'</div>' +
								'<div class="gecd-horizontal-content gscd-horizontal-content">';

			// Only render vertical containers (no direct fields in horizontal containers)
			var childCount = 0;
			for (intI = 0; intI < objContainer_a.children.length; intI++) 
			{
				objChild = objContainer_a.children[intI];
				if (objChild.type === 'verticalcontainer') 
				{
					strContainerHtml += renderContainer(objChild);
					childCount++;
				}
			}
			
			if (objContainer_a.children.length > 0)
			{
				// MESSAGE: "Drop containers here to add at the right"
				strContainerHtml += '<div class="gecd-horizontal-dropzone" style="min-width:120px; color:#888; text-align:center; padding:12px 0;" draggable="false">' +
									'Drop<br>vertical<br>containers<br>here<br>to add<br>at the<br>right' +
									'</div>';

				strContainerHtml += '</div></div>';
			}
			else
			{
				// MESSAGE: "Drop containers here to add at the right"
				strContainerHtml += '<div class="gecd-horizontal-dropzone" style="min-width:120px; color:#888; text-align:center; padding:12px 0;" draggable="false">' +
									'Drop vertical containers here' +
									'</div>';

				strContainerHtml += '</div></div>';
			}
		} 
		else if (objContainer_a.type === 'verticalcontainer') 
		{
			strContainerHtml = '<div class="gecd-vertical-container gscd-vertical-container" draggable="true" data-container-id="' + objContainer_a.id + '">' +
								'<div class="gecd-vertical-header gscd-container-header">' +
								'<span>' + objContainer_a.caption + '</span>' +
								'<span class="gecd-remove-btn gscd-remove-btn" data-container-id="' + objContainer_a.id + '">×</span>' +
								'</div>' +
								'<div class="gecd-vertical-content gscd-vertical-content">';

			// Only render fields (vertical containers only contain fields)
			for (intI = 0; intI < objContainer_a.children.length; intI++) 
			{
				objChild = objContainer_a.children[intI];
				if (objChild.type !== 'verticalcontainer' && objChild.type !== 'horizontalcontainer') 
				{
					strContainerHtml += '<div class="gecd-layouteditor-field gscd-layouteditor-field" draggable="true" data-field-id="' + objChild.id + '">' +
										'<span>' + objChild.caption + '</span>' +
										'<span style="font-size:0.85em; color:#666;">' + buildDefaultDescription(objChild) + '</span>' +
										'<span class="gecd-field-actions">' +
											'<span class="gecd-copy-btn gscd-copy-btn" data-field-id="' + objChild.id + '">⧉</span>' +
											'<span class="gecd-remove-btn gscd-remove-btn" data-field-id="' + objChild.id + '">×</span>' +
										'</span>' +
										'</div>';
				}
			}
			
			if ((m_objOptions.datatypes.length > 0) || (m_objOptions.nativeDatatypes.length > 0))
			{
				if (objContainer_a.children.length > 0)
				{
					// MESSAGE: "Drop fields here to add at the end"
					strContainerHtml += '<div class="gecd-vertical-dropzone" style="color:#888; text-align:center; padding:8px 0;" draggable="false">' +
										'Drop fields here to add at the end' +
										'</div>';
				}
				else
				{
					// MESSAGE: "Drop fields here"
					strContainerHtml += '<div class="gecd-vertical-dropzone" style="color:#888; text-align:center; padding:8px 0;" draggable="false">' +
										'Drop fields here' +
										'</div>';
				}
			}

			strContainerHtml += '</div></div>';
		}
		
		return strContainerHtml;
	}

	function renderDatatypes()
	{
		var intI;
		var strList = "";
		
		if (m_objOptions.datatypes.length > 0)
		{
			// Add Datatypes heading
			strList += '<div class="gecd-section-heading gscd-section-heading">Datatypes</div>';
			strList += '<div class="gecd-collapsible gbcd-collapsible">';
			
			// Render datatypes
			for (intI = 0; intI < m_objOptions.datatypes.length; intI++) 
			{
				var objOption = m_objOptions.datatypes[intI];
				var strOption = '';
				if (objOption.type === '--')
				{
					strOption = '<div class="gecd-datatype gscd-category">' + objOption.caption + '</div>';
					strList += strOption;
				}
				else
				{
					strOption = '<div class="gecd-datatype gscd-datatype" draggable="true" data-datatype-type="' + objOption.type + '">' + objOption.caption + '</div>';
					strList += strOption;
				}
			}
			
			strList += "</div>";
		}
		
		if (m_objOptions.containers.length > 0)
		{
			// Add Containers heading
			strList += '<div class="gecd-section-heading gscd-section-heading">Containers & Sections</div>';
			strList += '<div class="gecd-collapsible gbcd-collapsible">';
			
			// Render containers
			for (intI = 0; intI < m_objOptions.containers.length; intI++) 
			{
				var objContainer = m_objOptions.containers[intI];
				var strContainer = '';
				if (objContainer.type === '--')
				{
					strContainer = '<div class="gecd-containertype gscd-category">' + objContainer.caption + '</div>';
				}
				else
				{
					strContainer = '<div class="gecd-containertype gscd-containertype" draggable="true" data-container-type="' + objContainer.type + '">' + objContainer.caption + '</div>';
				}
				strList += strContainer;
			}

			strList += "</div>";
		}
		
		if (m_objOptions.allowNativeDatatypes && m_objOptions.nativeDatatypes.length > 0)
		{
			// Add Native Datatypes heading
			strList += '<div class="gecd-section-heading gscd-section-heading">Native Datatypes</div>';
			strList += '<div class="gecd-collapsible gbcd-collapsible">';
			
			// Render native datatypes
			for (intI = 0; intI < m_objOptions.nativeDatatypes.length; intI++) 
			{
				var objNativeOption = m_objOptions.nativeDatatypes[intI];
				var strNativeOption = '';
				if (objNativeOption.type === '--')
				{
					strNativeOption = '<div class="gecd-datatype gscd-category">' + objNativeOption.caption + '</div>';
				}
				else if (objNativeOption.type === 'nativelistoption')
				{
					doNothing();
				}
				else
				{
					strNativeOption = '<div class="gecd-datatype gscd-datatype" draggable="true" data-native-datatype-type="' + objNativeOption.type + '">' + objNativeOption.caption + '</div>';
				}
				strList += strNativeOption;
			}

			strList += "</div>";
		}
		
		m_objOptions.cbElement(m_objOptions.datatypeTarget).html(strList);
		
		// bindings
		m_objOptions.cbElement(m_objOptions.datatypeTarget, '.gecd-datatype').on('dragstart', onDragStart_Datatype);
		m_objOptions.cbElement(m_objOptions.datatypeTarget, '.gecd-containertype').on('dragstart', onDragStart_Container);
	}

	function renderLayout()
	{
		var strLayoutHtml = "";

		for (var intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
		{
			var objSection = m_objOptions.layoutSections[intI];
			var strSectionHtml = '<div class="gecd-layouteditor-section gscd-layouteditor-section" draggable="true" data-section-id="' + objSection.id + '">' +
									'<div class="gecd-section-header gscd-section-header">' +
									'<span>' + objSection.caption + '</span>' +
									'<span class="gecd-remove-btn gscd-remove-btn" data-section-id="' + objSection.id + '">×</span>' +
									'</div>' +
									'<div class="gecd-section-content gscd-section-content">';

			// Only render containers (no direct fields in sections)
			for (var intJ = 0; intJ < objSection.containers.length; intJ++) 
			{
				var objContainer = objSection.containers[intJ];
				strSectionHtml += renderContainer(objContainer);
			}
			
			if (objSection.containers.length > 0)
			{
				// MESSAGE: "Drop containers here to add at the end" (at the end of the section)
				strSectionHtml += '<div class="gecd-section-dropzone" style="color:#888; text-align:center; padding:12px 0; border:1px dashed #bbb; background:#fbfbfb; margin:12px 0 0 0;" draggable="false">' +
									'Drop containers here to add at the end' +
									'</div>';

				strSectionHtml += '</div></div>';
			}
			else
			{
				// MESSAGE: "Drop containers here" (on the section)
				strSectionHtml += '<div class="gecd-section-dropzone" style="color:#888; text-align:center; padding:12px 0; border:1px dashed #bbb; background:#fbfbfb; margin:12px 0 0 0;" draggable="false">' +
									'Drop containers here' +
									'</div>';

				strSectionHtml += '</div></div>';
			}
			strLayoutHtml += strSectionHtml;
		}

		if (m_objOptions.layoutSections.length > 0)
		{
			// If there is at least one section, or even if there are none, always offer to add a new layout section at the end:
			strLayoutHtml += '<div class="gecd-layouteditor-dropzone" style="color:#888; text-align:center; padding:18px 0; border:2px dashed #333; background:#f2f2f2; font-weight:bold; font-size:17px;">' +
							'Drop layout sections here to add at the end' +
							'</div>';
		}
		else
		{
			// If there is at least one section, or even if there are none, always offer to add a new layout section at the end:
			strLayoutHtml += '<div class="gecd-layouteditor-dropzone" style="color:#888; text-align:center; padding:18px 0; border:2px dashed #333; background:#f2f2f2; font-weight:bold; font-size:17px;">' +
							'Drop layout sections here' +
							'</div>';
		}

		m_objOptions.cbElement(m_objOptions.layoutEditorTarget).html(strLayoutHtml);

		// Add drag bindings
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget, '.gecd-layouteditor-field').on('dragstart', onDragStart_Field);
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget, '.gecd-layouteditor-section').on('dragstart', onDragStart_LayoutSection);
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget, '.gecd-horizontal-container, .gecd-vertical-container').on('dragstart', onDragStart_Container);

		// Add remove button bindings
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget, '.gecd-remove-btn').on('click', onClick_Remove);
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget, '.gecd-copy-btn').on('click', onClick_CopyField);

		// Click bindings
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget, '.gecd-vertical-header, .gecd-horizontal-header').on('click', onClick_ContainerHeader);
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget, '.gecd-section-header').on('click', onClick_SectionHeader);
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget, '.gecd-layouteditor-field').on('click', onClick_Field);
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget).on('click', onClick_Layout);

		// Double-Clicks
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget, '.gecd-vertical-header, .gecd-horizontal-header').on('dblclick', onDblClick_ContainerHeader);
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget, '.gecd-section-header').on('dblclick', onDblClick_SectionHeader);
		m_objOptions.cbElement(m_objOptions.layoutEditorTarget, '.gecd-layouteditor-field').on('dblclick', onDblClick_Field);
		
		renderPreview();
		renderLayoutData();
	}

	function renderLayoutData() 
	{
		var objRaw = m_objOptions.layoutSections;
		
		if (isFunction(m_objOptions.cbTransformer))
		{
			objRaw = m_objOptions.cbTransformer(objRaw);
		}
		
		if (isFunction(m_objOptions.cbDataRenderer))
		{
			m_objOptions.cbDataRenderer(objRaw);
		}
	}

	function renderPreview() 
	{
		var objRaw = m_objOptions.layoutSections;
		
		if (isFunction(m_objOptions.cbTransformer))
		{
			objRaw = m_objOptions.cbTransformer(objRaw);
		}
		
		if (isFunction(m_objOptions.cbPreviewRenderer))
		{
			m_objOptions.cbPreviewRenderer(objRaw);
		}
	}

	function renderProperties(strSectionID_a, strContainerID_a, strFieldID_a) 
	{
		var blnChecked;
		var intI;
		var objProp;
		var objSchema = null;
		var objSelected = null;
		var strHTML;
		var strInputHtml;
		var strPropName;
		var varValue;
		
		// Locate selected object and schema
		function findFieldByID(strFieldID_a) 
		{
			var objResult = null;
			var objContainer;
			var objField;
			var objSection;
			
			for (var intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
			{
				objSection = m_objOptions.layoutSections[intI];
				if (objSection.containers) 
				{
					for (var intJ = 0; intJ < objSection.containers.length; intJ++) 
					{
						objContainer = objSection.containers[intJ];
						if (objContainer.children) 
						{
							for (var intK = 0; intK < objContainer.children.length; intK++) 
							{
								objField = objContainer.children[intK];
								if (objField.type === 'verticalcontainer')
								{
									var objContainer2 = objField;
									if (objContainer2.children) 
									{
										for (var intL = 0; intL < objContainer2.children.length; intL++) 
										{
											var objField2 = objContainer2.children[intL];
											if (objField2.id === strFieldID_a) 
											{
												objResult = objField2;
												break;
											}
										}
									}
								}
								else if (objField.id === strFieldID_a) 
								{
									objResult = objField;
									break;
								}
							}
						}
						
						if (objResult !== null)
						{
							break;
						}
					}
				}
						
				if (objResult !== null)
				{
					break;
				}
			}
			
			return objResult;
		}

		function findContainerByID_Flat(strContainerID_a) 
		{
			var objResult = null;
			var objContainer;
			var objSection;
			
			for (var intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
			{
				objSection = m_objOptions.layoutSections[intI];
				if (objSection.containers) 
				{
					for (var intJ = 0; intJ < objSection.containers.length; intJ++) 
					{
						objContainer = objSection.containers[intJ];
						if (objContainer.id === strContainerID_a) 
						{
							objResult = objContainer;
							break;
						}
					}
				}
				
				if (objResult !== null)
				{
					break;
				}
			}
			
			return objResult;
		}

		function findSectionByID(strSectionID_a) 
		{
			var objResult = null;
			var objSection;
			
			for (var intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
			{
				objSection = m_objOptions.layoutSections[intI];
				if (objSection.id === strSectionID_a) 
				{	
					objResult = objSection;
					break;
				}
			}
			return objResult;
		}

		function renderMetaProperty(strType_a, strPropertyName_a, strLabel_a, strValue_a, blnEditable_a)
		{
			var strMetaHtml = '';
			var strSafeValue = strValue_a || '';
			var strType = strType_a || 'text';

			strMetaHtml += '<div class="mb-3">';
			strMetaHtml += '<label class="form-label" for="gecd-meta-' + strPropertyName_a + '">' + strLabel_a + '</label>';

			if (blnEditable_a)
			{
				if (strType === 'checkbox')
				{
					var blnChecked = toBoolean(strSafeValue);
					strMetaHtml += '<div class="form-check">';
					strMetaHtml += '<input type="checkbox" class="form-check-input gecd-meta-' + strPropertyName_a + '" data-prop-name="' + strPropertyName_a + '"' + (blnChecked ? ' checked' : '') + '>';
					strMetaHtml += '<label class="form-check-label">Yes / No</label>';
					strMetaHtml += '</div>';
				}
				else
				{
					strMetaHtml += '<input type="text" class="form-control gecd-meta-' + strPropertyName_a + '" data-prop-name="' + strPropertyName_a + '" value="' + strSafeValue + '">';
				}
			}
			else
			{
				strMetaHtml += '<input type="text" class="gscd-readonly form-control gecd-meta-' + strPropertyName_a + '" value="' + strSafeValue + '" readonly>';
			}

			strMetaHtml += '</div>';

			return strMetaHtml;
		}
		
		// note: the heirarchical option is flattened for the form and we need to unflatten it 
		// 		 upon submit, so we are putting the datatype in front followed by propertyname, then index
		function renderOption(objSelected_a, objProp_a, strDataType_a, blnMulti_a)
		{
			var intI;
			var strPropName;
			var strResult = '';
			var objProp;
			var objSchema = findSchemaByType(strDataType_a);
			var varValue;
			var varValues = [[],[],[]];
			
			if (objSchema) 
			{
				if (blnMulti_a)
				{
					strResult += '<div class="gecd-options" data-datatype="' + strDataType_a + '" data-propname="' + objProp_a.name + '">';
						strResult += '<div class="mb-2"><strong>' + objProp_a.label + '</strong></div>';
						strResult += '<div class="option-rows">';
				}
				
				strResult += '<table class="table table-sm">';
				
				// Header row
				strResult += '<thead><tr>';
				for (intI = 0; intI < objSchema.properties.length; intI++) 
				{
					objProp = objSchema.properties[intI];
					strResult += '<th>' + objProp.label + '</th>';
				}
				if (blnMulti_a) 
				{
					strResult += '<th width="40"></th>'; // Column for - button
				}
				strResult += '</tr></thead>';
				
				strResult += '<tbody>';
				
				if (blnMulti_a)
				{
					// get array data for cells
					for (intI = 0; intI < objSchema.properties.length; intI++) 
					{
						objProp = objSchema.properties[intI];
						if (objProp.name === objProp_a.name)
						{
							strPropName = objProp_a.name;
						}
						else
						{
							strPropName = objProp_a.name + '-' + objProp.name;
						}
						
						varValue = objSelected_a[strPropName];
						if (varValue === undefined) 
						{
							varValues[intI][0] = '';
						}
						else
						{
							varValues[intI] = varValue;
						}
					}
					
					if (varValues[0].length === 0)
					{
						varValues = [[''],[''],['']];
					}

					// populate the table
					for (intI = 0; intI < varValues[0].length; intI++) 
					{
						if (intI === 0)
						{
							strResult += '<tr>';
							for (intJ = 0; intJ < objSchema.properties.length; intJ++) 
							{
								varValue = varValues[intJ][intI];
								objProp = objSchema.properties[intJ];
								strPropName = strDataType_a + '-' + m_intNewIndex + '-' + objProp_a.name + '-' + objProp.name;
								
								strResult += '<td><input type="text" class="form-control form-control-sm gecd-prop-' + strPropName + '" data-prop-name="' + strPropName + '" value="' + varValue + '"></td>';
							}
							//strResult += '<td><button type="button" class="btn btn-sm btn-danger">−</button></td>';
							strResult += '<td></td>'; // No - button on first row
							strResult += '</tr>';
							m_intNewIndex++;
						}
						else
						{
							strResult += '<tr>';
							for (intJ = 0; intJ < objSchema.properties.length; intJ++) 
							{
								varValue = varValues[intJ][intI];
								objProp = objSchema.properties[intJ];
								strPropName = strDataType_a + '-' + m_intNewIndex + '-' + objProp_a.name + '-' + objProp.name;
								
								strResult += '<td><input type="text" class="form-control form-control-sm gecd-prop-' + strPropName + '" data-prop-name="' + strPropName + '" value="' + varValue + '"></td>';
							}
							strResult += '<td><button type="button" class="btn btn-sm btn-danger">−</button></td>';
							//strResult += '<td></td>'; // No - button on first row
							strResult += '</tr>';
							m_intNewIndex++;
						}
					}

					// Empty row with + button (only if multi)
					strResult += '<tr class="add-row">';
						for (intI = 0; intI < objSchema.properties.length; intI++) 
						{
							strResult += '<td></td>'; // Empty cells
						}
						strResult += '<td><button type="button" class="btn btn-sm btn-success">+</button></td>';
					strResult += '</tr>';
				}
				else
				{
					strResult += '<tr>';
					for (intI = 0; intI < objSchema.properties.length; intI++) 
					{
						objProp = objSchema.properties[intI];
						if (objProp.name === objProp_a.name)
						{
							strPropName = objProp_a.name;
						}
						else
						{
							strPropName = objProp_a.name + '-' + objProp.name;
						}
						
						varValue = objSelected_a[strPropName];
						if (varValue === undefined) { varValue = ''; }
						
						strPropName = strDataType_a + '--' + objProp_a.name + '-' + objProp.name;
						strResult += '<td><input type="text" class="form-control form-control-sm gecd-prop-' + strPropName + '" data-prop-name="' + strPropName + '" value="' + varValue + '"></td>';
					}
					strResult += '</tr>';
				}
				
				strResult += '</tbody></table>';
				
				if (blnMulti_a)
				{
						strResult += '</div>'; // Close option-rows
					strResult += '</div>'; // Close container
				}
			} 
			
			return strResult;
		}

		function bindOptionEvents() 
		{
			m_objOptions.cbElement('#' + m_strPropertyLayout, '.gecd-options .btn-success').off('click');
			m_objOptions.cbElement('#' + m_strPropertyLayout, '.gecd-options .btn-danger').off('click');
			
			// Bind add button - scoped to this property layout
			m_objOptions.cbElement('#' + m_strPropertyLayout, '.gecd-options .btn-success').on('click', function() 
			{
				var objElement = m_objOptions.cbElement(this).closest('.gecd-options');
				addOptionRow(objElement);
			});
			
			// Bind remove buttons - scoped to this property layout  
			m_objOptions.cbElement('#' + m_strPropertyLayout, '.gecd-options .btn-danger').on('click', function() 
			{
				removeOptionRow(this);
			});
		}

		function addOptionRow(objElement_a) 
		{
			var strDataType = objElement_a.attr('data-datatype');
			var strPropName = objElement_a.attr('data-propname');
			
			var objTable = objElement_a.find('table tbody');
			var objAddRow = objTable.find('.add-row');
			var arrDataRows = objTable.find('tr:not(.add-row)');
			
			// Get the schema to rebuild the row structure
			var objSchema = findSchemaByType(strDataType);
			if (objSchema)
			{
				var strNewRow = '<tr>';
				
				// Add input fields
				for (var intI = 0; intI < objSchema.properties.length; intI++) 
				{
					var objProp = objSchema.properties[intI];
					var strFullPropName = strDataType + '-' + m_intNewIndex + '-' + strPropName + '-' + objProp.name;
					strNewRow += '<td><input type="text" class="form-control form-control-sm gecd-prop-' + strFullPropName + '" data-prop-name="' + strFullPropName + '" value=""></td>';
				}
				m_intNewIndex++;
				
				// Add - button
				strNewRow += '<td><button type="button" class="btn btn-sm btn-danger">−</button></td>';
				strNewRow += '</tr>';
				
				// Insert before the add row
				objAddRow.before(strNewRow);
				
				// Re-bind events for the new button within this specific property layout
				bindOptionEvents();
			}
		}

		function removeOptionRow(objElement_a) 
		{
			var objRow = m_objOptions.cbElement(objElement_a).closest('tr');
			objRow.remove();
		}

		if (strFieldID_a) 
		{
			objSelected = findFieldByID(strFieldID_a);
			if (objSelected)
			{
				objSchema = findSchemaByType(objSelected.type);
			}
		} 
		else if (strContainerID_a) 
		{
			objSelected = findContainerByID(strContainerID_a);
			if (objSelected)
			{
				objSchema = findSchemaByType(objSelected.type);
			}
		} 
		else if (strSectionID_a) 
		{
			objSelected = findSectionByID(strSectionID_a);
			objSchema = { properties: [] };
		}

		if (!objSelected) 
		{
			m_objOptions.cbElement(m_objOptions.propertyEditorTarget).html("<div class='alert alert-danger'>No object selected.</div>");
		}
		else
		{
			strHTML = '<form class="p-2" id="' + m_strPropertyLayout + '">';

			// Render meta-properties first
			var strSelectedID = objSelected.id || '';
			strHTML += renderMetaProperty('textbox', 'id', 'ID', strSelectedID, false);
			
			var strSelectedType = objSelected.type || '';
			strHTML += renderMetaProperty('textbox', 'type', 'Type', strSelectedType, false);
			
			var strSelectedCaption = objSelected.caption || '';
			strHTML += renderMetaProperty('textbox', 'caption', 'Caption', strSelectedCaption, true);

			var blnSelectedVisible = toBoolean(objSelected.visible);
			strHTML += renderMetaProperty('checkbox', 'visible', 'Visible', blnSelectedVisible, true);
			
			// if (objSelected.container !== undefined)
			// {
				// var strContainerValue = objSelected.container ? 'Yes' : 'No';
				// strHTML += renderMetaProperty('textbox', 'container', 'Container', strContainerValue, false);
			// }

			// Add separator if we have both meta-properties and schema properties
			if (objSchema && objSchema.properties && objSchema.properties.length > 0)
			{
				strHTML += '<hr class="my-3">';
			}

			// Render schema-defined properties
			if (objSchema && objSchema.properties)
			{
				for (intI = 0; intI < objSchema.properties.length; intI++) 
				{
					objProp = objSchema.properties[intI];
					strPropName = objProp.name;
					// Skip meta-properties if they appear in schema (avoid duplication)
					if (strPropName === 'id' || strPropName === 'type' || strPropName === 'caption' || strPropName === 'container')
					{
						continue;
					}
					
					varValue = '';
					if (objSelected[strPropName] !== undefined && objSelected[strPropName] !== null) 
					{
						varValue = objSelected[strPropName];
					}
					strInputHtml = '';

					if (objProp.datatype === 'nativetextbox') 
					{
						strInputHtml = '<input type="text" class="form-control gecd-prop-' + strPropName + '" data-prop-name="' + strPropName + '" value="' + varValue + '">';
					} 
					else if (objProp.datatype === 'nativemultilinetextbox') 
					{
						var intRows = objProp.lines | 0;
						intRows = parseInt(intRows, 10);
						if (intRows > 0)
						{
							strInputHtml = '<textarea class="form-control gecd-prop-' + strPropName + '" data-prop-name="' + strPropName + '" rows="' + intRows + '">' + varValue + '</textarea>';
						}
						else
						{
							strInputHtml = '<textarea class="form-control gecd-prop-' + strPropName + '" data-prop-name="' + strPropName + '">' + varValue + '</textarea>';
						}
					} 
					else if (objProp.datatype === 'nativeyesno') 
					{
						blnChecked = toBoolean(varValue);
						strInputHtml = '<div class="form-check">' +
									  '<input type="checkbox" class="form-check-input gecd-prop-' + strPropName + '" data-prop-name="' + strPropName + '"';
						if (blnChecked) 
						{
							strInputHtml += ' checked';
						}
						strInputHtml += '>' +
									  '<label class="form-check-label" for="gecd-prop-' + strPropName + '">Yes / No</label>' +
									  '</div>';
					} 
					else if (objProp.datatype === 'nativelistoption') 
					{
						m_intNewIndex = 0;
						strInputHtml = renderOption(objSelected, objProp, objProp.datatype, false);
					}
					else if (Array.isArray(objProp.datatype)) 
					{
						m_intNewIndex = 0;
						strInputHtml = '<div>';
						for (intJ = 0; intJ < objProp.datatype.length; intJ++) 
						{
							strInputHtml += renderOption(objSelected, objProp, objProp.datatype[intJ], true);
						}
						strInputHtml += '</div>';
					} 
					else 
					{
						// catch all
						strInputHtml = '<input type="text" class="form-control gecd-prop-' + strPropName + '" data-prop-name="' + strPropName + '" value="' + varValue + '">';
					}

					strHTML += '<div class="mb-3">' +
							  '<label class="form-label" for="gecd-prop-' + strPropName + '">' + objProp.label + '</label>' +
							  strInputHtml +
							  '</div>';
				}
			}

			strHTML += '<div class="cecd-savecancel"><div class="mb-3 d-flex" style="gap:10px;">' +
					  '<button class="gecd-btn-save btn btn-primary" type="submit">Save Properties</button>' +
					  '<button class="gecd-btn-cancel btn btn-secondary" type="button">Cancel</button>' +
					  '</div></div></form>';

			m_objOptions.cbElement(m_objOptions.propertyEditorTarget).html(strHTML);
			bindOptionEvents();

			m_objOptions.cbElement('#' + m_strPropertyLayout).on('submit', function(objEvent_a) 
			{
				objEvent_a.preventDefault();
				m_objOptions.cbElement(this).find('[data-prop-name]').each(function() 
				{
					var strN = m_objOptions.cbElement(this).attr('data-prop-name');
					var objEl = m_objOptions.cbElement(this);

					if (objEl.attr('type') === "checkbox") 
					{
						if (this.checked) 
						{
							objSelected[strN] = true;
						} 
						else 
						{
							objSelected[strN] = false;
						}
					} 
					else 
					{
						varValue = objEl.val();
						var arrElement = strN.split('-');
						if (Array.isArray(arrElement) && arrElement[0] && arrElement[0] === 'nativelistoption')
						{
							var arrOption;
							if (arrElement[2] === arrElement[3])
							{
								strN = arrElement[2];
							}
							else
							{
								strN = arrElement[2] + '-' + arrElement[3];
							}

							if (arrElement[1] === '')
							{
								// we are unflattening to an object
								objSelected[strN] = varValue;
							}
							else
							{
								var intIndex = parseInt(arrElement[1], 10);
								
								// we are unflattening to an array
								if (intIndex === 0)
								{
									objSelected[strN] = [];
								}

								try
								{
									if (DEBUG)
									{
										console.log("try: " + intIndex + ":" + strN + ":" + JSON.stringify(varValue));
									}
									objSelected[strN].push(varValue);
								}
								catch(err)
								{
									if (DEBUG)
									{
										console.log("failed: " + intIndex + ":" + strN + ":" + JSON.stringify(varValue));
									}
								}
							}
						}
						else
						{
							objSelected[strN] = varValue;
						}
					}
				});
				
				m_objOptions.cbElement(m_objOptions.propertyEditorTarget, '.cecd-savecancel').prepend('<div class="alert alert-success mb-3">Properties saved.</div>');
				renderLayout();
				
				setTimeout(function()
				{
					m_objOptions.cbElement(m_objOptions.propertyEditorTarget).find('.alert-success').remove();
				}, 1300);
			});

			m_objOptions.cbElement('.gecd-btn-cancel').on('click', function(objEvent_a)
			{
				objEvent_a.preventDefault();
				renderProperties(strSectionID_a, strContainerID_a, strFieldID_a);
			});
		}
	}
   
    // event handler helpers

	function onClick_CopyField(objEvent_a)
	{
		objEvent_a.preventDefault();
		objEvent_a.stopPropagation();

		var strFieldID = m_objOptions.cbElement(this).attr('data-field-id');
		if (!strFieldID) { return; }

		var objParent = findParentContainerOfField(strFieldID);
		if (!objParent) { return; }

		var intIndex = -1;
		for (var intI = 0; intI < objParent.children.length; intI++)
		{
			if (objParent.children[intI].id === strFieldID)
			{
				intIndex = intI;
				break;
			}
		}

		if (intIndex === -1) { return; }

		var objCopy = JSON.parse(JSON.stringify(objParent.children[intIndex]));
		objCopy.id      = getGUID('field-');
		objCopy.caption = 'Copy of ' + objCopy.caption;

		objParent.children.splice(intIndex + 1, 0, objCopy);
		renderLayout();
	}

	function onClick_RemoveContainer(strContainerID_a) 
	{
		var blnResult = false;
		
		if (strContainerID_a) 
		{
			logConsole("Attempting to remove container:", strContainerID_a);
			var objRemovedContainer = removeContainerFromAnywhere(strContainerID_a);
			
			if (objRemovedContainer) 
			{
				renderLayout();
				blnResult = true;
			}
		}
		
		return blnResult;
	}

	function onClick_RemoveField(strFieldID_a) 
	{
		var blnResult = false;
		
		if (strFieldID_a) 
		{
			logConsole("Attempting to remove field:", strFieldID_a);
			var objRemovedField = removeFieldFromAnywhere(strFieldID_a);
			logConsole("Field removal result:", objRemovedField);
			
			if (objRemovedField) 
			{
				logConsole("About to call renderLayout()");
				renderLayout();
				logConsole("renderLayout() completed");
				blnResult = true;
			}
		}
		
		return blnResult;
	}

	function onClick_RemoveSection(strSectionID_a) 
	{
		var blnResult = false;
		
		if (strSectionID_a) 
		{
			logConsole("Attempting to remove section:", strSectionID_a);
			
			for (var intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
			{
				if (m_objOptions.layoutSections[intI].id === strSectionID_a) 
				{
					m_objOptions.layoutSections.splice(intI, 1);
					renderLayout();
					blnResult = true;
					break;
				}
			}
		}
		
		return blnResult;
	}

	function onDrop_Container(objEvent_a) 
	{
		objEvent_a.preventDefault();
		objEvent_a.stopPropagation();

		logConsole("=== onDrop_Container ===");
		logLayoutStructure();
		
		logConsole("Event target:", objEvent_a.target.tagName, "classes:", m_objOptions.cbElement(objEvent_a.target).attr('class'));
		logConsole("Closest container:", m_objOptions.cbElement(objEvent_a.target).closest('.gecd-vertical-container, .gecd-horizontal-container').attr('data-container-id'));
		
		var strData = objEvent_a.originalEvent.dataTransfer.getData('text/plain');
		logConsole("Drag data:", strData);
		
		var blnHandled = false;
		
		// Handle section drops on containers (insert section before the container's parent section)
		if (strData.startsWith(DRAG_SECTION) || (strData.startsWith(DRAG_CONTAINER) && 
			getContainerPropertiesByDragData(strData) && 
			getContainerPropertiesByDragData(strData).type === 'layoutsection')) 
		{
			blnHandled = onDrop_Container_LayoutSection(objEvent_a, strData);
		}
		
		if (!blnHandled) 
		{
			// Get target container for other operations
			var strTargetID = m_objOptions.cbElement(objEvent_a.target).closest('.gecd-vertical-container, .gecd-horizontal-container').attr('data-container-id');
			var objTarget_a = findContainerByID(strTargetID);
			
			if (objTarget_a) 
			{
				// Handle existing container repositioning
				if (!blnHandled) 
				{
					blnHandled = onDrop_Container_ExistingContainer(objEvent_a, strData, objTarget_a);
				}

				// Handle new container from sidebar
				if (!blnHandled) 
				{
					blnHandled = onDrop_Container_NewContainer(objEvent_a, strData, objTarget_a);
				}

				// Handle field drops
				if (!blnHandled) 
				{
					blnHandled = onDrop_Container_Field(strData, objTarget_a);
				}

				// Handle datatype drops
				if (!blnHandled) 
				{
					blnHandled = onDrop_Container_Datatype(strData, objTarget_a);
				}

				// If we get here, the drop wasn't handled
				if (!blnHandled && objTarget_a.type === 'verticalcontainer') 
				{
					logConsole("Vertical Containers can only contain Fields, not other containers.");
				}
			}
		}

		logLayoutStructure();
		
		logConsole("=== End onDrop_Container ===");
	}

	function onDrop_Container_Datatype(strData_a, objTarget_a) 
	{
		logConsole("=== onDrop_Container_Datatype ===");
		logLayoutStructure();
		
		var blnResult = false;
		var objNewField;
		var objSourceDatatype;
		
		if (objTarget_a.type === 'verticalcontainer') 
		{
			if (strData_a.startsWith(DRAG_NATIVE_DATATYPE)) 
			{
				objSourceDatatype = getNativeDatatypePropertiesByDragData(strData_a);
				if (objSourceDatatype) 
				{
					objNewField = createFieldFromDatatype(objSourceDatatype);

					objTarget_a.children = objTarget_a.children || [];
					objTarget_a.children.push(objNewField);
					renderLayout();
					blnResult = true;
				}
			} 
			else if (strData_a.startsWith(DRAG_DATATYPE)) 
			{
				objSourceDatatype = getDatatypePropertiesByDragData(strData_a);
				if (objSourceDatatype) 
				{
					objNewField = createFieldFromDatatype(objSourceDatatype);

					objTarget_a.children = objTarget_a.children || [];
					objTarget_a.children.push(objNewField);
					renderLayout();
					blnResult = true;
				}
			}
		}

		if (blnResult) 
		{
			logLayoutStructure();
		}
		
		logConsole("Result: " + blnResult);
		logConsole("=== End onDrop_Container_Datatype ===");
		
		return blnResult;
	}

	function onDrop_Container_ExistingContainer(objEvent_a, strData_a, objTarget_a) 
	{
		objEvent_a.preventDefault();
		objEvent_a.stopPropagation();

		logConsole("=== onDrop_Container_ExistingContainer ===");
		logLayoutStructure();

		var blnAbort = false;
		var blnResult = false;
		var objParent = null;
		
		if (strData_a.startsWith(DRAG_EXISTING_CONTAINER)) 
		{
			var strSourceID = strData_a.substring(DRAG_EXISTING_CONTAINER.length);
			var objSource = findContainerByID(strSourceID);
			
			if (objSource && objTarget_a && objSource.id !== objTarget_a.id) 
			{
				// CHECK THIS FIRST - before any other logic
				var objSourceParent = findParentOfContainer(objSource.id);
				if (objSourceParent && objSourceParent.id === objTarget_a.id) 
				{
					logConsole("Source container is already in target container - no move needed");
					blnAbort = true;
				}
			}
			
			if (!blnAbort)
			{
				logConsole("=== onDrop_Container_ExistingContainer ===");
				logConsole("Source ID: " + strSourceID);
				logConsole("Target container: " + (objTarget_a ? objTarget_a.type + " (" + objTarget_a.id + ")" : "null"));
				logConsole("Drop target element: " + objEvent_a.target.tagName + " with classes: " + (m_objOptions.cbElement(objEvent_a.target).attr('class') || 'none'));
				
				if (objSource && objTarget_a && objSource.id !== objTarget_a.id) 
				{
					// Remove source container from its current location first
					// logConsole("Removing source container from current location...");
					// removeContainerFromAnywhere(strSourceID);
					
					// Check what type of drop target this is
					var bIsHorizontalDropzone = m_objOptions.cbElement(objEvent_a.target).hasClass('gecd-horizontal-dropzone');
					var bIsVerticalDropzone = m_objOptions.cbElement(objEvent_a.target).hasClass('gecd-vertical-dropzone');
					var bIsSectionDropzone = m_objOptions.cbElement(objEvent_a.target).hasClass('gecd-section-dropzone');
					var bIsVerticalHeader = m_objOptions.cbElement(objEvent_a.target).closest('.gecd-vertical-header').length > 0;
					var bIsHorizontalHeader = m_objOptions.cbElement(objEvent_a.target).closest('.gecd-horizontal-header').length > 0;
					var bIsSectionHeader = m_objOptions.cbElement(objEvent_a.target).closest('.gecd-section-header').length > 0;
					
					logConsole("Drop analysis:");
					logConsole("  Is horizontal dropzone: " + bIsHorizontalDropzone);
					logConsole("  Is vertical dropzone: " + bIsVerticalDropzone);
					logConsole("  Is section dropzone: " + bIsSectionDropzone);
					logConsole("  Is vertical header: " + bIsVerticalHeader);
					logConsole("  Is horizontal header: " + bIsHorizontalHeader);
					logConsole("  Is section header: " + bIsSectionHeader);
					
					// CASES 3 & 4: Dropping on any container header (reorder - insert before target)
					if (bIsVerticalHeader || bIsHorizontalHeader) 
					{
						logConsole("CASE 3&4: Reordering - inserting before target container");
						
						// Get the container that owns this header, not the generic closest container
						var strHeaderContainerID;
						if (bIsHorizontalHeader) 
						{
							strHeaderContainerID = m_objOptions.cbElement(objEvent_a.target).closest('.gecd-horizontal-container').attr('data-container-id');
						} 
						else 
						{
							strHeaderContainerID = m_objOptions.cbElement(objEvent_a.target).closest('.gecd-vertical-container').attr('data-container-id');
						}
						
						var objHeaderTarget = findContainerByID(strHeaderContainerID);
						objParent = findParentOfContainer(objHeaderTarget.id);
						
						if (objParent) 
						{
							// Remove source container from its current location first
							logConsole("Removing source container from current location...");
							removeContainerFromAnywhere(strSourceID);
							
							logConsole("Found parent, inserting before target");
							insertContainerAtPosition(objSource, objHeaderTarget, objParent);
							renderLayout();
							blnResult = true;
						}
					}
					// CASE 1: Dropping on a horizontal container's dropzone (add to the right)
					else if (bIsHorizontalDropzone && objSource.type === 'verticalcontainer') 
					{
						logConsole("CASE 1: Adding vertical container to horizontal container");
						var objHorizontalContainer = findContainerByID(m_objOptions.cbElement(objEvent_a.target).closest('.gecd-horizontal-container').attr('data-container-id'));
						if (objHorizontalContainer) 
						{
							// Remove source container from its current location first
							logConsole("Removing source container from current location...");
							removeContainerFromAnywhere(strSourceID);
							
							objHorizontalContainer.children = objHorizontalContainer.children || [];
							objHorizontalContainer.children.push(objSource);
							renderLayout();
							blnResult = true;
						}
					}
					// CASE 2: Dropping on a section's dropzone (add to the end of section)
					else if (bIsSectionDropzone) 
					{
						logConsole("CASE 2: Adding container to end of section");
						var objSection = findSectionByID(m_objOptions.cbElement(objEvent_a.target).closest('.gecd-layouteditor-section').attr('data-section-id'));
						if (objSection) 
						{
							// Remove source container from its current location first
							logConsole("Removing source container from current location...");
							removeContainerFromAnywhere(strSourceID);
							
							objSection.containers = objSection.containers || [];
							objSection.containers.push(objSource);
							renderLayout();
							blnResult = true;
						}
					}
					// CASE 5: Dropping on a horizontal container's content area (but not dropzone)
					else if (objTarget_a.type === 'horizontalcontainer' && objSource.type === 'verticalcontainer') 
					{
						logConsole("CASE 4: Adding vertical container to horizontal container content");

						logConsole("Pre-validation - Source ID:", objSource.id);
						logConsole("Pre-validation - Target ID:", objTarget.id);

						// Remove source container from its current location first
						logConsole("Removing source container from current location...");
						removeContainerFromAnywhere(strSourceID);
						
						objTarget_a.children = objTarget_a.children || [];
						objTarget_a.children.push(objSource);
						renderLayout();
						blnResult = true;
					}
					// CASE 6: Default reordering behavior (insert before target)
					else 
					{
						logConsole("CASE 5: Default reordering behavior");
						objParent = findParentOfContainer(objTarget_a.id);
						if (objParent) 
						{
							// Remove source container from its current location first
							logConsole("Removing source container from current location...");
							removeContainerFromAnywhere(strSourceID);
							
							logConsole("Inserting container before target");
							insertContainerAtPosition(objSource, objTarget_a, objParent);
							renderLayout();
							blnResult = true;
						}
						else 
						{
							logConsole("No parent found - cannot reorder");
						}
					}
				}
				else 
				{
					logConsole("Invalid drop conditions:");
					logConsole("  Source exists: " + !!objSource);
					logConsole("  Target exists: " + !!objTarget_a);
					logConsole("  Different IDs: " + (objSource && objTarget_a && objSource.id !== objTarget_a.id));
				}
				
				logConsole("Result: " + blnResult);
				logConsole("=== End onDrop_Container_ExistingContainer ===");
			}
		}

		if (blnResult) 
		{
			logLayoutStructure();
		}
		
		logConsole("Result: " + blnResult);
		logConsole("=== End onDrop_Container_ExistingContainer ===");
			
		return blnResult;
	}

	function onDrop_Container_Field(strData_a, objTarget_a) 
	{
		logConsole("=== onDrop_Container_Field ===");
		logLayoutStructure();

		var blnResult = false;
		
		if (strData_a.startsWith(DRAG_FIELD) && objTarget_a.type === 'verticalcontainer') 
		{
			var strFieldID = strData_a.substring(DRAG_FIELD.length);
			var objField = removeFieldFromAnywhere(strFieldID);
			if (objField) 
			{
				objTarget_a.children = objTarget_a.children || [];
				objTarget_a.children.push(objField);
				renderLayout();
				blnResult = true;
			}
		}

		if (blnResult) 
		{
			logLayoutStructure();
		}
		
		logConsole("Result: " + blnResult);
		logConsole("=== End onDrop_Container_Field ===");
				
		return blnResult;
	}

	function onDrop_Container_LayoutSection(objEvent_a, strData_a) 
	{
		objEvent_a.preventDefault();
		objEvent_a.stopPropagation();

		logConsole("=== onDrop_Container_LayoutSection ===");
		logLayoutStructure();

		var intI;
		var strTargetID = m_objOptions.cbElement(objEvent_a.target).closest('.gecd-layouteditor-section').attr('data-section-id');
		var objTarget = findSectionByID(strTargetID);
		var blnResult = false;
		
		if (objTarget) 
		{
			if (strData_a.startsWith(DRAG_SECTION)) 
			{
				var strSourceID = strData_a.substring(DRAG_SECTION.length);
				if (strSourceID !== strTargetID) 
				{
					var objSource = null;
					var intSourceIndex = -1;
					
					for (intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
					{
						if (m_objOptions.layoutSections[intI].id === strSourceID) 
						{
							objSource = m_objOptions.layoutSections[intI];
							intSourceIndex = intI;
							break;
						}
					}
					
					if (objSource && intSourceIndex !== -1) 
					{
						m_objOptions.layoutSections.splice(intSourceIndex, 1);
						insertSectionAtPosition(objSource, objTarget);
						renderLayout();
						blnResult = true;
					}
				}
			} 
			else if (strData_a.startsWith(DRAG_CONTAINER)) 
			{
				var objContainer = getContainerPropertiesByDragData(strData_a);
				
				if (objContainer && objContainer.type === 'layoutsection') 
				{
					var objNewSection = 
					{
						id: getGUID('section-'),
						caption: objContainer.caption,
						visible: false,
						containers: [],
						fields: []
					};
					insertSectionAtPosition(objNewSection, objTarget);
					renderLayout();
					blnResult = true;
				}
			}
		}

		if (blnResult) 
		{
			logLayoutStructure();
		}
		
		logConsole("Result: " + blnResult);
		logConsole("=== End onDrop_Container_LayoutSection ===");
		
		return blnResult;
	}

	function onDrop_ContainerHeader(objEvent_a) 
	{
		objEvent_a.preventDefault();
		objEvent_a.stopPropagation();

		logConsole("=== onDrop_ContainerHeader ===");
		logLayoutStructure();

		var strData = objEvent_a.originalEvent.dataTransfer.getData('text/plain');
		var objHeader = m_objOptions.cbElement(objEvent_a.target).closest('.gecd-horizontal-header, .gecd-vertical-header');
		var objContainer = objHeader.parent();
		var strTargetID = objContainer.attr('data-container-id');
		var objTarget = findContainerByID(strTargetID);
		var objParent = findParentOfContainer(strTargetID);

		var blnHandled = false;

		// Handle reorder: existing container
		if (!blnHandled && strData.startsWith(DRAG_EXISTING_CONTAINER))
		{
			var strSourceID = strData.substring(DRAG_EXISTING_CONTAINER.length);
			var objSource = findContainerByID(strSourceID);
			if (objSource && objSource.id !== objTarget.id)
			{
				if (objParent)
				{
					removeContainerFromAnywhere(objSource.id);

					insertContainerAtPosition(objSource, objTarget, objParent);
					renderLayout();
					blnHandled = true;
				}
			}
		}

		// Handle new container from sidebar
		if (!blnHandled && strData.startsWith(DRAG_CONTAINER))
		{
			var objSourceType = getContainerPropertiesByDragData(strData);
			if (objSourceType)
			{
				var objNewContainer = {
					id: getGUID('container-'),
					type: objSourceType.type,
					caption: objSourceType.caption,
					children: []
				};
				if (objSourceType.type === 'horizontalcontainer')
				{
					objNewContainer.children = [
						{ id: getGUID('container-'), type: 'verticalcontainer', caption: 'Vertical Container', children: [] },
						{ id: getGUID('container-'), type: 'verticalcontainer', caption: 'Vertical Container', children: [] }
					];
				}
				if (objParent)
				{
					insertContainerAtPosition(objNewContainer, objTarget, objParent);
					renderLayout();
					blnHandled = true;
				}
			}
		}

		logLayoutStructure();
		logConsole("=== End onDrop_Container_LayoutSection ===");
	}

	function onDrop_Container_NewContainer(objEvent_a, strData_a, objTarget_a) 
	{
		objEvent_a.preventDefault();
		objEvent_a.stopPropagation();

		logConsole("=== onDrop_Container_NewContainer ===");
		logLayoutStructure();

		var blnResult = false;
		
		if (strData_a.startsWith(DRAG_CONTAINER)) 
		{
			var objSource = getContainerPropertiesByDragData(strData_a);
			
			if (objSource) 
			{
				var objNewContainer = 
				{
					id: getGUID('container-'),
					type: objSource.type,
					caption: objSource.caption,
					children: []
				};
				
				// Initialize with 2 vertical containers for horizontal container
				if (objSource.type === 'horizontalcontainer') 
				{
					objNewContainer.children = [
						{ id: getGUID('container-'), type: 'verticalcontainer', caption: 'Vertical Container', children: [] },
						{ id: getGUID('container-'), type: 'verticalcontainer', caption: 'Vertical Container', children: [] }
					];
				}
				
				// Check if we're dropping on a dropzone (should add at end)
				var bIsDropZone = m_objOptions.cbElement(objEvent_a.target).hasClass('gecd-horizontal-dropzone') || m_objOptions.cbElement(objEvent_a.target).hasClass('gecd-vertical-dropzone');
				
				// If dropping on a horizontal container or its dropzone, add to the right
				if (objTarget_a.type === 'horizontalcontainer' || bIsDropZone) 
				{
					var objHorizontalContainer;
					if (objTarget_a.type === 'horizontalcontainer')
					{
						objHorizontalContainer = objTarget_a;
					}
					else
					{
						objHorizontalContainer = findContainerByID(m_objOptions.cbElement(objEvent_a.target).closest('.gecd-horizontal-container').attr('data-container-id'));
					}
					
					if (objHorizontalContainer && objNewContainer.type === 'verticalcontainer') 
					{
						objHorizontalContainer.children = objHorizontalContainer.children || [];
						objHorizontalContainer.children.push(objNewContainer);
						renderLayout();
						blnResult = true;
					}
				} 
				else 
				{
					// Otherwise, insert before target container
					var objParent = findParentOfContainer(objTarget_a.id);
					if (objParent) 
					{
						insertContainerAtPosition(objNewContainer, objTarget_a, objParent);
						renderLayout();
						blnResult = true;
					}
				}
			}
		}

		if (blnResult) 
		{
			logLayoutStructure();
		}
		
		logConsole("Result: " + blnResult);
		logConsole("=== End onDrop_Container_NewContainer ===");
		
		return blnResult;
	}

	function onDrop_Field_ExistingContainer(strData_a, strTargetID_a) 
	{
		logConsole("=== onDrop_Field_ExistingContainer ===");
		logLayoutStructure();

		var blnResult = false;
		
		if (strData_a.startsWith(DRAG_EXISTING_CONTAINER)) {
			var strSourceID = strData_a.substring(DRAG_EXISTING_CONTAINER.length);
			var objSource = findContainerByID(strSourceID);
			var objTarget = findParentContainerOfField(strTargetID_a);
			
			if (objSource && objTarget && objSource.type === 'verticalcontainer') 
			{
				var objParent = findParentOfContainer(objTarget.id);
				if (objParent) 
				{
					removeContainerFromAnywhere(strSourceID);

					insertContainerAtPosition(objSource, objTarget, objParent);
					renderLayout();
					blnResult = true;
				}
			}
		}
		
		if (blnResult) 
		{
			logLayoutStructure();
		}
		
		logConsole("Result: " + blnResult);
		logConsole("=== End onDrop_Field_ExistingContainer ===");
		
		return blnResult;
	}

	function onDrop_Field_FieldReorder(strData_a, strTargetID_a) 
	{
		logConsole("=== onDrop_Field_FieldReorder ===");
		logLayoutStructure();

		var intI;
		var blnResult = false;
		
		if (strData_a.startsWith(DRAG_FIELD)) 
		{
			var strSourceID = strData_a.substring(DRAG_FIELD.length);
			
			if (strSourceID !== strTargetID_a) 
			{
				var objSourceParent = findParentContainerOfField(strSourceID);
				var objTarget = findParentContainerOfField(strTargetID_a);
				var intSourceIndex = -1, targetIndex = -1, objSource = null, objTargetField = null;
				
				if (objSourceParent && objTarget) 
				{
					for (intI = 0; intI < objSourceParent.children.length; intI++) 
					{
						if (objSourceParent.children[intI].id === strSourceID) 
						{
							objSource = objSourceParent.children[intI]; 
							intSourceIndex = intI;
						}
					}
					for (intI = 0; intI < objTarget.children.length; intI++) 
					{
						if (objTarget.children[intI].id === strTargetID_a) 
						{
							objTargetField = objTarget.children[intI]; 
							targetIndex = intI;
						}
					}
					
					if (intSourceIndex !== -1 && objSource && targetIndex !== -1 && objTargetField) 
					{
						objSourceParent.children.splice(intSourceIndex, 1);
						if (objSourceParent === objTarget && intSourceIndex < targetIndex) targetIndex--;
						objTarget.children.splice(targetIndex, 0, objSource);
						renderLayout();
						blnResult = true;
					}
				}
			}
		}

		if (blnResult) 
		{
			logLayoutStructure();
		}
		
		logConsole("Result: " + blnResult);
		logConsole("=== End onDrop_Field_FieldReorder ===");
		
		return blnResult;
	}

	function onDrop_Field_LayoutSection(strData_a, strTargetID_a) 
	{
		logConsole("=== onDrop_Field_LayoutSection ===");
		logLayoutStructure();

		var intI;
		var blnResult = false;
		
		if (strData_a.startsWith(DRAG_SECTION) || (strData_a.startsWith(DRAG_CONTAINER) && 
			 getContainerPropertiesByDragData(strData_a) &&
			 getContainerPropertiesByDragData(strData_a).type === 'layoutsection')) 
		 {
			// Find the section containing this field
			var objTarget = findParentContainerOfField(strTargetID_a);
			
			if (objTarget) 
			{
				for (intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
				{
					var objSection = m_objOptions.layoutSections[intI];
					if (objSection.containers) 
					{
						for (var intJ = 0; intJ < objSection.containers.length; intJ++) 
						{
							if (findFieldParentRecursive(objSection.containers[intJ], strTargetID_a)) 
							{
								objTarget = objSection;
								break;
							}
						}
					}
					if (objTarget) break;
				}
				
				if (objTarget) 
				{
					if (strData_a.startsWith(DRAG_SECTION)) 
					{
						var strSourceID = strData_a.substring(DRAG_SECTION.length);
						if (strSourceID !== objTarget.id) 
						{
							var objSource = null;
							var intSourceIndex = -1;
							
							for (intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
							{
								if (m_objOptions.layoutSections[intI].id === strSourceID) 
								{
									objSource = m_objOptions.layoutSections[intI];
									intSourceIndex = intI;
									break;
								}
							}
							
							if (objSource && intSourceIndex !== -1) 
							{
								m_objOptions.layoutSections.splice(intSourceIndex, 1);
								insertSectionAtPosition(objSource, objTarget);
								renderLayout();
								blnResult = true;
							}
						}
					} 
					else if (strData_a.startsWith(DRAG_CONTAINER)) 
					{
						var objContainer = getContainerPropertiesByDragData(strData_a);
						
						if (objContainer && objContainer.type === 'layoutsection') 
						{
							var objNewSection = 
							{
								id: getGUID('section-'),
								caption: objContainer.caption,
								visible: false,
								containers: [],
								fields: []
							};
							insertSectionAtPosition(objNewSection, objTarget);
							renderLayout();
							blnResult = true;
						}
					}
				}
			}
		}
		
		if (blnResult) 
		{
			logLayoutStructure();
		}
		
		logConsole("Result: " + blnResult);
		logConsole("=== End onDrop_Field_LayoutSection ===");
		
		return blnResult;
	}

	function onDrop_Field_NewContainer(strData_a, strTargetID_a) 
	{
		logConsole("=== onDrop_Field_NewContainer ===");
		logLayoutStructure();

		var blnResult = false;
		
		if (strData_a.startsWith(DRAG_CONTAINER)) 
		{
			var objSource = getContainerPropertiesByDragData(strData_a);
			var objTarget = findParentContainerOfField(strTargetID_a);
			var objParent = findParentOfContainer(objTarget.id);

			if (objSource && objTarget && objParent) 
			{
				var objNewContainer = 
				{
					id: getGUID('container-'),
					type: objSource.type,
					caption: objSource.caption,
					children: []
				};
				
				// Initialize with 2 vertical containers for horizontal container
				if (objSource.type === 'horizontalcontainer') 
				{
					objNewContainer.children = [
						{ id: getGUID('container-'), type: 'verticalcontainer', caption: 'Vertical Container', children: [] },
						{ id: getGUID('container-'), type: 'verticalcontainer', caption: 'Vertical Container', children: [] }
					];
				}
				
				insertContainerAtPosition(objNewContainer, objTarget, objParent);
				renderLayout();
				blnResult = true;
			}
		}
		
		if (blnResult) 
		{
			logLayoutStructure();
		}
		
		logConsole("Result: " + blnResult);
		logConsole("=== End onDrop_Field_NewContainer ===");
		
		return blnResult;
	}

	function onDrop_Field_NewDatatype(strData_a, strTargetID_a) 
	{
		logConsole("=== onDrop_Field_NewDatatype ===");
		logLayoutStructure();

		var intI;
		var blnResult = false;
		
		if (strData_a.startsWith(DRAG_DATATYPE) || strData_a.startsWith(DRAG_NATIVE_DATATYPE)) 
		{
			var objTarget = findParentContainerOfField(strTargetID_a);
			
			if (objTarget) 
			{
				var intTargetIndex = -1;
				for (intI = 0; intI < objTarget.children.length; intI++) 
				{
					if (objTarget.children[intI].id === strTargetID_a) 
					{					
						intTargetIndex = intI; 
						break; 
					}
				}
				
				var objNewField = null;
				if (strData_a.startsWith(DRAG_DATATYPE)) 
				{
					var objSourceDatatype = getDatatypePropertiesByDragData(strData_a);
					if (objSourceDatatype) 
					{
						objNewField = createFieldFromDatatype(objSourceDatatype);
					}
				} 
				else if (strData_a.startsWith(DRAG_NATIVE_DATATYPE)) 
				{
					var objSourceNative = getNativeDatatypePropertiesByDragData(strData_a);
					if (objSourceNative) 
					{
						objNewField = createFieldFromDatatype(objSourceNative);
					}
				}
				
				if (objNewField && intTargetIndex !== -1) 
				{
					objTarget.children.splice(intTargetIndex, 0, objNewField);
					renderLayout();
					blnResult = true;
				}
			}
		}
		
		if (blnResult) 
		{
			logLayoutStructure();
		}
		
		logConsole("Result: " + blnResult);
		logConsole("=== End onDrop_Field_NewDatatype ===");
		
		return blnResult;
	}

	function onDrop_Layout_ExistingSection(strData_a) 
	{
		logConsole("=== onDrop_Layout_ExistingSection ===");
		logLayoutStructure();

		var blnResult = false;
		
		if (strData_a.startsWith(DRAG_SECTION)) 
		{
			var strSectionID = strData_a.substring(DRAG_SECTION.length);
			var objSection = null;
			var intSourceIndex = -1;
			
			// Find the section to move
			for (var intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
			{
				if (m_objOptions.layoutSections[intI].id === strSectionID) 
				{
					objSection = m_objOptions.layoutSections[intI];
					intSourceIndex = intI;
					break;
				}
			}
			
			if (objSection && intSourceIndex !== -1) 
			{
				// Remove from current position
				m_objOptions.layoutSections.splice(intSourceIndex, 1);
				// Add to end (could be enhanced to drop at specific position)
				m_objOptions.layoutSections.push(objSection);
				renderLayout();
				blnResult = true;
			}
		}
		
		if (blnResult) 
		{
			logLayoutStructure();
		}
		
		logConsole("Result: " + blnResult);
		logConsole("=== End onDrop_Layout_ExistingSection ===");
		
		return blnResult;
	}
		
	function onDrop_Layout_NewLayoutSection(strData_a) 
	{
		logConsole("=== onDrop_Layout_NewLayoutSection ===");
		logLayoutStructure();

		var blnResult = false;
		
		if (strData_a.startsWith(DRAG_CONTAINER)) 
		{
			var objContainer = getContainerPropertiesByDragData(strData_a);
			
			if (objContainer && objContainer.type === 'layoutsection') 
			{
				var objNewSection = 
				{
					id: getGUID('section-'),
					caption: objContainer.caption,
					visible: false,
					containers: [],
					fields: []
				};
				m_objOptions.layoutSections.push(objNewSection);
				renderLayout();
				blnResult = true;
			}
		}
		
		if (blnResult) 
		{
			logLayoutStructure();
		}
		
		logConsole("Result: " + blnResult);
		logConsole("=== End onDrop_Layout_NewLayoutSection ===");
		
		return blnResult;
	}

	function onDrop_Section_ExistingSection(strData_a, objTarget_a) 
	{
		logConsole("=== onDrop_Section_ExistingSection ===");
		logLayoutStructure();

		var blnResult = false;
		
		if (strData_a.startsWith(DRAG_SECTION)) 
		{
			var strSourceID = strData_a.substring(DRAG_SECTION.length);
			
			if (strSourceID !== objTarget_a.id) {
				// Find and remove source section
				var objSource = null;
				var intSourceIndex = -1;
				
				for (var intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
				{
					if (m_objOptions.layoutSections[intI].id === strSourceID) 
					{
						objSource = m_objOptions.layoutSections[intI];
						intSourceIndex = intI;
						break;
					}
				}
				
				if (objSource && intSourceIndex !== -1) 
				{
					// Remove from current position
					m_objOptions.layoutSections.splice(intSourceIndex, 1);
					
					// Insert before target section
					insertSectionAtPosition(objSource, objTarget_a);
					renderLayout();
					blnResult = true;
				}
			}
		}
		
		if (blnResult) 
		{
			logLayoutStructure();
		}
		
		logConsole("Result: " + blnResult);
		logConsole("=== End onDrop_Section_ExistingSection ===");
		
		return blnResult;
	}

	function onDrop_Section_NewLayoutSection(strData_a, objTarget_a) 
	{
		logConsole("=== onDrop_Section_NewLayoutSection ===");
		logLayoutStructure();

		var blnResult = false;
		
		if (strData_a.startsWith(DRAG_CONTAINER)) 
		{
			var objContainer = getContainerPropertiesByDragData(strData_a);
			
			if (objContainer && objContainer.type === 'layoutsection') 
			{
				var objNewSection = 
				{
					id: getGUID('section-'),
					caption: objContainer.caption,
					visible: false,
					containers: [],
					fields: []
				};
				
				// Insert before target section
				insertSectionAtPosition(objNewSection, objTarget_a);
				renderLayout();
				blnResult = true;
			}
		}
		
		if (blnResult) 
		{
			logLayoutStructure();
		}
		
		logConsole("Result: " + blnResult);
		logConsole("=== End onDrop_Section_NewLayoutSection ===");
		
		return blnResult;
	}

	function onDrop_SectionContent_ExistingContainer(strData_a, objTarget_a) 
	{
		logConsole("=== onDrop_SectionContent_ExistingContainer ===");
		logLayoutStructure();

		var blnResult = false;
		
		if (strData_a.startsWith(DRAG_EXISTING_CONTAINER)) 
		{
			var strContainerID = strData_a.substring(DRAG_EXISTING_CONTAINER.length);
			var objContainer = removeContainerFromAnywhere(strContainerID);
			
			if (objContainer && (objContainer.type === 'verticalcontainer' || objContainer.type === 'horizontalcontainer')) 
			{
				objTarget_a.containers = objTarget_a.containers || [];
				objTarget_a.containers.push(objContainer);
				renderLayout();
				blnResult = true;
			}
		}
		
		if (blnResult) 
		{
			logLayoutStructure();
		}
		
		logConsole("Result: " + blnResult);
		logConsole("=== End onDrop_SectionContent_ExistingContainer ===");
		
		return blnResult;
	}

	function onDrop_SectionContent_LayoutSection(strData_a, objTarget_a) 
	{
		logConsole("=== onDrop_SectionContent_LayoutSection ===");
		logLayoutStructure();

		var intI;
		var blnResult = false;
		
		if (strData_a.startsWith(DRAG_SECTION) || (strData_a.startsWith(DRAG_CONTAINER) && 
			 getContainerPropertiesByDragData(strData_a) && 
			 getContainerPropertiesByDragData(strData_a).type === 'layoutsection')) 
		{
			
			if (strData_a.startsWith(DRAG_SECTION)) 
			{
				var strSourceID = strData_a.substring(DRAG_SECTION.length);
				if (strSourceID !== objTarget_a.id) 
				{
					var objSource = null;
					var intSourceIndex = -1;
					
					for (intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
					{
						if (m_objOptions.layoutSections[intI].id === strSourceID) 
						{
							objSource = m_objOptions.layoutSections[intI];
							intSourceIndex = intI;
							break;
						}
					}
					
					if (objSource && intSourceIndex !== -1) 
					{
						m_objOptions.layoutSections.splice(intSourceIndex, 1);
						insertSectionAtPosition(objSource, objTarget_a);
						renderLayout();
						blnResult = true;
					}
				}
			} 
			else if (strData_a.startsWith(DRAG_CONTAINER)) 
			{
				var objContainer = getContainerPropertiesByDragData(strData_a);
				
				if (objContainer && objContainer.type === 'layoutsection') 
				{
					var objNewSection = 
					{
						id: getGUID('section-'),
						caption: objContainer.caption,
						visible: false,
						containers: [],
						fields: []
					};
					insertSectionAtPosition(objNewSection, objTarget_a);
					renderLayout();
					blnResult = true;
				}
			}
		}
		
		if (blnResult) 
		{
			logLayoutStructure();
		}
		
		logConsole("Result: " + blnResult);
		logConsole("=== End onDrop_SectionContent_LayoutSection ===");
		
		return blnResult;
	}
		
	function onDrop_SectionContent_InvalidField(strData_a) 
	{
		logConsole("=== onDrop_SectionContent_InvalidField ===");
		logLayoutStructure();

		var blnResult = false;
		
		if (strData_a.startsWith(DRAG_FIELD) || strData_a.startsWith(DRAG_DATATYPE) || strData_a.startsWith(DRAG_NATIVE_DATATYPE)) 
		{
			logConsole("Fields can only be dropped on Vertical Containers, not directly on Layout Sections.");
			blnResult = true; // Return true because we "handled" it (by rejecting it)
		}
		
		if (blnResult) 
		{
			logLayoutStructure();
		}
		
		logConsole("Result: " + blnResult);
		logConsole("=== End onDrop_SectionContent_InvalidField ===");
		
		return blnResult;
	}

	function onDrop_SectionContent_NewContainer(strData_a, objTarget_a) 
	{
		logConsole("=== onDrop_SectionContent_NewContainer ===");
		logLayoutStructure();
		
		var blnResult = false;
		
		if (strData_a.startsWith(DRAG_CONTAINER)) 
		{
			var objContainer = getContainerPropertiesByDragData(strData_a);
			
			if (objContainer && (objContainer.type === 'verticalcontainer' || objContainer.type === 'horizontalcontainer')) 
			{
				var objNewContainer = 
				{
					id: getGUID('container-'),
					type: objContainer.type,
					caption: objContainer.caption,
					children: []
				};
				
				// Initialize with 2 vertical containers for horizontal container
				if (objContainer.type === 'horizontalcontainer') 
				{
					objNewContainer.children = [
						{ id: getGUID('container-'), type: 'verticalcontainer', caption: 'Vertical Container', children: [] },
						{ id: getGUID('container-'), type: 'verticalcontainer', caption: 'Vertical Container', children: [] }
					];
				}
				
				objTarget_a.containers = objTarget_a.containers || [];
				objTarget_a.containers.push(objNewContainer);
				renderLayout();
				blnResult = true;
			}
		}
		
		if (blnResult) 
		{
			logLayoutStructure();
		}
		
		logConsole("Result: " + blnResult);
		logConsole("=== End onDrop_SectionContent_NewContainer ===");
		
		return blnResult;
	}

    // event handlers

	function onClick_ContainerHeader(objEvent_a)
	{
		objEvent_a.stopPropagation();
		var strContainerID = m_objOptions.cbElement(this).closest('[data-container-id]').attr('data-container-id');
		renderProperties(null, strContainerID, null);
	}
	
	function onClick_Field(objEvent_a) 
	{
		objEvent_a.stopPropagation();

		var strSectionID = m_objOptions.cbElement(this).attr('data-section-id');
		var strFieldID = m_objOptions.cbElement(this).attr('data-field-id');
		var strContainerID = m_objOptions.cbElement(this).attr('data-container-id');

		renderProperties(strSectionID, strContainerID, strFieldID);
	}
	
	function onClick_Layout(objEvent_a)
	{
		if (objEvent_a.target === m_objOptions.cbElement(this)[0]) 
		{
			m_objOptions.cbElement(m_objOptions.propertyEditorTarget).empty();
		}
	}
	
	function onClick_SectionHeader(objEvent_a)
	{
		objEvent_a.stopPropagation();
		var strSectionID = m_objOptions.cbElement(this).closest('[data-section-id]').attr('data-section-id');
		renderProperties(strSectionID, null, null);
	}
	
	function onClick_Remove(objEvent_a) 
	{
		objEvent_a.preventDefault();
		objEvent_a.stopPropagation();
		
		logConsole("=== onClick_Remove ===");
		logLayoutStructure();

		var strSectionID = m_objOptions.cbElement(this).attr('data-section-id');
		var strFieldID = m_objOptions.cbElement(this).attr('data-field-id');
		var strContainerID = m_objOptions.cbElement(this).attr('data-container-id');
		var blnHandled = false;
		
		logConsole("onClick_Remove called with:", {sectionID: strSectionID, fieldID: strFieldID, containerID: strContainerID});
		
		// Try field removal
		if (!blnHandled) 
		{
			blnHandled = onClick_RemoveField(strFieldID);
		}
		
		// Try container removal
		if (!blnHandled) 
		{
			blnHandled = onClick_RemoveContainer(strContainerID);
		}
		
		// Try section removal
		if (!blnHandled) 
		{
			blnHandled = onClick_RemoveSection(strSectionID);
		}
		
		// If nothing was removed, log it
		if (!blnHandled) 
		{
			logConsole("Nothing was removed - no valid ID found");
		}

		logLayoutStructure();
		logConsole("=== End onClick_Remove ===");
	}

	function onDblClick_ContainerHeader(objEvent_a)
	{
		objEvent_a.stopPropagation();

		var strContainerID = m_objOptions.cbElement(this).closest('[data-container-id]').attr('data-container-id');
		logConsole("Double-clicked container ID:", strContainerID);
		renderProperties(null, strContainerID, null);

		activateTab('propertyeditor');
	}
	
	function onDblClick_Field(objEvent_a) 
	{
		objEvent_a.stopPropagation();

		var strFieldID = m_objOptions.cbElement(this).attr('data-field-id');
		renderProperties(null, null, strFieldID);

		activateTab('propertyeditor');
	}
	
	function onDblClick_SectionHeader(objEvent_a)
	{
		objEvent_a.stopPropagation();
		
		var strSectionID = m_objOptions.cbElement(this).closest('[data-section-id]').attr('data-section-id');
		renderProperties(strSectionID, null, null);

		activateTab('propertyeditor');
	}
	
    function onDragOver(objEvent_a) 
    {
        objEvent_a.preventDefault();
    }
    
    function onDragOver_Layout(objEvent_a) 
    {
        objEvent_a.preventDefault();
    }

	function onDragStart_Container(objEvent_a)
	{
		logConsole("=== onDragStart_Container FIRED ===");
		logConsole("Dragging m_objOptions.cbElement:", objEvent_a.target.tagName, "classes:", m_objOptions.cbElement(objEvent_a.target).attr('class'));
		
		// Check if this is from sidebar (containertype) or existing container
		var strContainerType = m_objOptions.cbElement(this).attr('data-container-type');
		var strContainerID = m_objOptions.cbElement(this).attr('data-container-id');
		
		logConsole("Container type:", strContainerType);
		logConsole("Container ID:", strContainerID);
		
		if (strContainerType !== undefined) 
		{
			// Dragging from sidebar
			objEvent_a.originalEvent.dataTransfer.setData('text/plain', 'container:' + strContainerType);
			logConsole("Set data: container:" + strContainerType);
		} 
		else if (strContainerID !== undefined) 
		{
			// Dragging existing container
			objEvent_a.originalEvent.dataTransfer.setData('text/plain', 'existingcontainer:' + strContainerID);
			logConsole("Set data: existingcontainer:" + strContainerID);
			objEvent_a.stopPropagation();
		}
		else 
		{
			logConsole("ERROR: No container type or ID found!");
		}
	}

	function onDragStart_Datatype(objEvent_a)
	{
		var strDatatype = m_objOptions.cbElement(this).attr('data-datatype-type');
		var strNativeDatatype = m_objOptions.cbElement(this).attr('data-native-datatype-type');
		
		if (strDatatype !== undefined) 
		{
			// Regular datatype
			objEvent_a.originalEvent.dataTransfer.setData('text/plain', 'datatype:' + strDatatype);
		} 
		else if (strNativeDatatype !== undefined) 
		{
			// Native datatype
			objEvent_a.originalEvent.dataTransfer.setData('text/plain', 'nativedatatype:' + strNativeDatatype);
		}
	}
		
    function onDragStart_Field(objEvent_a)
    {
        var strFieldID = m_objOptions.cbElement(this).attr('data-field-id');
        objEvent_a.originalEvent.dataTransfer.setData('text/plain', 'field:' + strFieldID);
        objEvent_a.stopPropagation();
    }
    
    function onDragStart_LayoutSection(objEvent_a)
    {
        var strSectionID = m_objOptions.cbElement(this).attr('data-section-id');
        objEvent_a.originalEvent.dataTransfer.setData('text/plain', 'section:' + strSectionID);
    }
	
	function onDrop_Field(objEvent_a) 
	{
		objEvent_a.preventDefault();
		objEvent_a.stopPropagation();

		var strData = objEvent_a.originalEvent.dataTransfer.getData('text/plain');
		var strTargetID = m_objOptions.cbElement(this).attr('data-field-id');
		var blnHandled = false;
		
		if (strTargetID) 
		{
			// Try field-to-field reorder
			if (!blnHandled) 
			{
				blnHandled = onDrop_Field_FieldReorder(strData, strTargetID);
			}

			// Try new datatype creation
			if (!blnHandled) 
			{
				blnHandled = onDrop_Field_NewDatatype(strData, strTargetID);
			}

			// Try existing container drop
			if (!blnHandled) 
			{
				blnHandled = onDrop_Field_ExistingContainer(strData, strTargetID);
			}

			// Try new container creation
			if (!blnHandled) 
			{
				blnHandled = onDrop_Field_NewContainer(strData, strTargetID);
			}

			// Try layout section handling
			if (!blnHandled) 
			{
				blnHandled = onDrop_Field_LayoutSection(strData, strTargetID);
			}

			// If nothing handled the drop, it's invalid
			if (!blnHandled) 
			{
				logConsole("Invalid drop on field:", strData);
			}
		}
	}

	function onDrop_Layout(objEvent_a) 
	{
		objEvent_a.preventDefault();
		
		var strData = objEvent_a.originalEvent.dataTransfer.getData('text/plain');
		var blnHandled = false;
		
		// Try new layout section creation from sidebar
		if (!blnHandled) 
		{
			blnHandled = onDrop_Layout_NewLayoutSection(strData);
		}
		
		// Try existing section repositioning
		if (!blnHandled) 
		{
			blnHandled = onDrop_Layout_ExistingSection(strData);
		}
		
		// If nothing handled the drop, it's an unknown drop type
		if (!blnHandled) 
		{
			logConsole("Unknown drop type on layout area:", strData);
		}
	}

	function onDrop_Section(objEvent_a) 
	{
		objEvent_a.preventDefault();
		objEvent_a.stopPropagation();

		var strData = objEvent_a.originalEvent.dataTransfer.getData('text/plain');
		var strTargetID = m_objOptions.cbElement(objEvent_a.target).closest('.gecd-layouteditor-section').attr('data-section-id');
		var objTarget = findSectionByID(strTargetID);
		var blnHandled = false;

		// Move/reorder existing section
		if (!blnHandled && strData.startsWith(DRAG_SECTION)) 
		{
			var strSourceID = strData.substring(DRAG_SECTION.length);
			if (strSourceID !== strTargetID) {
				// Remove the source section and insert before target
				var objSource = null;
				for (var intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
				{
					if (m_objOptions.layoutSections[intI].id === strSourceID) 
					{
						objSource = m_objOptions.layoutSections.splice(intI, 1)[0];
						break;
					}
				}
				if (objSource && objTarget) 
				{
					insertSectionAtPosition(objSource, objTarget);
					renderLayout();
					blnHandled = true;
				}
			}
		}

		// Add NEW section from sidebar before the target
		if (!blnHandled && strData.startsWith(DRAG_CONTAINER)) 
		{
			var objContainerType = getContainerPropertiesByDragData(strData);
			if (objContainerType && objContainerType.type === 'layoutsection') 
			{
				var objNewSection = {
					id: getGUID('section-'),
					caption: objContainerType.caption,
					visible: false,
					containers: [],
					fields: []
				};
				insertSectionAtPosition(objNewSection, objTarget);
				renderLayout();
				blnHandled = true;
			}
		}
	}

	function onDrop_SectionContent(objEvent_a) 
	{
		objEvent_a.preventDefault();
		objEvent_a.stopPropagation();
		
		var strData = objEvent_a.originalEvent.dataTransfer.getData('text/plain');
		var strSectionID = m_objOptions.cbElement(this).closest('.gecd-layouteditor-section').attr('data-section-id');
		var blnHandled = false;
		
		// Find the target section
		var objTarget = null;
		for (var intI = 0; intI < m_objOptions.layoutSections.length; intI++) 
		{
			if (m_objOptions.layoutSections[intI].id === strSectionID) 
			{
				objTarget = m_objOptions.layoutSections[intI];
				break;
			}
		}
		
		if (objTarget) 
		{
			// Try layout section handling (existing section or new layout section)
			if (!blnHandled) 
			{
				blnHandled = onDrop_SectionContent_LayoutSection(strData, objTarget);
			}
			
			// Try existing container drop
			if (!blnHandled) 
			{
				blnHandled = onDrop_SectionContent_ExistingContainer(strData, objTarget);
			}
			
			// Try new container creation
			if (!blnHandled) 
			{
				blnHandled = onDrop_SectionContent_NewContainer(strData, objTarget);
			}
			
			// Try to handle invalid field drops (this will log the error and return true if it's a field)
			if (!blnHandled) 
			{
				blnHandled = onDrop_SectionContent_InvalidField(strData);
			}
			
			// If nothing handled the drop, it's an unknown drop type
			if (!blnHandled) 
			{
				logConsole("Unknown drop type on section:", strData);
			}
		}
	}

    // publics
	
    initialise();
}