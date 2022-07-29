#!/usr/bin/env perl
use warnings; use strict; 
use lib "./tests";
use lib "./local";

require TestManager;
require CNFCentral;

my $test = TestManager -> new($0);

use Syntax::Keyword::Try; try{
    ###
    # Test instance creation.
    #
    die $test->failed() if not my $central = CNFCentral->new();
    $test->case("Passed new instance CNFCentral.");
    #  
    $test-> nextCase();
    #

    # Test session token.
    die $test->failed()if not my $token = CNFCentral::generateSessionToken();   
    #
    $test->case("Passed CNFCentral::generateSessionToken().");
    $test-> nextCase();    
    #

    ###
    # Test tagCNFToArray from session token.    
    ###
    my @prop = $central->tagCNFToArray($token);
    die $test->failed()if @prop != 3;
    @prop = $central->tagCNFToArray('<<name<value>>>');
    $test->case(join '|', @prop);
    die $test->failed()if @prop != 2;
    $test->subcase("It equals to nb of elements.");
    die $test->failed()if $prop[0] ne 'name' or $prop[1] ne 'value';
    $test->subcase("And they equal 'name' and 'value'");
    
    #
    $test-> nextCase();     
    #

    ###
    # Test static utility.
    #
    @prop = $central->sessionTokenToArray($token);
    $test->case(join '|', @prop);
    die $test->failed() if @prop != 2;
    #
    $test-> nextCase(); 
    #

    ###
    # Test parse chain of server issued commands.
    #
    die $test->failed()if not my @chain = $central->parseCmdChain("auth anon kurac='palac '");
    die $test->failed()if not @chain == 4;
        $test->case(join '|', @chain);    
    die $test->failed()if not $chain[-1] eq "='palac '";
    #

    #   
    $test->done();    
    #
}
catch{ 
   $test -> dumpTermination($@);   
   $test -> doneFailed();
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