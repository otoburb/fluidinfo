! Copyright (C) 2011 otoburb.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors assocs base64 byte-arrays classes 
combinators debugger hashtables http http.client 
io json.reader json.writer kernel locals 
namespaces prettyprint sequences strings urls ;

IN: fluidinfo

SYMBOL: auth-token 

: base64-auth ( username password --  )
    [ ":" append ] dip append >base64 >string auth-token set ;

SYMBOL: fluid-instance
CONSTANT: aws "ec2-184-72-128-158.compute-1.amazonaws.com:8080"
CONSTANT: sandbox "sandbox.fluidinfo.com" 
CONSTANT: main "fluiddb.fluidinfo.com"
main fluid-instance set-global

! Low level REST API wrapper
<PRIVATE

: add-auth-header ( request -- request' )
   auth-token get 
   [ "Basic " prepend "Authorization" set-header ] when* ; 

: tidy-data ( data -- data' ) >string json> ;
: tidy-response ( response data -- data' ) nip tidy-data ;

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

: ensure-fluid-hostname ( url -- url ) 
    >url dup host>> [ fluid-instance get >>host "http" >>protocol ] unless ;

GENERIC: >fluid-url ( object -- url )
M: string >fluid-url ensure-fluid-hostname ;
M: url >fluid-url ensure-fluid-hostname ;

: set-query-params ( url/string params-hash -- url )
    [ >fluid-url ] dip [ swap set-query-param ] assoc-each ;

PRIVATE>

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

: check-response ( response -- ) 
    dup code>> {
            { [ dup { 200 201 204 } member? ] [ 2drop ] } 
            { [ dup 400 = ] [ drop fluid-bad-request ] }
            { [ dup 401 = ] [ drop fluid-unauthorized ] }
            { [ dup 404 = ] [ drop fluid-not-found ] }
            { [ dup 406 = ] [ drop fluid-not-acceptable ] }
            { [ dup 412 = ] [ drop fluid-precondition-failed ] }
            { [ dup 413 = ] [ drop fluid-entity-too-large ] }
            [ drop fluid-error ] 
    } cond ;

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

