#!/usr/bin/env perl
use warnings; use strict; 
use lib "./tests";
use lib "./local";

require TestManager;
require CNFParser;

my $manager = TestManager->new($0);

use Syntax::Keyword::Try; try {

    ###
    # Test instance creation.
    ###
    die $manager->failed()  if not my $cnf = CNFParser->new();
    $manager->case("Passed new instance for CNFParser.");
    #

    #  
    $manager-> nextCase();
    #

    ###
    # Test parsing HTML tags in value.
    ###
    $cnf->parse(undef,"<<tag1<CONST><HTML></HTML>>>");
    die $manager->failed()  if not $cnf->{tag1}  eq '<HTML></HTML>';
    $manager->case($cnf->{tag1});
    #

    #
    $manager-> nextCase();
    #

    ###
    # Parser will ignore if a previous constance tag1 is tried to be parsed again, this is an feature.
    # So let's do tag2.
    ###
    $cnf->parse(undef,q(<<tag2<CONST>
    <HTML>something</HTML>
    >>));
    my $tag2 = $cnf->{tag2}; $tag2 =~ s/^\s*|\s*$//g; #<- trim spaces.
    $manager->case($tag2);
    die $manager->failed()  if not $tag2  eq '<HTML>something</HTML>';
    #

    #
    $manager-> nextCase();
    #

    ###
    # Test central.cnf
    #
    ###
    die $manager->failed()  if not  $cnf = CNFParser->new('central.cnf');+
    $manager->case($cnf);
    $manager->subcase("\$DEBUG=$cnf->{'$DEBUG'}");
    # CNF Constances can't be modifed anymore, let's test.
    try{
        $cnf->{'$DEBUG'}= 'false'
    }catch{
        $manager->subcase("Passed keep constant test for \$cnf->\$DEBUG=$cnf->{'$DEBUG'}");
    }

    #
    $manager->done();
    #
}
catch{ 
   $manager -> dumpTermination($@);   
   $manager->doneFailed();
}


