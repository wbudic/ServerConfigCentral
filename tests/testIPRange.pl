#!/usr/bin/env perl
use warnings; use strict; use Syntax::Keyword::Try; use Term::ANSIColor qw(:constants);

my $test=1;

try{
    die &failed if checkIPrange('192.168.0.1', '192.168.*.');   ++$test;
    die &failed if checkIPrange('192.168.0.1', '192.168.*.*')==0;  ++$test;
    # It will die if it reports not in range. Here it returns true or 1.
    die &failed if !checkIPrange('192.168.0.1', '*.*.*.*');  ++$test;
    # $bool as 1 is true anything other is false: following $bool should be true, as the ranging matches.
        my  $bool   = checkIPrange('192.168.1.20', '192.168.*.20'); 
        if(!$bool){die &failed}
        die &failed unless $bool || $bool == 0;
        ++$test;
    #
    # Range doesn't match should retun false or 0.                     
        die failed() if 1==checkIPrange('192.168.1.20', '192.*.*.21');     
        ++$test;
    #
    # Following should return false or 0 ip first range do not match.
    # The: unless checkIPrange('172.200.1.120', '192.*.*.*') tells die if sub is returning true.
    die failed() unless !checkIPrange('172.200.1.120', '192.*.*.*');
    ++$test;
    #
    print BOLD "All tests have ", BRIGHT_GREEN ,"PASSED",RESET," for test file:", RESET WHITE, " $0\n", RESET;
}
catch{
    my $failed = $@;
    print BOLD BRIGHT_RED "Test file failed $failed";
    my @parse = ($failed =~ m/.*\s*at\s*(.*)\sline\s*(\d*)\.$/);
    open (my $file, '<:perlio', $parse[0]) or die("Error $! opening file: $parse[0]");
    my ($coment, $past);
    while( my $line = <$file>)  {       
        if($. >= $parse[-1]){
           $line =~ s/^\s*//;
           print $coment, "\n", RESET; 
           print "[".$parse[0]."]\n\t".BRIGHT_RED."Failed\@Line".WHITE." $. -> $line".RESET;
           last  
        }elsif($line=~m/^\s*(\#.*)/){
            if( $1 eq '#' ){
                $past = 0 
            }
            elsif($past){
                $coment .= "\n".RESET."$.   ".ITALIC.YELLOW.$1 
            }
            else{
                $past = 1;$coment = RESET."$.   ".ITALIC.YELLOW.$1 
            }

        }elsif($past){
               $line=~s/^\s*//;
               chomp($line);
               $coment .= "\n".RESET."$.   ".$line; 
        }
    }
    close $file;
}

    sub failed {
        my $err=shift; $err="" if !$err;
        return BLINK.BRIGHT_RED."on test:$test $err",RESET 
    }


#  TESTING THE FOLLOWING IS FROM HERE  #

sub checkIPrange {
    my ($sip, $srange) = @_;
    my @ip = ($sip=~m/(\d*|\*)\.(\d*|\*)\.(\d*|\*)\.(\d*|\*)/);
    my @range = ($srange=~m/(\d*|\*)\.(\d*|\*)\.(\d*|\*)\.(\*|\d*)/);
    if(@ip==@range){        
        for(my $i=0;$i<@ip;$i++){
             next if $range[$i] eq '*';
             my $n = $range[$i]; 
                $n = 0 if !$n;
             if ($n!=$ip[$i]){
                return 0;
             }
        }
        return 1;
    }
    return 0;
}