#!/usr/bin/env perl
use warnings; use strict; 
use lib "./tests";
use lib "./local";

require TestManager;
require CNFCentral;

my $manager = TestManager->new($0);

use Syntax::Keyword::Try; try{
    ###
    # Test instance creation.
    #
    die $manager->failed()if not my $central = CNFCentral->new();
    $manager->case("Passed new instance CNFCentral.");
    #  
    $manager-> nextCase();
    #

    # Test session token.
    die $manager->failed()if not my $token = CNFCentral::generateSessionToken();   
    #
    $manager->case("Passed CNFCentral::generateSessionToken().");
    $manager-> nextCase();    
    #

    ###
    # Test tagCNFToArray from session token.    
    ###
    my @prop = $central->tagCNFToArray($token);
    die $manager->failed()if @prop != 3;
    @prop = $central->tagCNFToArray('<<name<value>>>');
    $manager->case(join '|', @prop);
    die $manager->failed()if @prop != 2;
    $manager->subcase("It equals to nb of elements.");
    die $manager->failed()if $prop[0] ne 'name' or $prop[1] ne 'value';
    $manager->subcase("And they equal 'name' and 'value'");
    
    #
    $manager-> nextCase();     
    #

    ###
    # Test static utility.
    #
    @prop = $central->sessionTokenToArray($token);
    $manager->case(join '|', @prop);
    die $manager->failed() if @prop != 2;
    #
    $manager-> nextCase(); 
    #

    ###
    # Test parse chain of server issued commands.
    #
    die $manager->failed()if not my @chain = $central->parseCmdChain("auth anon kurac='palac '");
    die $manager->failed()if not @chain == 4;
        $manager->case(join '|', @chain);    
    die $manager->failed()if not $chain[-1] eq "='palac '";
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