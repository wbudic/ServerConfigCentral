#!/usr/bin/env perl
use v5.12;
use warnings; use strict; 
use Syntax::Keyword::Try;
use Term::ANSIColor qw(:constants);
use lib "./tests";
use lib "./local";
use lib "/home/will/dev/ServerConfigCentral/tests";
require TestManager;

use IPC::Run qw( run timeout );
###
#  Notice All test are to be run from the project directory.
#  Not in the test directory.
#  i.e.: perl ./tests/testAll.pl
###
print '-'x100, "\n";
my $manager = TestManager->new();
print '-'x100, "\n";
try{
    opendir my($dh), './tests' or die "Couldn't open dir: $!";
    my @files = grep { !/^\./ && /\.pl$/ && -f "./tests/$_" } readdir($dh);
    closedir $dh;

    my ($test_pass, $test_fail, $test_cases, @OUT, %WARN);
    
    foreach my $file(@files) {        
        if($0 !~ m/$file$/){ 
            $file = "./tests/$file";            
            my ($in,$output, $warnings);
            my @perl = ('/usr/bin/env','perl',$file);            
            run  (\@perl, \$in, \$output, '2>>', \$warnings);            
            my @test_ret = $output=~m/(\d*)\|(.*)\|($file)$/g;
            $output=~s/\d*\|.*\|$file\s$//g;
            push @OUT, $output;
             if ($warnings){
                for(split "\n", $warnings){
                    $WARN{$_} = $file;
                }
            }
            if($test_ret[1] eq 'SUCCESS'){
                $test_pass++;                
            }else{
                $test_fail++;
            }
            #This is actually global test cases pass before sequently hitting an fail.
            $test_cases+=$test_ret[0];
        }
    }
    foreach(@OUT){        
            print $_;        
    }
    print '-'x100, "\n";
    if($test_fail){
        print BOLD BRIGHT_RED, "HALT! Not all test have passed!\n",BLUE,
        "\tFailed test file count: ", BOLD RED,"$test_fail\n",BLUE,
        "\tPassed test count: $test_pass\n",
        "\tNumber of test cases run: $test_cases\n",
        WHITE, "Finished with test Suit ->$0\n", RESET;

    }elsif($test_pass){
        print BOLD "All tests ($test_pass) having ($test_cases) cases, have ", BRIGHT_GREEN ,"PASSED",RESET," for test run:", RESET WHITE, " $0\n", RESET;
    }else{
        print BOLD BRIGHT_RED, "No tests have been run or found!", RESET WHITE, " $0\n", RESET;
    }
    if(%WARN){
        print BOLD YELLOW, "Buddy, you got some Perl Issues with me:\n",BLUE;
        foreach(keys %WARN){        
            print "In file:  $WARN{$_}\n",$_."\n";        
        }
        print RESET;
    }
    print '-'x100, "\n";
}
catch{ 
   $manager -> dumpTermination($@)
}
