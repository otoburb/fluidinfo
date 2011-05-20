! Copyright (C) 2011 otoburb.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs base64 byte-arrays combinators 
hashtables http http.client json.reader json.writer kernel 
locals namespaces sequences strings urls ;

IN: fluidinfo

SYMBOL: auth-token 

: base64-auth ( username password --  )
    [ ":" append ] dip append >base64 >string auth-token set ;

SYMBOL: fluid-instance
CONSTANT: aws "http://ec2-184-72-128-158.compute-1.amazonaws.com:8080"
CONSTANT: main "http://fluiddb.fluidinfo.com"
CONSTANT: sandbox "http://sandbox.fluidinfo.com" 

! Low level REST API wrapper
<PRIVATE

: add-auth-header ( request -- request' )
   auth-token get 
   [ "Basic " prepend "Authorization" set-header ] when* ; 

: tidy-response ( server-response byte-payload -- json-payload ) 
    nip >string json> ;

: fluid-http-request ( request -- response data ) 
    add-auth-header http-request ;

: fluid-request ( request -- assoc ) 
    fluid-http-request tidy-response ;

ERROR: missing-fluid-instance ;

: fluid-url ( path -- url )
    fluid-instance get 
    dup string? [ missing-fluid-instance throw ] unless 
    prepend >url ;

: >json-post-data ( post-data string/assoc -- post-data' )
    >json >byte-array >>data ;

: single-json-payload ( value key -- post-data )
    associate "application/json" <post-data> swap
    >json-post-data ;

: bool>string ( ? -- str )
    { 
        { t [ "True" ] } 
        { f [ "False" ] }
        [ ] 
    } case ;

: boolean-string-substitute ( assoc -- assoc' )
    [ bool>string ] assoc-map ;

: fluid-response-ok? ( response data -- t/f )
    drop code>> 204 = ;

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

: /objects-get-by-query ( query-assoc -- response )
    "/objects/" fluid-url swap
    [ first2 swap set-query-param ] each
    <get-request> fluid-request ;

: /objects-get-by-id ( uri-arg-assoc id -- response )
    "/objects/" prepend fluid-url swap
    [ first2 swap set-query-param ] each
    <get-request> fluid-request ;

: /objects-get-tag-value ( tag -- response )  
    "/objects/" prepend fluid-url <get-request> fluid-request ; 

: /objects-head ( id+tag -- t/f )
    "/objects/" prepend fluid-url <head-request> fluid-http-request 
    fluid-response-ok? ; 
    
: /objects-put ( post-data id+tag -- response )
    "/objects/" prepend fluid-url <put-request> fluid-request ;

: /objects-delete ( id+tag -- t/f )
    "/objects/" prepend fluid-url <delete-request> fluid-http-request 
    fluid-response-ok? ;

: /tags-post ( post-data namespace -- response )
    "/tags/" prepend fluid-url <post-request> fluid-request ;

: /tags-get ( uri-arg-assoc tag -- response )
    swap [ "/tags/" prepend fluid-url ] dip
    boolean-string-substitute first first2 swap set-query-param 
    <get-request> fluid-request ;

 : /tags-put ( description tag -- t/f )
    "/tags/" prepend fluid-url swap
    "description" single-json-payload swap
    <put-request> fluid-http-request
    fluid-response-ok? ;

: /tags-delete ( namespace -- t/f )
    "/tags/" prepend fluid-url <delete-request>
    fluid-http-request fluid-response-ok? ; 

: /users-get ( username -- response )
    "/users/" prepend fluid-url <get-request> fluid-request ;

: /values-get ( uri-args-assoc -- response )
    "/values/" fluid-url swap 
    [ first2 swap set-query-param ] each 
    <get-request> fluid-request ;

: /values-put ( queries-post-data -- t/f )
    "/values/" fluid-url <put-request> fluid-http-request 
    fluid-response-ok? ;

: /values-delete ( uri-args-assoc -- t/f ) 
    "/values/" fluid-url swap
    [ first2 swap set-query-param ] each
    <delete-request> fluid-http-request
    fluid-response-ok? ; 

: /permissions-get ( action-str namespace|tags|tag-values -- response )
    "/permissions/" prepend fluid-url swap
    "action" set-query-param <get-request> fluid-request ;

: /permissions-put ( post-data action-str namespace|tags|tag-values -- response )
    "/permissions/" prepend fluid-url swap
    "action" set-query-param <put-request>
    fluid-http-request fluid-response-ok? ;

: /policies-get ( path -- response )
    "/policies/" prepend fluid-url <get-request> fluid-request ;

: /policies-put ( post-data path -- response )
    "/policies/" prepend fluid-url <put-request> 
    fluid-http-request fluid-response-ok? ;
