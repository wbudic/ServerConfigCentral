#!/usr/bin/env perl
use warnings; use strict; use Syntax::Keyword::Try; use Term::ANSIColor qw(:constants);
use lib "./tests";
use lib "./local";
require TestManager;
require CNFCentral;

my $manager = TestManager->new($0);

try{   

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
       
    die &failed if not $text eq $dec;
    #  

    # Test session token.
    die &failed if not my $t =checkGenerateSessionToken();   
    $manager-> nextCase();
    my @token = CNFCentral::sessionTokenToArray($t);
    die &failed if @token !=2;
    $manager->case("Token array contents -> [". join (', ', @token) . "]");
    $manager-> nextCase();
    die &failed if !checkGenerateSessionToken("ABCssssssssssssssssssssssss28");  
    #
    print BOLD "Test cases have ", BRIGHT_GREEN ,"PASSED",RESET," for test file:", RESET WHITE, " $0\n", RESET;
}
catch{ 
   $manager -> dumpTermination($@)
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