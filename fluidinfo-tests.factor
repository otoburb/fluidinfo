USING: accessors assocs byte-arrays http http.client kernel 
fluidinfo fluidinfo.private multiline namespaces tools.test 
sequences urls json.writer ; 

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

! DELETE /about/aboutstr/ns1/ns2/tag 
[ 204 "" ] 
    [ "/about/London/fluidinfo-factor/rating" fluid-delete
    [ code>> ] dip ] unit-test

! POST /namespaces/namespace1/namespace2
[ 201 "http://fluiddb.fluidinfo.com/namespaces/fluidinfo-factor/foo" 
    "997e04a5-3558-4bfe-a2e6-7d1eab9fac17" ]
    [ H{ 
        { "description" "Foo description for a foo-ey namespace!" } 
        { "name" "foo" } } >json-post-data 
    "/namespaces/fluidinfo-factor" fluid-post 
    [ code>> ] dip [ "URI" swap at ] [ "id" swap at ] bi 
] unit-test

! GET /namespaces/ns1/ns2
[ 200 "997e04a5-3558-4bfe-a2e6-7d1eab9fac17" ] 
[ "/namespaces/fluidinfo-factor/foo" fluid-get [ code>> ] dip "id" swap at ] unit-test

! PUT /namespaces/ns1/ns2
[ 204 "" ]
[ 
    H{ 
        { "description" 
          "Updated description for namespace fluidinfo-factor/foo" } 
    } >json-post-data 
    "/namespaces/fluidinfo-factor/foo" fluid-put [ code>> ] dip ] unit-test

! DELETE /namespaces/ns1/ns2
[ 204 "" ] [ "/namespaces/fluidinfo-factor/foo" fluid-delete 
    [ code>> ] dip ] unit-test

! POST /objects
[ 201 ] [ 
    H{ { "about" "about:fluidinfo-factor test object" } } >json-post-data
    "/objects" fluid-post drop code>> ] unit-test 

[ 201 ] [ 
    "application/json" <post-data>
    "/objects" fluid-post drop code>> ] unit-test

! GET /objects
[ 200 ] [
    "/objects" H{ { "query" "fluiddb/about matches \"fluidinfo-factor\"" } } 
    fluid-set-query-params fluid-get drop code>> ] unit-test

! GET /objects/id
[ 200 "about:fluidinfo-factor test object" ] [
    "/objects/fde1f917-6c56-42f9-90da-9105828cc44a" 
    H{ { "showAbout" "True" } } fluid-set-query-params fluid-get 
    [ code>> ] [ "about" swap at ] bi* ] unit-test

! GET /objects/id/ns1/ns2/tag w/ primitive value
[ 200 "about:fluidinfo-factor test object" ] [
    "/objects/fde1f917-6c56-42f9-90da-9105828cc44a/fluiddb/about"
    fluid-get [ code>> ] dip ] unit-test

! HEAD /objects/id/ns1/ns2/tag
[ 200 ] [ 
        "/objects/fde1f917-6c56-42f9-90da-9105828cc44a/fluiddb/about"
        fluid-head drop code>> ] unit-test

! PUT /objects/id/ns1/ns2/tag w/ primitive values
[ 204 ] [ 
    "application/vnd.fluiddb.value+json" <post-data>
    "6" >byte-array >>data
    "/objects/fde1f917-6c56-42f9-90da-9105828cc44a/fluidinfo-factor/rating"
    fluid-put drop code>> ] unit-test 

! PUT /objects/id/ns1/ns2/tag w/ opaque data
[ 204 ] [ 
    "text/html" <post-data>
    "<p>This is a simple paragraph with HTML tags</p>" >byte-array >>data
    "/objects/fde1f917-6c56-42f9-90da-9105828cc44a/fluidinfo-factor/rating"
    fluid-put drop code>> ] unit-test 

! DELETE /objects/id/ns1/ns2/tag
[ 204 ] [ 
    "/objects/fde1f917-6c56-42f9-90da-9105828cc44a/fluidinfo-factor/rating"
    fluid-delete drop code>> ] unit-test

! GET /permissions/namespaces/ns1/ns2
[ 200 "open" ] [ 
    "/permissions/namespaces/fluidinfo-factor" 
    H{ { "action" "list" } } fluid-set-query-params
    fluid-get [ code>> ] [ "policy" swap at ] bi* ] unit-test

! GET /permissions/tag-values/ns1/ns2/tag
[ 200 "open" ] [ 
    "/permissions/tag-values/fluidinfo-factor/rating" 
    H{ { "action" "read" } } fluid-set-query-params
    fluid-get [ code>> ] [ "policy" swap at ] bi* ] unit-test

! PUT /permissions/namespaces/ns1/ns2
[ 204 "" ] [
    H{  { "exceptions" { "fluidinfo-factor" } } 
        { "policy" "closed" } } >json-post-data
    "/permissions/namespaces/fluidinfo-factor/permsfoo" 
    H{ { "action" "list" } } fluid-set-query-params
    fluid-put [ code>> ] dip ] unit-test

