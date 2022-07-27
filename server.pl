#!/usr/bin/env perl

# To open port on linux:
# sudo ufw allow perl-cnf
# Which is set/found in /etc/services
# perl-cnf	1028/tcp			# PerlCnf server port.
use warnings; use strict; use Syntax::Keyword::Try;
use lib "./local";
require CNFCentral;

my $central = CNFCentral -> server();
my $cnf     = $central   -> {'parser'};
my $server  = $central   -> {'socket'};   

# my $cnf  = CNFParser->new("central.cnf",{Domain => AF_INET, Type => SOCK_STREAM, Proto=>'tcp'});
# my $server = IO::Socket->new(%$cnf)  or die "Cannot open socket - $IO::Socket::errstr\n";
$central->loadConfigs();
while(1) {
    COMM: print " Server is listenning...\n";
    if(my $client = $server->accept()) {

        my ($cmd,$rl,$client_address,$client_port);
        $client_address = $client->peerhost();
        $client_port = $client->peerport();
        my $host_hdr = `hostname`. scalar localtime; 
        $host_hdr =~ s/\n/:/g;
        $client->send("<<header<$host_hdr>>>\n");
        
        
        print "Connection from: $client_address ($client_port)\n";
             
            my $read = $cmd= "";            
            # while(sysread $client, $read, 1024){ print '.';
            #     $cmd .= $read;            
            # }
            $client->recv($cmd,1024);
            print "Received cmd: $cmd\n" if $cmd;
            if(    $cmd =~ /^list/ )    {list($client,$cmd)}
            elsif( $cmd =~ /^auth/ )    {auth($client,$cmd)}
            elsif( $cmd =~ /^prp/ )     {property($client, $cmd)} 
            elsif( $cmd =~ /^end/)      {$client->close(); 
                                         print "Connection ended: $client_address($client_port)\n";
                                         goto COMM
            }elsif($cmd){
                $client->send("<<error<$cmd>Command not known to server!>>");
            }

        
        print "Socket closed: $client_address($client_port)\n";
    }
}

$server->close();

sub auth {
    my ($client, $cmd)= @_;
    my $client_id = $client->peerport();
    my $token = CNFCentral::generateSessionToken();
    $central->{$client_id} = CNFCentral::sessionTokenToArray($token);
    $client->send($token);    
    print "Send token: $token\n";
}

sub property {
    my ($client, $cmd)= @_;
    my ($name,$value,$path,$rep,$process);    
    my $pub  = $cnf->{public_dir}; $cmd =~ /.*\s+(.*\.*.*)/;    
    my $cip = $client->peerhost();
    $path = $1; 
    print qq(Accessing: $path\n);    
    my @arr = ($1 =~ m/(.*)\/(.*)/g);
    if(@arr!=2){
        $client->send("<<error<3>Invalid path: $cmd>>\n");
        return
    }
    $name = $arr[-1];
    if($arr[0]=~/\s/){ #has process command.      
       $process = pop @arr
    }
    if($arr[0]!~/\./){ #uses protocol of config path to query.
       $arr[0] = $arr[0].'.cnf'
    }
    $path = join "", @arr[0 .. $#arr-1] if @arr >1;
    $rep = %$central{'%config_files'};
    $rep = $rep->{$path};    
    if( !$rep ){
        $value = "<<error<1>Configuration '$path' not found!\nFailed to retrieve: $cmd>>\n";
        print "$value\n";
    }elsif(!$central->checkIPrange($cip, $$rep->anon('IP_RANGE_ACCEPT'))){
         $value = "<<error<2>Access Denied to '$path' property '$name'!\nFailed to retrieve: '$cmd'>>\n";
         print qq(Denied Access to: $cip\n);
        
    }else{              
        $value = $$rep->anon($name);        
        if(!$value){
            #Following if not cought will crash the server,
            # as constants have now private read only access.
            try{                
                $value = $$rep->constant($name)                
            }catch{
                undef $value;
            };
        }
        if(!$value){
            $value = "<<error<3>Configuration '$path' property '$name' not available!\nFailed to retrieve: $cmd>>\n"
        }else{
            $value = qq(<<property<$name>$value>>);
        }
    }    
    $client->send($value);
}

sub list {
    my ($client, $cmd) = @_;
    my $pub  = $cnf->{public_dir};
    my $path = length($cmd) > 4 ? substr $cmd, 5 : ""; 
    my $data ="";
    $path =~ s/^[\/|~|\.]+//g; 
    $path = "$pub/$path";
    print qq(Listing: $path\n);
    $cmd = "ls -lah $path";
    $data = qx($cmd);
    if($data){
       $client->send($data);      
    }else{
        if(! -e $path){
            $client->send("<<error<1>No such file or directory '$path'>>\n");
        }
    }    
}

