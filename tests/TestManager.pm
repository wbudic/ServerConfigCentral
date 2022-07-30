#!/usr/bin/env perl
package TestManager;
use warnings; use strict;
use Term::ANSIColor qw(:constants);

###
#  Notice All test are to be run from the project directory.
#  Not in the test directory.
###
sub new {
     my ($class, $test_file, $self) = @_; 
     $test_file = $0 if not $test_file;
     $self = bless {test_file=> $test_file,test_cnt=>1}, $class;
     print  BLUE."Running -> ".WHITE."$test_file\n".RESET;
     return $self;
}

sub failed {
    my ($self, $err) = @_; 
    $err="" if !$err;
    return BLINK. BRIGHT_RED. " on test: ".$self->{test_cnt}." -> $err". RESET
}

sub case { 
    my ($self, $out) =@_;
    print BRIGHT_CYAN,"\tCase ".$self->{test_cnt}.": $out\n".RESET
}
sub subcase {
    my ($self, $out) =@_;
    my $sub_cnt = ++$self->{sub_cnt};
    print GREEN."\t   Case ".$self->{test_cnt}.".$sub_cnt: $out\n".RESET
}

sub nextCase {
    my ($self) =@_;
    $self->{test_cnt}++;
    $self->{sub_cnt}=0
}

sub done {
    my ($self) =@_;
    print BOLD "Test cases ($self->{test_cnt}) have ", BRIGHT_GREEN ,"PASSED",RESET," for test file:", RESET WHITE, " .$self->{test_file}\n", RESET;
    print $self->{test_cnt}."|SUCCESS|".$self->{test_file},"\n"    
}
sub doneFailed {
    my ($self) =@_;
    print $self->{test_cnt}."|FAILED|".$self->{test_file},"\n"
}

###
# Following routine is custom made by Will Budic. 
# The pattern it seeks is like this comment in source file.
# To display code where error occured.
###
sub dumpTermination {
    my ($failed, $comment, $past, $cterminated) = @_;
    if(ref($comment) =~ /Exception$/){
        $comment = $comment->{'message'};
    }
    my ($file,$lnErr) = ($comment =~ m/.*\s*at\s*(.*)\sline\s*(\d*)\.$/); 
    
    # if(!$file){
    #     $file = $0;
    #     $lnErr= 0; print $comment;
    # }
    open (my $flh, '<:perlio', $file) or die("Error $! opening file: $file");
          my @slurp = <$flh>;
    close $flh;
    print BOLD BRIGHT_RED "Test file failed -> $comment";
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