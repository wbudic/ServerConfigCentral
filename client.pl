#!/usr/bin/env perl

use warnings; use strict; use Syntax::Keyword::Try;
use lib "./local";
use lib "/home/will/dev/ServerConfigCentral/local";
require CNFCentral;

my $central = CNFCentral -> client();
my $socket  = $central   -> {'socket'};
my ($cmd,$strip,$piped);



$socket->recv($cmd, 64);
print "Connected: $cmd" if $central->config()->{'$DEBUG'}; 
$cmd="";

foreach my $a (@ARGV){
    my $v = $a; $v =~ s/^-+.*[=:]//;
    if($a eq '-')            {$piped = <>;next}
    elsif($a =~ m/^-+c/i)    {issueCommand($v) if $a ne $v}
    elsif($a =~ m/^-+s/i)    {$strip =1;next}
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
        $socket -> close();    undef   $socket;
    }
    else{
           print "Error: Don't understand argument: [$a]\n"; exit 2;
    }    
    $socket  = $central   -> socketC() if !$socket;
}

if ($socket){
    $socket->send('end');
    $socket->close()
}

sub issueCommand { my ($cmd) = @_;
    print "IssueCommand -> $cmd\n" if $central->config()->{'$DEBUG'};
    my ($read, $token, $buffer) ="";
    try{ 

        if($cmd =~ m/^auth/){            
            my $c = 'auth';
            $socket->send($c."\0");
            $socket->recv($buffer, 1024);            
            print ("Recieved token: $buffer\n");
            $central->registerClientWithToken($socket, $buffer);
            $c = substr $cmd,5;
            $buffer ="";
            if($c=~/^load/){
               $socket->send($c."\0"); 
               $socket->recv($buffer, 1024);
               if($buffer =~ "<<load<send>>>"){
                  $central -> scrumbledReceive($socket);
                  return
               }else{
                  $socket->close();
                  print "ERROR: Server responded with: $buffer";
                  return;
               }
            }
            elsif($c=~/^save/){
                my $file = substr $c,5;
                if(-e $file){

                    $socket->send($c."\0");
                    $socket->recv($buffer, 1024);

                    if($buffer =~ "<<save<send>>>"){
                        open(my $fh, "<:perlio", $file ) or $buffer = undef;
                           read $fh, $buffer, -s $fh;
                        close   $fh;
                        $central -> scrumbledSend($socket, $buffer);                        
                        $socket->recv($buffer, 1024);
                        if($buffer =~ "<<save<send>>>"){
                            print "File has been successfully saved on server: $file"
                        }
                        else{
                            print "ERROR: Server responded with: $buffer";
                        }
                    }else{
                        $socket->close();
                            print "ERROR: Server responded with: $buffer";
                        return;
                    }

                }else{
                    $socket->close();
                            print "ERROR:$file not found!";
                    return;
                }

            }elsif($c=~/log/){
                
                if(length $c > 3 && $c =~ /^log add/){
                    $c = substr $c, 3; 
                    $c = substr $c, 4 if $c =~ /^ add/;
                    $socket->send("log add ".$ENV{USER});
                    $socket->recv($buffer, 1024);
                    
                    if($buffer =~ "<<log<send>>>"){
                        print "Sending: log $c ...";
                        if($c=~/\{\}$/){
                            if($piped){
                                ($c=~m/(.*)(\{\}$)/g);    
                                $piped = "$\n$piped" if $1;
                                $central->scrumbledSend($socket, $piped);
                            }else{
                                print "Warning - You didn't pipe in any log text.\n"
                            }
                        }else{
                           $central->scrumbledSend($socket, $c);
                        }
                        print "done\n";                        
                        $socket->recv($buffer, 1024);
                        print "Server response: $buffer","\n";                  
                        return;
                    }else{
                        print "ERROR: Server responded with: $buffer";
                        $socket->close();
                        return;
                    }
                }else{                    
                    $socket->send("$c");   
                    $buffer = $central -> scrumbledReceive($socket);
                    if($strip){
                                foreach(split(/\n/,$buffer)) {
                                    my @tag = $central-> tagCNFToArray($_);
                                    if(scalar @tag>1){
                                        $strip = $tag[2]; $strip =~ s/^\s*|\s*$//g;
                                        print "$tag[1] | $strip\n";
                                    }
                                }
                                return;    
                    }                 
                }               
            }
            else{            
                $socket->send($c."\0");
                $buffer="";
            }
        }else{
            $socket->send($cmd);
            while(sysread $socket, $read, 1024){ $buffer .= $read}
        }
        if($strip){     
                    foreach(split(/\n/,$buffer)) {
                        my @tag = $central-> tagCNFToArray($_);
                        if(scalar @tag>1){
                            $strip = $tag[2]; $strip =~ s/^\s*|\s*$//g;
                            print $strip;
                        }
                    }        
        }else{
            print "Recieved: $buffer\n";
        }
    }catch{
        print "Socket Error -> ".$@;
    }
    $socket->close()
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
-s                              - Strip CNF response tag, including header.
                                  Translates property output value only if placed before command.
--h -help_Me -? --help          - Prints this help. Perl trickery for the wickery.

Commands:

list {path}     - Lists contents from the servers <<CONST<<public_dir>> location. 
prp             - Obtain property value.
--------------------------------------------------------------------------------------------------------------