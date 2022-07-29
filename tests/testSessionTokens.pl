#!/usr/bin/env perl
use warnings; use strict;
use lib "./tests";
use lib "./local";

require TestManager;
require CNFCentral;

my $manager = TestManager->new($0);

use Syntax::Keyword::Try; try{   

    ###
    # Test encryption.
    ###    
    my $text = "Hello Wolrd!"; 
    my $central =  CNFCentral-> new();
       $central->initCBC(checkGenerateSessionToken());
       my $ enc = $central -> encrypt($text);
       $manager->subcase("enc -> [$enc]");
       my $ dec = $central -> decrypt($enc);       
       $manager->subcase("dec -> [$dec]");
       $manager->subcase(qq(sessionKey -> [$central->{'session_key'}]));
       
    die $manager->failed() if not $text eq $dec;
    #

    #  
    $manager-> nextCase();
    #

    # Test session token.
    die $manager->failed() if not my $t =checkGenerateSessionToken();

    #
    $manager-> nextCase();
    #
    
    #
    # Test session token to array
    #
    my @token = CNFCentral::sessionTokenToArray($t);
    die $manager->failed() if @token !=2;
    $manager->case("Token array contents -> [". join (', ', @token) . "]");
    $manager-> nextCase();
    die &failed if !checkGenerateSessionToken("ABCssssssssssssssssssssssss28");  
    #
    
    #
    $manager->done();
    #
}
catch{ 
   $manager -> dumpTermination($@);
   $manager->doneFailed();
}


#
#  TESTING THE FOLLOWING IS FROM HERE  #

###
# Test in general session token utility.
###
sub checkGenerateSessionToken {  my $pass = shift;        
    my $t =  CNFCentral::generateSessionToken($pass);    
    $manager->case($t);
    die if length($t)<27;
    return $t;
}