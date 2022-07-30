#!/usr/bin/env perl

# To open port on linux:
# sudo ufw allow perl-cnf
# Which is set/found in /etc/services
# perl-cnf	1028/tcp			# PerlCnf server port.
use warnings; use strict; use Syntax::Keyword::Try;
use lib "./local";

require CNFCentral;

my $central = CNFCentral ->   server();
my $cnf     = $central   -> {'parser'};
my $server  = $central   -> {'socket'}; 


#
$central->loadConfigs();
#
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
            $client->recv($cmd,1024);
            print "Received cmd: $cmd\n" if $cmd;
            if(    $cmd =~ /^auth/ )    {auth($client,$cmd)}
            elsif( $cmd =~ /^list/ )    {list($client,$cmd)}
            elsif( $cmd =~ /^repo/ )    {repo($client,$cmd)}
            elsif( $cmd =~ /^prp/  )    {prop($client, $cmd)} 
            elsif( $cmd =~ /^help/ )    {help($client)} 
            elsif( $cmd =~ /^end/)      {
                                         $central->{ $client_port } = undef;
                                         $client->close(); 
                                         print "Connection ended: $client_address($client_port)\n";
                                         goto COMM
            }elsif( $cmd =~ /^anon/ || $cmd =~ /^load/ || $cmd =~ /^save/ ){#chained authentication protocol based commands
                $client->send("<<error<$cmd>Authentication exchange required for command.>>");
            }elsif($cmd){
                $client->send("<<error<$cmd>Command not known to server!>>");
            }

        print "Socket closed: $client_address($client_port)\n";
    }
}

$server->close();

sub help{ 
    my ($client, $cmd)= @_; my $ver = $cnf->VERSION;
        $client->send(  <<__HELP
    
Perl CNF Central Server $ver

Avalable commands:

list - List available repositories.
prop - Obtains property from an repository.
       \$ prop myRepo/example
       returns -> <<property<example>Hello! You reached my value client.>>
auth - Initiates CNF Central client/server authentic communication and token session.       
       \$auth {id}
       returns ->  <<session<{date}>{Unique-Session-Token-For-Your-Client-Only}>>
       The {id} is required if running different client for several applications. 
       And also to temporarly persist the session during the servers running state.
end  - Indicates to server proper closing communication from the client side.

Authentication based  commands:

Client has to be setup, for server configuration specifics, the following to work.
See documentation for further info.

load - Load and send a whole repo or configuration file.
save - Store client send whole repo, this is usually an copy of a loaded one.
anon - Store client or global by id only accessible property and value.
       \$con_cnt= client.pl -c "prop global/connection_count";
       \$con_cnt=\$con_cnt+1;
       \$client.pl -c "auth anon global connection_count = \$con_cnt");

__HELP
)}


sub auth {
    my ($client, $cmd)= @_;    
    my $token = CNFCentral::generateSessionToken();
    $central->{$client->peerport()} = CNFCentral::sessionTokenToArray($token);    
    $client->send($token);    
    print "Token send: $token\n";
    $client->recv($cmd, 1024);
    print "Client req: $cmd\n";
    if(length($cmd>4)){        
        if(    $cmd =~ /^auth\s*anon/ )    {anon($client,$cmd)}
        elsif( $cmd =~ /^auth\s*load/ )    {load($client,$cmd)}
        elsif( $cmd =~ /^auth\s*save/ )    {save($client,$cmd)}
    }
    return $token;
}

sub anon {
    my ($client, $cmd)= @_;     
    my @args = $central -> parseCmdChain('global',$cmd);
    my $name = shift @args;# <- should always will be 'auth' up to this point.
       $name = shift @args;# <- should always will be 'anon'.
    # Following is an powerful language feature of perl, 
    # called anonymous function pass to the class.    
    my  $ret = CNFCentral::processChainedCmd($client, 'global', *accessRepositoryForAnon, @args);
    $client->send("$ret\n<<error<1>Service '$cmd' not available yet. It is still Under development.>>\n");
}

    sub accessRepositoryForAnon{
        my ($client, $rep_alias, $name, $value)= @_;
        
        my $repo = $central -> getRepo($rep_alias);
        if(!$repo){
            return "<<error<2>Repository not found: $rep_alias/$name>>";
        }
           $value = "" if not $value;
        if($value=~/^=\s*'(.*)'\s*$/){
           $value=$1;
           my $anons = $repo->anon();
           $anons->{$name} = $value;
           return "<<anon<modified $rep_alias/$name>$value>>";
        }
        return "<<anon<$rep_alias/$name>$value>>";
    }



sub load {
    my ($client, $cmd)= @_; 
    $client->send("<<error<1>Service '$cmd' not available yet. It is still Under development.>>\n");
}
sub save {
    my ($client, $cmd)= @_; 
    $client->send("<<error<1>Service '$cmd' not available yet. It is still Under development.>>\n");
}



sub repo {
    my ($client, $cmd)= @_;
    my $client_id = $client->peerport();
    my $token = CNFCentral::generateSessionToken();
    $central->{$client_id} = CNFCentral::sessionTokenToArray($token);    
    $client->send($token);    
    print "Send token: $token\n";
}

sub prop {
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

