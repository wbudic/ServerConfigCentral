#!/usr/bin/env perl
use v5.12;
use warnings; use strict; use Syntax::Keyword::Try; use Term::ANSIColor qw(:constants);
my $test;
try{
    opendir my($dh), './tests' or die "Couldn't open dir: $!";
    my @files = grep { !/^\./ && -f "./tests/$_" } readdir($dh);
    foreach my $file(@files) {        
        if($0 !~ m/$file$/){ 
           $file = "./tests/$file";
            print "Testing $file\n";
            print `perl $file`
        }
    }
    closedir $dh;
    print BOLD "All tests have ", BRIGHT_GREEN ,"PASSED",RESET," for test file:", RESET WHITE, " $0\n", RESET;
}
catch{ 
    ###
    # Following routine is custom made by Will Budic. 
    # The pattern it seeks is like this comment in source file.
    # To display code where error occured.
    ###
    my ($failed, $comment, $past, $cterminated) = $@;        
    my ($file,$lnErr) = ($failed =~ m/.*\s*at\s*(.*)\sline\s*(\d*)\.$/);    
    open (my $flh, '<:perlio', $1) or die("Error $! opening file: $1");
          my @slurp = <$flh>;
    close $flh;
    print BOLD BRIGHT_RED "Test file failed $failed";
    our $DEC = "%0".(length($slurp[-1]) + 1)."d   ";
    for(my $i=0; $i<@slurp;$i++)  { 
        local $. = $i + 1;
        my $line = $slurp[$i]; 
        if($. >= $lnErr+1){                  
           print $comment, RESET.frmln($.).$line;
           print "[".$file."]\n\t".BRIGHT_RED."Failed\@Line".WHITE." $i -> ", $slurp[$i-1].RESET;
           last  
        }elsif($line=~m/^\s*(\#.*)/){
            if( $1 eq '#'){
                $comment .= "\n".RESET.frmln($.).ITALIC.YELLOW.'#' ;
                $past = $cterminated = 0 
            }
            elsif($past){
                $_=$1."\n"; $comment = "" if $cterminated && $1=~m/^\s*\#\#\#/;
                $comment .= RESET.frmln($.).ITALIC.YELLOW.$_;
                $cterminated = 0;
            }
            else{                
                $comment = RESET.frmln($.).ITALIC.YELLOW.$1."\n"; 
                $past = $cterminated = 1                
            }
        }elsif($past){
               $line= $slurp[$i];
               $comment .= RESET.frmln($.).$line; 
        }
    }
}
    our $DEC =  "%-2d %s"; #under 100 lines pad like -> printf "%2d %s", $.
    sub frmln { my($at)=@_;
       return sprintf($DEC,$at)
    }

    sub failed {
        my $err=shift; $err="" if !$err;
        return BLINK.BRIGHT_RED."on test:$test $err",RESET 
    }


