#!/usr/bin/env perl

# To open port on linux:
# sudo ufw allow perl-cnf
# Which is set/found in /etc/services
# perl-cnf	1028/tcp			# PerlCnf server port.
use warnings; use strict; use Syntax::Keyword::Try; 
#use lib "./local";
use lib "/home/will/dev/ServerConfigCentral/local";


require CNFCentral;

my $central = CNFCentral ->   server();
my $cnf     = $central   -> {'parser'};
my $server  = $central   -> {'socket'}; 
#
$central->loadConfigs();
#
while(1) {
    COMM: print " Server is listening...\n";
    if(my $client = $server->accept()) {

        my ($cmd,$rl,$client_address,$client_port);
        
        my $stamp = $central->stamp();
        my $host_hdr = `hostname`. ' '.$stamp; 
        
        $client_address = $client->peerhost();
        $client_port = $client->peerport();
        $host_hdr =~ s/\n/:/g;
        $client->send("<<header<$host_hdr>>>\n");        
        
        print "Connection from: $client_address ($client_port) - $stamp\n";
             
            my $read = $cmd= "";            
            $client->recv($cmd,1024);
            print "Received cmd: $cmd\n" if $cmd;
            if(    $cmd =~ /^auth/ )    {auth($client,$cmd)}
            elsif( $cmd =~ /^list/ )    {list($client,$cmd)}
            elsif( $cmd =~ /^repo/ )    {repo($client,$cmd)}
            elsif( $cmd =~ /^prop/  )   {prop($client, $cmd)} 
            elsif( $cmd =~ /^help/ )    {help($client)} 
            elsif( $cmd =~ /^end/)      {
                                         $central->unRegisterClientFromToken($client);                                         
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

list - List available repositories as files.
prop - Obtains property from an repository.
       \$ prop myRepo/example
       returns -> <<property<example>Hello! You reached my value client.>>
auth - Initiates CNF Central client/server authentic communication and token session.       
       \$auth {id}
       returns ->  <<session<{date}>{Unique-Session-Token-For-Your-Client-Only}>>
       The {id} is required if running different client for several applications. 
       And also to temporarly persist the session during the servers running state.
end  - Indicates to server proper closing communication from the client side.

Authentication based commands:

Client has to be setup, for server configuration specifics, the following to work.
See documentation for further info.

load - Load and send a whole repo or configuration file.
save - Store client send whole repo, this is usually an copy of a loaded one.
anon - Store client or global by id only accessible property and value.
       you\@terminal \$ con_cnt= client.pl -c "prop global/connection_count";
       you\@terminal \$ con_cnt=\$con_cnt+1;
       you\@terminal \$ client.pl -c "auth anon global connection_count = \$con_cnt");
log  - Add a stamped CNF formated log line at start of file central.log.
       Withouth parameters lists last ten entries.
       you\@terminal \$ echo "Hello World!" | ./client.pl - -c "auth log {}"

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
    $central->registerClientWithToken($client, $token);
    if(length($cmd)>2){        
        my $args = $central -> parseCmdChain($cmd);
        my $func = shift @$args;
        if(    $func =~ /^anon/ )    {anon($client, $cmd, @$args)}
        elsif( $func =~ /^load/ )    {load($client, $cmd, @$args)}
        elsif( $func =~ /^list/ )    {listProps($client, $cmd, @$args)}
        elsif( $func =~ /^log/  )    {logCNF($client, $cmd, @$args)}
        elsif( $func =~ /^save/ )    {save($client, $cmd, @$args)}
    }
    return $token;
}

###
# CNF anon properites are an setable variable in any repository.
# In contrast to the CNF constants, each repository has its own. Setable only in file.
##
sub anon {
    my ($client, $cmd, @args)= @_;    
    
    $client->send("<<error<1>Service '$cmd' what?>>\n") if @args == 0;
    # Following is an powerful language feature of perl, 
    # called anonymous function pass to the class.    
    my  $ret = CNFCentral::_processChainedCmd($client, 'global', *accessRepositoryForAnon, @args);
    $client->send($ret);
}

    sub accessRepositoryForAnon{
        my ($client, $rep_alias, $name, $value)= @_;        
        my $repo = $central -> getRepo($rep_alias);
        if(!$repo){
            return "<<error<2>Repository not found: $rep_alias/$name>>"
        }        
        my $anons = $repo->anon();
           $value = "" if not $value;
        if($value=~/^=\s*'(.*)'\s*$/){
           $value=$1;          
           $anons->{$name} = $value;
           return "<<anon<modified $rep_alias/$name>$value>>";
        }else{           
           $value = $anons->{$name};
           if(!$value){
            return "<<error<3>Anon not found : $rep_alias/$name>>"
           }
        }
        return "<<anon<$rep_alias/$name>$value>>";
    }

sub listProps {
    my ($client, $cmd, @args)= @_;
    if(!@args){
        $client->send("<<error<2>Service '$cmd' not possible. Like load what for you?>>\n");
        return;
    }
    my  $ret = CNFCentral::_processChainedCmd($client, 'global', *accessRepositoryForListProps, @args);
    $client->send($ret);
}


 sub accessRepositoryForListProps{
        my ($client, $rep_alias, $name, $value)= @_;        
        my $repo = $central -> getRepo($name);        
        if(!$repo){
            return "<<error<2>Repository not found: $rep_alias/$name>>"
        }  
        my $buffer;
        foreach(keys %$repo){
            my ($n,$v) = ($_, $repo->{$_});
            $buffer .= "$n='$v'\n";
        }
        my $anons = $repo->anon();
        foreach(keys %$anons){
            my ($n,$v) = ($_, $anons->{$_});
            $buffer .= "$n='$v'\n";
        }
        return $buffer;
}

sub logCNF {
    my ($client, $cmd, @args)= @_;
    my ($log_file, $log_tmp) = ($cnf->{'public_dir'}.'/central.log', '/tmp/'.$client->peerhost().'_central.log');
    
    if(!@args || $args[0] eq 'list'){       
        my ($cnt, $limit)=(0,3);
        my $content;
        open(my $fhL, "<:perlio", $log_file);
        while(<$fhL>){
            my $line = $_;
            if($line=~/<<\$\$</){
               last if ($cnt++>$limit);
            }
            $line =~ s/\\n/\n/g;
            $content .= $line;
        }
        close $fhL;
        $central -> scrumbledSend($client, $content);
        return;
    }
    my $user = $args[-1];
    $client->send("<<log<send>>>");
    my  $content = $central -> scrumbledReceive($client);
   # $client->recv($content, 64*1024);
    $content =~ s/^\s|\s$//g;
     
    if($content){    
        open(my $fhL, "<:perlio", $log_file);
        open(my $fhT, ">:perlio", $log_tmp);
        
        print $fhT "<<\$\$<$user@".$client->peerhost().' '.$central->stamp().">$content>>\n";
        if($fhL){
            while(<$fhL>){ print $fhT $_ }
            close $fhL;
        }
        close $fhT;
        
        open($fhT, "<:perlio", $log_tmp);
        open($fhL, ">:perlio", $log_file);
        if($fhL){
            while(<$fhT>){
                print $fhL $_;
                #print $_,"\n";
            }
        }
        close $fhT;
        close $fhL;
        unlink $log_tmp;
        $client->send("<<log<received>>>");
    }
    
}


sub load {
    my ($client, $cmd, @args)= @_;
    if(!@args){
        $client->send("<<error<2>Service '$cmd' not possible. Like load what for you?>>\n");
        return;
    }
    my ($path, $content) = ($cnf->{'public_dir'}.'/'. $args[0].'.cnf',"");
    open(my $fh, "<:perlio", $path ) or $content = undef;
    read $fh, $content, -s $fh;
    close $fh;
    if($content) {  
       $client->send($content);
    }else{
       $client->send("<<error<1>Service '$cmd' errored -> $!");       
    }     
}


sub save {
    my ($client, $cmd, @args)= @_; 
    if(!@args){
        $client->send("<<error<2>Service '$cmd' not possible, if not providing a file name.>>\n");
        return;
    }
    mkdir $cnf->{'public_dir'}.'/'.$client->peerhost();
    my ($path, $content) = ($args[0],"");
        $path=~s/\//_/g; $path = substr $path, 1 if $path =~ /^_/;
        $path = $cnf->{'public_dir'}.'/'.$client->peerhost()."/$path";
    if(open(my $fhW, ">:perlio", $path )){    
       $client->send("<<save<send>>>");
       $client->recv($content, 64*1024);
       print $fhW $content;       
       close $fhW;
       $client->send("<<save<saved>>>");       
    }else{
       $client->send("<<error<1>Service '$cmd' errored -> $!");
    } 

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

