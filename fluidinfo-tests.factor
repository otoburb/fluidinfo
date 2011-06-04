USING: accessors assocs byte-arrays http http.client kernel 
fluidinfo fluidinfo.private multiline tools.test urls ; 

IN: fluidinfo.tests

! Test username and password for the Fluidinfo Factor library
"fluidinfo-factor" "ai3hs45kl2" base64-auth

[ T{ url
    { protocol "http" }
    { host "fluiddb.fluidinfo.com" }
    { path "/about/chewing-gum" } 
  }
] [ "/about/chewing-gum" >fluid-url ] unit-test

[ T{ url
    { protocol "http" }
    { host "abc.com" }
    { port 8080 }
    { path "/about/chewing-gum" }
    { query H{ { "tag" { "1" "2" } } { "query" "cond" } } }
  }
] [ "http://abc.com:8080/about/chewing-gum?query=cond&tag=1&tag=2" >fluid-url ]
unit-test


[ t ] [ 
    "/about/chewing-gum" >fluid-url 
    "about/chewing-gum" >fluid-url = 
] unit-test

[ t ] [ 
    URL" about/chewing-gum" >fluid-url 
    URL" /about/chewing-gum" >fluid-url = 
] unit-test

[ t ] [ 
    "/about/chewing-gum" >fluid-url 
    URL" about/chewing-gum" >fluid-url = 
] unit-test

[ T{ url
    { protocol "http" }
    { host "fluiddb.fluidinfo.com" }
    { path "/namespaces/fluidinfo-factor/foo" }
    { query H{  { "returnDescription" "True" }
                { "returnNamespaces" "True" }
                { "returnTags" "True" }
            } 
    }
  }
] 
[ 
    "/namespaces/fluidinfo-factor/foo" 
    H{  { "returnDescription" t } 
        { "returnNamespaces" t } 
        { "returnTags" "True" }
    }
    bool>string fluid-set-query-params
] unit-test 

! Live fire exercise
!   - assumes fluiddb.fluidinfo.com main instance is alive

! POST /about/aboutstr
[ 201 ] [
    "application/json" <post-data>
    "/about/chewing-gum" fluid-post
    drop code>> ] unit-test

! GET /about/aboutstr
[ "a44c8790-8853-441b-8b25-8849fc56c041" ] 
    [ "/about/chewing-gum" fluid-get nip "id" swap at ] unit-test

! GET /about/aboutstr/namespace1/namespace2/tag
[ 200 "chewing-gum" ] 
    [ "/about/chewing-gum/fluiddb/about" fluid-get [ code>> ] dip ] unit-test 

[ 200 "London" ] 
    [ "/about/London/fluiddb/about" fluid-get [ code>> ] dip ] unit-test 

! GET /about/aboutstr/ns1/ns2/tag w/ opaque value

! HEAD /about/aboutstr/ns1/ns2/tag
[ 200 "" ] 
    [ "/about/Toronto/fluiddb/about" fluid-head [ code>> ] dip ] unit-test

! PUT /about/aboutstr/ns1/ns2/tag w/ primitive value
[ 204 "" ] 
[   "application/vnd.fluiddb.value+json" <post-data>
    "true" >byte-array >>data 
    "/about/London/fluidinfo-factor/rating" fluid-put 
    [ code>> ] dip 
] unit-test

! PUT /about/aboutstr/ns1/ns2/tag w/ opaque value

! DELETE /about/aboutstr/ns1/ns2/tag 
[ 204 "" ] 
    [ "/about/London/fluidinfo-factor/rating" fluid-delete
    [ code>> ] dip ] unit-test

! POST /namespaces/namespace1/namespace2
[ 
    H{
        {
        "URI"
        "http://fluiddb.fluidinfo.com/namespaces/fluidinfo-factor/foo"
        }
        { "id" "997e04a5-3558-4bfe-a2e6-7d1eab9fac17" }
    } ]
    [   "application/json" <post-data> 
    H{ 
        { "description" "Foo description for a foo-ey namespace!" } 
        { "name" "foo" } } >json-post-data 
    "/namespaces/fluidinfo-factor" fluid-post 
] unit-test

! GET /namespaces/ns1/ns2
[ 200 "997e04a5-3558-4bfe-a2e6-7d1eab9fac17" ] 
[ "/namespaces/fluidinfo-factor/foo" fluid-get [ code>> ] dip "id" swap at ] unit-test

! PUT /namespaces/ns1/ns2
[ 204 "" ]
[ "application/json" <post-data>
    H{ 
        { "description" 
          "Updated description for namespace fluidinfo-factor/foo" } 
    } >json-post-data 
    "/namespaces/fluidinfo-factor/foo" fluid-put [ code>> ] dip ] 
] unit-test

! DELETE /namespaces/ns1/ns2
[ 204 "" ] [ "/namespaces/fluidinfo-factor/foo" fluid-delete 
    [ code>> ] dip ] unit-test

! POST /objects
[ 201 ] [ 
    "application/json" <post-data>
    H{ { "about" "about:fluidinfo-factor test object" } } >json-post-data
    "/objects" fluid-post drop code>> ] unit-test 

[ 201 ] [ 
    "application/json" <post-data>
    "/objects" fluid-post drop code>> ] unit-test

! GET /objects
[ 

/* {
    {
        "queries"
        {
            {
                "mike/rating > 5"
                H{
                    { "ntoll/seen" H{ { "value" t } } }
                    { "ntoll/rating" H{ { "value" 6 } } }
                }
            }
            {
                "fluiddb/about matches \"great\""
                H{ { "ntoll/rating" H{ { "value" 10 } } } }
            }
            {
                "fluiddb/id = \"6ed3e622-a6a6-4a7e-bb18-9d3440678851\""
                H{ { "mike/seen" H{ { "value" t } } } }
            }
        }
    }
}
*/
