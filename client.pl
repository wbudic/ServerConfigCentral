#!/usr/bin/env perl

use warnings; use strict;
use lib "./local";
require CNFCentral;


my $central = CNFCentral -> client();
my $socket  = $central   -> {'socket'};
my $cmd;

foreach my $a (@ARGV){
    my $v = $a; $v =~ s/^-+.*[=:]//;
    print "[$a] -> $v\n" if $central->config()->{'$DEBUG'};
    if($a =~ m/~/g){print "Error: Directory substitution is not permited.\n"; exit 2;} 
    elsif($a =~ m/^-+c/i)    {issueCommand($v) if $a ne $v}
    elsif($a =~ m/^-+p/i)    {$cmd = "prp "; $cmd = $cmd .$v  if $a ne $v}
    elsif($a =~ m/^-+h|\?/i) {&printHelp;}
    elsif($a !~ m/^-+/)      {
        if($cmd){
           $cmd = $cmd .' '. $v;
           issueCommand($cmd);
           $cmd = ""
        }else{
            issueCommand($a)
        }
    }
    else{
            print "Error: Don't understand argument: [$a]\n"; exit 2;
    }    
}

#$socket->send("list");
#$socket -> send("prp list sample1/PAGE");
sub issueCommand { my ($cmd, $buffer) = @_;
    $socket->send($cmd);
    do{
        $socket->recv($buffer, 1024);
        print $buffer;
    }while(length ($buffer)>0);
}

END{
$socket->close() if $central;
}
sub printHelp {while(<DATA>){print $_}return;}
__END__
--------------------------------------------------------------------------------------------------------------
Client For Perl CNF Central Server Interaction

This utility will connect and return command type output from an Perl CNF Server.
All settings needed for both client and server are in the local ./central.cnf file.
This file can also be placed into the ~./.config directory.

Options:

-c='{command}'' -c... -         - Command to issue.
-p=name {repository path}       - Fetches propery by name from an available repoistory config file.
./client.pl "{direct command}"  - Default behaviour is to issue command from the command line.
--h -help_Me -? --help          - Prints this help. Perl trickery for the wickery.

Commands:

list {path}     - Lists contents from the servers <<CONST<<public_dir>> location. 
prp             - Obtain property value.
--------------------------------------------------------------------------------------------------------------