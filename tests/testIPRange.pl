#!/usr/bin/env perl
use warnings; use strict; use Syntax::Keyword::Try; use Term::ANSIColor qw(:constants);
use lib "./tests";
use lib "./local";
require TestManager;

my $manager = TestManager->new($0);
try{
    #
    # Test common encounters.
    die &failed if checkIPrange('192.168.0.1', '192.168.*.')==1;  $manager-> nextCase();
    die &failed if checkIPrange('192.168.0.1', '192.168.*.*')==0; $manager-> nextCase();
    die &failed if checkIPrange('192.168.0.1', '192.167.*.');  $manager-> nextCase();
    die &failed if checkIPrange('192.168.0.1', '192.167.*.*');  $manager-> nextCase();
    die &failed if !checkIPrange('192.168.0.1', '192.168.*.*');  $manager-> nextCase();
    # It will die if it reports not in range. Here it returns true or 1.
    die &failed if !checkIPrange('192.168.0.1', '*.*.*.*'); $manager-> nextCase();
    # $bool as 1 is true anything other is false: following $bool should be true, as the ranging matches.
        my  $bool   = checkIPrange('192.168.1.20', '192.168.*.20'); 
        if(!$bool){die &failed}
        die &failed unless $bool || $bool == 0;
       $manager-> nextCase();
    #
    # Range doesn't match should retun false or 0.                     
        die failed() if 1==checkIPrange('192.168.1.20', '192.*.*.21');     
    $manager-> nextCase();
    #
    # Following should return false or 0 ip first range do not match.
    # The: unless checkIPrange('172.200.1.120', '192.*.*.*') tells die if sub is returning true.
        die failed() unless !checkIPrange('172.200.1.120', '192.*.*.*');
    #
    print BOLD "Test cases have ", BRIGHT_GREEN ,"PASSED",RESET," for test file:", RESET WHITE, " $0\n", RESET;  
    $manager->done();  
}
catch{ 
   $manager -> dumpTermination($@);
   $manager->doneFailed();
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