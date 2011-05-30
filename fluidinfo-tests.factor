USING: fluidinfo urls ; 

IN: fluidinfo.tests
 
[ T{ url
    { protocol "http" }
    { host "fluiddb.fluidinfo.com" }
    { path "/about/chewing-gum" } 
  }
] [ "/about/chewing-gum" >fluid-url ] unit-test


! Live fire exercise
!   - assumes fluiddb.fluidinfo.com main instance is alive
[ 201 ] [
    "application/json" <post-data>
    "/about/chewing-gum" fluid-post
    drop code>> ] unit-test

[ "a44c8790-8853-441b-8b25-8849fc56c041" ] [
    "/about/chewing-gum" fluid-get nip "id" swap at ] unit-test

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