! PUT /permissions/tags/ns1/ns2/tag
[ 204 "" ] [
    H{  { "exceptions" { "fluidinfo-factor" } } 
        { "policy" "closed" } } >json-post-data
    "/permissions/tags/fluidinfo-factor/permsfoo/quz" 
    H{ { "action" "update" } } fluid-set-query-params
    fluid-put [ code>> ] dip ] unit-test

! PUT /permissions/tag-values/ns1/ns2/tag
[ 204 "" ] [
    H{  { "exceptions" { "fluidinfo-factor" } } 
        { "policy" "closed" } } >json-post-data
    "/permissions/tag-values/fluidinfo-factor/permsfoo/quz" 
    H{ { "action" "read" } } fluid-set-query-params
    fluid-put [ code>> ] dip ] unit-test

! GET /policies/username/category/action
[ 200 "closed" ] [ 
    "/policies/fluidinfo-factor/namespaces/create" fluid-get
    [ code>> ] [ "policy" swap at ] bi* ] unit-test

! PUT /policies/username/category/action
[ 204 "" ] [
    H{  { "exceptions" { "fluidinfo-factor" } } 
        { "policy" "closed" } } >json-post-data
    "/policies/fluidinfo-factor/namespaces/create" 
    fluid-put [ code>> ] dip ] unit-test

! POST /tags/ns1/ns2/tag
[ 201 ] [
    H{  { "description" "HI tag!" } 
        { "indexed" t }
        { "name" "hi" } } >json-post-data 
    "/tags/fluidinfo-factor" fluid-post drop code>> ] unit-test

! GET /tags/ns1/ns2/tag
[ 200 ] [ 
    "/tags/fluidinfo-factor/hi" 
    H{ { "returndescription" "true" } } fluid-set-query-params
    fluid-get drop code>> ] unit-test

[ 204 "" ] [
    H{ { "description" "Modified description of the HI tag :)" } }
    >json-post-data "/tags/fluidinfo-factor/hi"
    fluid-put [ code>> ] dip ] unit-test

! DELETE /tags/ns1/ns2/tag
[ 204 "" ] 
    [ "/tags/fluidinfo-factor/hi" fluid-delete [ code>> ] dip ] unit-test

! GET /users/username
[ 200 "Fluidinfo Factor Library" ] [ 
    "/users/fluidinfo-factor" fluid-get
    [ code>> ] [ "name" swap at ] bi* ] unit-test

! GET /values
[ 200  
H{
    {
        "results"
        H{
            {
                "id"
                H{
                    {
                        "7ed045bc-89dc-4f72-adb7-a5dc9a484861"
                        H{
                            {
                                "fluiddb/about"
                                H{
                                    {
                                        "value"
                                        "factorcode.org"
                                    }
                                }
                            }
                            {
                                "fluidinfo-factor/rating"
                                H{ { "value" 6 } }
                            }
                        }
                    }
                    {
                        "a1c3dea9-dde3-4dd6-9651-b1d682d5c0ff"
                        H{
                            {
                                "fluiddb/about"
                                H{ { "value" "Toronto" } }
                            }
                            {
                                "fluidinfo-factor/rating"
                                H{ { "value" 6 } }
                            }
                        }
                    }
                    {
                        "3d77462a-00d8-4495-ad4d-58b8851216c9"
                        H{
                            {
                                "fluiddb/about"
                                H{ { "value" "Vancouver" } }
                            }
                            {
                                "fluidinfo-factor/rating"
                                H{ { "value" 6 } }
                            }
                        }
                    }
                    {
                        "544ab4db-7629-443f-bd78-6577a60ab809"
                        H{
                            {
                                "fluiddb/about"
                                H{
                                    { "value" "New York City" }
                                }
                            }
                            {
                                "fluidinfo-factor/rating"
                                H{ { "value" 6 } }
                            }
                        }
                    }
                }
            }
        }
    }
}
 ] [
    "/values"
    H{
    { "query" "has fluidinfo-factor/visited" } 
    { "tag" { "fluidinfo-factor/rating" "fluiddb/about" } } } 
    fluid-set-query-params fluid-get [ code>> ] dip ] unit-test

! PUT /values
[ 204 ] [ 
    f jsvar-encode? 
    [ H{ { "queries" {
            { "has fluidinfo-factor/visited" 
              H{
                    { "fluidinfo-factor/seen" H{ { "value" t } } }
                    { "fluidinfo-factor/rating" H{ { "value" 6 } } }
               }
            }
            { "fluiddb/about matches \"great\""
              H{ 
                { "fluidinfo-factor/rating" H{ { "value" 10 } } } 
                { "fluidinfo-factor/liked" H{ { "value" t } } } }
            }
            { "fluiddb/id = \"6ed3e622-a6a6-4a7e-bb18-9d3440678851\""
              H{ { "fluidinfo-factor/seen" H{ { "value" t } } } }
            }
        } } } >json-post-data ] with-variable 
   "/values" fluid-put drop code>> ] unit-test 

! DELETE /values
[ 204 ] [
    "/values" H{ 
        { "query" "fluidinfo-factor/rating>5" }
        { "tag" { "fluidinfo-factor/rating" "fluidinfo-factor/liked" }
    } } fluid-set-query-params fluid-delete drop code>> ] unit-test

! End of live-fire exercise
