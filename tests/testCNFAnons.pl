#!/usr/bin/env perl
use warnings; use strict; 
use lib "./tests";
use lib "./local";

require TestManager;
require CNFCentral;
use Syntax::Keyword::Try;


my $test = TestManager -> new($0);
my $cnf;

try{

    

   ###
   # Test instance creation.
   #
   die $test->failed() if not $cnf = CNFParser->new();
   $test->case("Passed new instance CNFParser.");
   #  
   $test-> nextCase();
   #

   my $anons = $cnf->anon();
   die $test->failed() if %$anons; #The list is empty so far.
   $test->case("Obtained anons for repo.");
   #  
   $test-> nextCase();
   #
   $anons->{'The Added One'} = "Dynamically!";
   $cnf->anon()->{'The Added Two'} = "Dynamically2!";
   #  
   my $added = $cnf->anon('The Added One');
   $test->case("Added 'The Added One' ->$added");
   $test-> nextCase();
   die $test->failed() if not $added = $cnf->anon('The Added Two');
   $test->case("Added 'The Added Two' ->$added");   
   #

   #  
   $test-> nextCase();
   #

   ###
   # Anons are global by default.
   ###
   my $cnf2 = CNFParser->new();
   $added = $cnf2->anon('The Added Two');
   die $test->failed() if $cnf->anon('The Added Two') ne $cnf2->anon('The Added Two');
   $test->case("Contains shared 'The Added Two' ->$added");
   $test->subcase(CNFParser::anon('The Added One'));
   
   #  
   $test-> nextCase();
   #

   ###
   # Make anon's private for this one.
   ###
   my $cnf3 = CNFParser->new(undef,{ANONS_ARE_PUBLIC=>0});
   $added = $cnf3->anon('The Added Two');   
   die $test->failed() if $cnf3->anon('The Added Two');
   die $test->failed($cnf->anon('The Added Two')) if not $cnf->anon('The Added Two');
   $test->case("Doesn't contain a shared 'The Added Two'");
   $cnf3->anon()->{'The Added Three'} = "I am private Anon!";
   $test->subcase("It worked 'The Added Three = '".$cnf3->anon('The Added Three') );

   die $test->failed("main \$cnf contains:".$cnf->anon('The Added Three')) if  $cnf->anon('The Added Three');
   die $test->failed(    $cnf3 -> anon('The Added Three') ) if  $cnf3->anon('The Added Three') ne 'I am private Anon!';
 
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
#