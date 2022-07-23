#!/usr/bin/env perl
use v5.12;
use warnings; use strict; use Syntax::Keyword::Try; use Term::ANSIColor qw(:constants);
use lib "./tests";
use lib "./local";
use lib "/home/will/dev/ServerConfigCentral/tests";
require TestManager;

###
#  Notice All test are to be run from the project directory.
#  Not in the test directory.
#  i.e.: perl ./tests/testAll.pl
###

my $manager = TestManager->new();
try{
    opendir my($dh), './tests' or die "Couldn't open dir: $!";
    my @files = grep { !/^\./ && /\.pl$/ && -f "./tests/$_" } readdir($dh);
    my $tests;
    foreach my $file(@files) {        
        if($0 !~ m/$file$/){ 
           $file = "./tests/$file";            
            print `perl $file`;
            $tests++;
        }
    }
    closedir $dh;
    if($tests){
        print BOLD "All tests ($tests) have ", BRIGHT_GREEN ,"PASSED",RESET," for test run:", RESET WHITE, " $0\n", RESET;
    }else{
        print BOLD BRIGHT_RED, "No tests have been run or found!", RESET WHITE, " $0\n", RESET;
    }
}
catch{ 
   $manager -> dumpTermination($@)
}



