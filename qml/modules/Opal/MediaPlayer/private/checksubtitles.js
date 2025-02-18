//@ This file is part of opal-mediaplayer.
//@ https://github.com/Pretty-SFOS/opal-mediaplayer
//@ SPDX-FileCopyrightText: 2024 Mirian Margiani
//@ SPDX-FileCopyrightText: 2013-2020 Leszek Lesner
//@ SPDX-License-Identifier: GPL-3.0-or-later
WorkerScript.onMessage=function(message){var sub,text=[]
var a=message.subtitles,pos=message.position*1000
var ii,i0=0,i1=a.length
while(i1-i0>1){ii=(i0+i1)>>1
if(pos<a[ii].start){i1=ii
}else{i0=ii
}}if(typeof a[i0]!=="undefined"){while(i0>=0&&pos<=a[i0].end){i0--
}for(ii=i0+1;ii<i1;ii++){sub=a[ii]
if(sub.start<=pos){text.push(sub.text)
}}}WorkerScript.sendMessage(text.join("\n"))
}
