! Copyright (C) 2011 otoburb.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors base64 http http.client json.reader json.writer 
kernel locals namespaces sequences strings urls ;

IN: fluidinfo

SYMBOL: token 

: base64-token ( username password --  )
    [ ":" append ] dip append >base64 >string token set ;

: add-auth-header ( request -- request' )
   "Basic " token get append "Authorization" set-header ; 

CONSTANT: aws "http://ec2-184-72-128-158.compute-1.amazonaws.com:8080"
CONSTANT: main "http://fluiddb.fluidinfo.com"
CONSTANT: sandbox "http://sandbox.fluidinfo.com" 
SYMBOL: fluid-instance

! Low level REST API wrapper
<PRIVATE

: tidy-response ( server-response byte-payload -- json-payload ) 
    nip >string json> ;

: fluid-request ( request -- json-payload )
    add-auth-header http-request tidy-response ;

: fluid-url ( path -- url )
    fluid-instance get prepend >url ;

PRIVATE>

: /about-post ( about -- object-info )
    "/about/" prepend fluid-url  
    "application/json" <post-data> swap
    <post-request> fluid-request ;

: /about-get ( string -- response ) 
    "/about/" prepend fluid-url <get-request> fluid-request ;

: /about-head ( string -- response )
    "/about/" prepend fluid-url <head-request> fluid-request ;

: /about-put ( post-data about|tag -- response )
    "/about/" prepend fluid-url <put-request> fluid-request ;

: /about-delete ( about|tag -- response )
    "/about/" prepend fluid-url <delete-request> fluid-request ;

: /namespaces-post ( post-data namespace -- response )
    "/namespaces/" prepend fluid-url 
    <post-request> fluid-request ;

: /namespaces-get ( namespace uri-args -- response )
    " 
