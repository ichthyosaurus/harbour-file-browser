//@ This file is part of opal-about.
//@ https://github.com/Pretty-SFOS/opal-about
//@ SPDX-FileCopyrightText: 2021-2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
.pragma library
function updateSpdxList(licenses,spdxTarget,force){if(spdxTarget!==null&&force!==true){return null
}var spdx=[]
for(var i in licenses){spdx.push(licenses[i].spdxId)
}return{spdx:spdx}
}
function makeStringListConcat(first,second,allowEmpty){var a=makeStringList(first,allowEmpty)
var b=makeStringList(second,allowEmpty)
return a.concat(b)
}
function makeStringList(listOrString,allowEmpty){if(!(listOrString instanceof Array))listOrString=[listOrString]
var ae=(allowEmpty===true?1:0)
var ret=[]
for(var i in listOrString){var val=listOrString[i]
var str=(typeof val==="string"?val:(!val?"":String(val))).trim()
if(ae===0&&!val)continue
ret.push(val)
}return ret
}
function formatAppVersion(version,release,releaseType){var versionString=version
if(!!release&&release!==""&&release!=="1"){versionString+="-"+release
}if(!!releaseType&&releaseType!==""){versionString+=" (%1)".arg(releaseType)
}return versionString
}
