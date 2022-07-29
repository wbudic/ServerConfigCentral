#!/usr/bin/env perl
use warnings; use strict;
use lib "./tests";
use lib "./local";

require TestManager;
require CNFCentral;

my $test = TestManager -> new($0);

use Syntax::Keyword::Try; try{   

    ###
    # Test encryption.
    ###    
    my $text = "Hello Wolrd!"; 
    my $central =  CNFCentral-> new();
       $central->initCBC(checkGenerateSessionToken());
       my $ enc = $central -> encrypt($text);
       $test->subcase("enc -> [$enc]");
       my $ dec = $central -> decrypt($enc);       
       $test->subcase("dec -> [$dec]");
       $test->subcase(qq(sessionKey -> [$central->{'session_key'}]));
       
    die $test->failed() if not $text eq $dec;
    #

    #  
    $test-> nextCase();
    #

    # Test session token.
    die $test->failed() if not my $t =checkGenerateSessionToken();

    #
    $test-> nextCase();
    #

    #
    # Test session token to array
    #
    my @token = CNFCentral::sessionTokenToArray($t);
    die $test->failed() if @token !=2;
    $test->case("Token array contents -> [". join (', ', @token) . "]");
    $test-> nextCase();
    die &failed if !checkGenerateSessionToken("ABCssssssssssssssssssssssss28");  
    #
    
    #
    $test->done();
    #
}
catch{ 
   $test -> dumpTermination($@);
   $test->doneFailed();
}


#
#  TESTING THE FOLLOWING IS FROM HERE  #

###
# Test in general session token utility.
###
sub checkGenerateSessionToken {  my $pass = shift;        
    my $t =  CNFCentral::generateSessionToken($pass);    
    $test->case($t);
    die if length($t)<27;
    return $t;
}