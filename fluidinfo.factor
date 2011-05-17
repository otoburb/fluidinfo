! Copyright (C) 2011 otoburb.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors base64 byte-arrays hashtables http http.client 
json.reader json.writer kernel locals namespaces 
sequences strings urls ;

IN: fluidinfo

SYMBOL: auth-token 

: base64-auth ( username password --  )
    [ ":" append ] dip append >base64 >string auth-token set ;

: add-auth-header ( request -- request' )
   "Basic " auth-token get append "Authorization" set-header ; 

SYMBOL: fluid-instance
CONSTANT: aws "http://ec2-184-72-128-158.compute-1.amazonaws.com:8080"
CONSTANT: main "http://fluiddb.fluidinfo.com"
CONSTANT: sandbox "http://sandbox.fluidinfo.com" 

! Low level REST API wrapper
<PRIVATE

: tidy-response ( server-response byte-payload -- json-payload ) 
    nip >string json> ;

: fluid-http-request ( request -- response data ) 
    add-auth-header http-request ;

: fluid-request ( request -- assoc ) 
    fluid-http-request tidy-response ;

: fluid-url ( path -- url )
    fluid-instance get prepend >url ;

: >json-post-data ( string/assoc post-data -- post-data' )
    >json >byte-array >>data ;

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

: /namespaces-get ( uri-args-assoc namespace -- response ) 
    swap [ "/namespaces/" prepend fluid-url ] dip  
    [ first2 swap set-query-param ] each
    <get-request> fluid-request ;

: /namespaces-put ( description namespace -- response )
    "/namespaces/" prepend fluid-url swap
    [ "application/json" <post-data> ] dip
    "description" associate >json-post-data swap
    <put-request> fluid-request ;

: /namespaces-delete ( namespace -- response )
    "/namespaces/" prepend fluid-url <delete-request> fluid-request ;

: /objects-post ( about -- object-info )
    "/objects/" fluid-url swap
    [ "application/json" <post-data> ] dip 
    "about" associate >json-post-data swap
    <post-request> fluid-request ;

: /objects-get ( query|id|id+tag -- response )
    "/objects/" prepend fluid-url <get-request> fluid-request ; 

: /objects-head ( id+tag -- t/f )
    "/objects/" prepend fluid-url <head-request> fluid-http-request drop
    code>> 200 = ; 
    
: /objects-put ( post-data id+tag -- response )
    "/objects/" prepend fluid-url <put-request> fluid-request ;

: /objects-delete ( id+tag -- t/f )
    "/objects/" prepend fluid-url <delete-request> fluid-http-request drop
    code>> 204 = ;


