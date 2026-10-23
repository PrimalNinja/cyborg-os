function element(strScope_a, strElement_a)
{
	var objResult = null;
	var strElement = strElement_a;
	var strScope = strScope_a;

	if (strElement === undefined)
	{
		objResult = $(strScope);
	}
	else
	{
		objResult = $(strElement, strScope);
	}
	
	return objResult;
}

// prefix added because mysql doesn't like certain patterns of GUIDs for field names
// eg: 6e4 gets confused by mysql as a standard form number
function getGUID(strPrefix_a)
{
	var strPrefix = strPrefix_a;
	if (strPrefix == undefined) { strPrefix = ''; }

	return strPrefix + 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c)
	{
		var r = Math.random() * 16 | 0,
		v = c == 'x' ? r : (r & 0x3 | 0x8);
		return v.toString(16);
	}
	);
}

function toBoolean(strValue_a)
{
	return (strValue_a === 'yes' || strValue_a === 'true' || strValue_a === '1' || strValue_a === true);
}

