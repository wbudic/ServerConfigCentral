#!/usr/bin/env perl
use warnings; use strict; use Syntax::Keyword::Try; use Term::ANSIColor qw(:constants);
use lib "./tests";
use lib "./local";
require TestManager;
require CNFCentral;

my $manager = TestManager->new($0);

try{ 

    ###
    # Test instance creation.
    #
    die $manager->failed()if not my $central = CNFCentral->new();
    $manager->case("Passed new instance CNFCentral.");
    #  
    $manager-> nextCase();
    ###
    # Test session token.
    #
    die $manager->failed()if not my $token = CNFCentral::generateSessionToken();   
    #
    $manager->case("Passed CNFCentral::generateSessionToken().");
    $manager-> nextCase();    
    ###
    # Test tagCNFToArray from session token.
    #
    my @prop = $central->tagCNFToArray($token);
    die $manager->failed()if @prop != 3;
    @prop = $central->tagCNFToArray('<<name<value>>>');
    $manager->case(join '|', @prop);
    die $manager->failed()if @prop != 2;
    $manager->subcase("It equals to elements.");
    die $manager->failed()if $prop[0] ne 'name' or $prop[1] ne 'value';
    $manager->subcase("And they equal 'name' and 'value'");
    #
    $manager-> nextCase(); 
    ##
    #Test static utility.
    #
    @prop = $central->sessionTokenToArray($token);
    $manager->case(join '|', @prop);
    die $manager->failed() if @prop != 2;
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