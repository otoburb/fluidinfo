! Copyright (C) 2011 otoburb.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs base64 byte-arrays classes 
combinators debugger hashtables http http.client 
io io.encodings.string json.reader json.writer 
kernel locals make namespaces present prettyprint 
sequences strings urls ;

IN: fluidinfo

SYMBOL: fluid-auth 

: base64-auth ( username password --  )
    [ ":" append ] dip append >base64 >string fluid-auth set ;

SYMBOL: fluid-instance
CONSTANT: aws "http://ec2-184-72-128-158.compute-1.amazonaws.com:8080/"
CONSTANT: sandbox "http://sandbox.fluidinfo.com/" 
CONSTANT: main "http://fluiddb.fluidinfo.com/"
main fluid-instance set-global

! Low level REST API wrapper
<PRIVATE

: add-auth-header ( request -- request' )
   fluid-auth get 
   [ "Basic " prepend "Authorization" set-header ] when* ; 

ERROR: fluid-error response ;
M: fluid-error error.
    "Fluidinfo error (" write dup class pprint ")" print
    response>> [ code>> print ] [ message>> print ] bi ;

ERROR: fluid-bad-request < fluid-error ;
ERROR: fluid-not-found < fluid-error ;
ERROR: fluid-unauthorized < fluid-error ;
ERROR: fluid-not-acceptable < fluid-error ;
ERROR: fluid-precondition-failed < fluid-error ;
ERROR: fluid-entity-too-large < fluid-error ;

: fluid-check-response ( response -- response ) 
    dup code>> {
            { [ dup { 200 201 204 } member? ] [ drop ] } 
            { [ dup 400 = ] [ fluid-bad-request ] }
            { [ dup 401 = ] [ fluid-unauthorized ] }
            { [ dup 404 = ] [ fluid-not-found ] }
            { [ dup 406 = ] [ fluid-not-acceptable ] }
            { [ dup 412 = ] [ fluid-precondition-failed ] }
            { [ dup 413 = ] [ fluid-entity-too-large ] }
            [ fluid-error ] 
    } cond ;

: tidy-data ( data -- data' ) >string dup length 0 = [ json> ] unless ;
: tidy-response ( response data -- data' ) nip tidy-data ;

: fluid-check-response-with-body ( response body -- response body )
    [ >>body fluid-check-response ] keep ;

: (fluid-http-request) ( request -- response data )
    [ [ % ] with-http-request ] B{ } make
    over content-encoding>> decode fluid-check-response-with-body ;

: fluid-http-request ( request -- response data ) 
    add-auth-header http-request tidy-data ;

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

: (bool>string) ( ? -- str )
    { 
        { t [ "True" ] } 
        { f [ "False" ] }
        [ ] 
    } case ;

: bool>string ( assoc -- assoc' )
    [ (bool>string) ] assoc-map ;

: remove-leading-slash ( string -- string )
    dup first 1string "/" = [ 1 tail ] when ; 

: >fluid-url ( url -- url' ) 
    >url dup host>> 
    [ path>> fluid-instance get swap  
        remove-leading-slash url-append-path >url ] unless ; 

: fluid-set-query-params ( url/string params-hash -- url )
    [ >fluid-url ] dip bool>string >>query ;

PRIVATE>


: fluid-post ( post-data url -- response data ) 
    >fluid-url <post-request> fluid-http-request ;
: fluid-get ( url -- response data ) 
    >fluid-url <get-request> fluid-http-request ; 
: fluid-head ( url -- response data ) 
    >fluid-url <head-request> fluid-http-request ; 
: fluid-put ( post-data url -- response data ) 
    >fluid-url <put-request> fluid-http-request ;
: fluid-delete ( url -- response data ) 
    >fluid-url <delete-request> fluid-http-request ; 

