//@ This file is part of opal-mediaplayer.
//@ https://github.com/Pretty-SFOS/opal-mediaplayer
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick 2.6
import Sailfish.Silica 1.0
import QtMultimedia 5.6
Loader{id:root
property Item page
property string _title:"Playback failed"
property string _details:"These are the details. Marvel at them. They are marvellous."
property string _iconSource:"image://theme/icon-l-attention"
function reset(){_title=""
_details=""
_iconSource="image://theme/icon-l-attention"
sourceComponent=null
}function show(error,errorString){var title=qsTranslate("Opal.MediaPlayer","Playback failed","error info page heading")
var details=errorString+"\n\n"
if(error===MediaPlayer.ResourceError){title=qsTranslate("Opal.MediaPlayer","Resource error","error info page heading")
}else if(error===MediaPlayer.FormatError){qsTranslate("Opal.MediaPlayer","Format error","error info page heading")
}else if(error===MediaPlayer.NetworkError){qsTranslate("Opal.MediaPlayer","Network error","error info page heading")
}else if(error===MediaPlayer.AccessDenied){qsTranslate("Opal.MediaPlayer","Access denied","error info page heading")
}else if(error===MediaPlayer.ServiceMissing){qsTranslate("Opal.MediaPlayer","Media service missing","error info page heading")
}if(error===MediaPlayer.ResourceError){details+=qsTranslate("Opal.MediaPlayer","The video cannot be played due to a problem allocating resources.")
}else if(error===MediaPlayer.FormatError){details+=qsTranslate("Opal.MediaPlayer","The audio or video format is not supported.")
}else if(error===MediaPlayer.NetworkError){details+=qsTranslate("Opal.MediaPlayer","The video cannot be played due to network issues.")
}else if(error===MediaPlayer.AccessDenied){details+=qsTranslate("Opal.MediaPlayer","The video cannot be played due to insufficient permissions.")
}else if(error===MediaPlayer.ServiceMissing){details+=qsTranslate("Opal.MediaPlayer","The video cannot be played because the media service could not be instantiated.")
}else{details+=qsTranslate("Opal.MediaPlayer","Playback failed due to an expected "+"error. Please restart the app and try again.")
}showText(title,details)
}function showText(title,details,icon){_title=title||_title||""
_details=details||_details||""
_iconSource=icon||_iconSource||"image://theme/icon-l-attention"
sourceComponent=overlayComponent
}visible:!!_title||!!_details
anchors{verticalCenter:parent.verticalCenter
verticalCenterOffset:-Theme.iconSizeLarge
}width:parent.width
sourceComponent:null
Component{id:overlayComponent
Column{spacing:Theme.paddingLarge
width:parent.width
HighlightImage{source:root._iconSource
highlighted:true
anchors.horizontalCenter:parent.horizontalCenter
}Label{x:Theme.horizontalPageMargin
width:parent.width-2*x
horizontalAlignment:Text.AlignHCenter
wrapMode:Text.Wrap
color:Theme.secondaryHighlightColor
font{pixelSize:Theme.fontSizeExtraLarge
family:Theme.fontFamilyHeading
}text:root._title
}Label{x:Theme.horizontalPageMargin
width:parent.width-2*x
horizontalAlignment:Text.AlignLeft
wrapMode:Text.Wrap
color:Theme.secondaryHighlightColor
font.pixelSize:Theme.fontSizeMedium
text:root._details
}}}}