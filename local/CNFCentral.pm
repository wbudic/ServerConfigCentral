#!/usr/bin/env perl
#
# Programed by: Will Budic
# Open Source License -> https://choosealicense.com/licenses/isc/
#
package CNFCentral;

use warnings; use strict;
use IO::Socket qw(AF_INET AF_UNIX SOCK_STREAM SHUT_WR inet_aton);
use Crypt::CBC;
use Crypt::Blowfish;
use DateTime;
use feature qw(signatures);

require CNFParser;  
require CNF_CBC;

use constant VERSION => '1.0';
use constant CONFIG  => 'central.cnf';

our %clients;


sub server {    my ($class, $config, %self) = @_; 
    $config = defaultConfigFile($class, CONFIG) if ! $config;
    $self{'parser'} = CNFParser-> new ($config, {Domain => AF_INET, Type => SOCK_STREAM, Proto => 'tcp', ANONS_ARE_PUBLIC=>1});
    $self{'socket'} = IO::Socket->new(%{$self{'parser'}})     
       or die "Cannot open socket, is the server running? -> $IO::Socket::errstr\n";    
    $self{'CLIENT_SHUTDOWN'}  = SHUT_WR;
    bless \%self, $class;    
    return \%self;
}


sub client {    my ($class, $config, %self) = @_;    
    $config = defaultConfigFile($class, CONFIG) if ! $config;
    $self{'parser'} = CNFParser-> new (
        # Perl compiler must pass its export constants to the config as attributes, 
        # otherwise they are plain strings if specified only as such in the config.
        #
        $config, {Domain => AF_INET, Type => SOCK_STREAM, Proto => 'tcp', ANONS_ARE_PUBLIC=>1}   , 
        # Following is list of keys to remove from the config as they are server properties.
        # We automate the whole ordeal both client and server to have the same config file. 
        ['LocalPort',  'LocalHost', 'Listen' ,'ReusePort']
    );
    $self{'socket'} = IO::Socket->new(%{$self{'parser'}}) 
       or die "Cannot open socket, is the server running? -> $IO::Socket::errstr\n";
    bless \%self, $class;    
    return \%self;
}

sub socketC {
    my ($self) = @_;
    my $parser = $self->{'parser'};
    die if not $parser;
    return  IO::Socket->new(%$parser) 
}


sub new {  
    my ($self) = @_;    
    bless { parser => CNFParser-> new (
                                            defaultConfigFile(CONFIG), 
                                            {DO_enabled => 0, ANONS_ARE_PUBLIC => 1}
                                      )
        }, $self;
}

sub defaultConfigFile {
    my ($self, $config) = @_; 
    $config = $self if(scalar $self && !$config);
    if(! -e $config){$config = "~/.config/$config"}
    return  $config;
}

sub config {
    return shift -> {parser};
}
sub configDumpENV {
    return shift -> {parser} -> dumpENV();
}
###
# Method is similar to sub sessionTokenToArray but less stict in tag format.
# It extracts <<NAME<INSTRUCTION>VALUE>> but also <<NAME<VALUE>>> name and value pair.
# The value could be also any text or script between tags found. 
# @returns The query turned into an array as ["NAME", "VALUE"] pair. 
###
sub tagCNFToArray { 
    my ($self, $tag) = @_;
    die "Invalid no. of parameteres passed." unless @_ == 2;    
    my  @r = ($tag =~ m/<<(.*?)<(.*?)>(\s*.*?|[\*\.]*)(\s>>+|>>)/gs);
    if(@r){
        pop @r if $r[-1] eq '>>';
        pop @r if $r[-1] eq '';        
    }else{
        push @r, $tag
    }
    return @r
}
###
# Static method that parses further possibly chained series of commands.
# @return array reference
###
sub parseCmdChain { 
    shift if(@_>1);
    my $cmd = shift;
    my @rc =($cmd =~ /;/);
    if(@rc>0){
         my @recurse; 
        foreach(@rc){push @recurse, parseCmdChain($_)}
        return \@recurse;
    }else{        
        @rc = ( $cmd=~ m/(['=].*'|[\w\/\.]*)\s*/gs ); 
        while(@rc &&!$rc[-1]){pop @rc}
        return \@rc
    }
}

sub _processChainedCmd {    
    my ($client, $rep, $_anon_sub, @args)= @_; 
    my ($name, $value,$result);
    # It is complicated, the full format is:
    # "{repo} name {'=value'}" <-[...]
    # where default repo is {global} and if value not specified 
    # the anon existing value is required. If it exists and is valid.
    foreach my $next(@args){
            if(ref($next) eq 'ARRAY'){
                processChainedCmd($client, $rep, @$next);
            }elsif(!$name){
                $name = $next;
            }elsif(!$value){
                $value = $next;
            }
            
            if($value){
                if($value =~/^=/){
                   $result .= &$_anon_sub($client, $rep, $name, $value);
                   $name = $value = ""
                }else{
                   $rep  = $name;
                   $name = $value; 
                   $value = ""
                }
            }
    }
    $result .= &$_anon_sub($client, $rep, $name, $value) if $name;
    return $result;
}


###
# Server uses following routine at connection request stage.
###
sub generateSessionToken {
    my ($provided,@c) = shift;
    if (!$provided){
         @c = "1234567890ABCDEFGHIJKLMWCNFCENTRAL" =~ m/./g
       }else{
         @c = $provided =~ m/./g
       }
    my ($date,$code) = (&stamp, undef);    
    if(@c<28){    
        my $err =  qq(Error ->[@c] Pick token is less then 28 digits long.\n\t);
        die $err
    }
    $code .= sprintf ("%s%s", $c[rand(@c)], $c[rand(@c)])foreach(1..8);    
    return qq(<<session<$date>$code>>);
}

sub stamp {
    my $now   = DateTime->now();        
    return $now->ymd.' '.$now->hms;
}

###
# Client/Server uses following to obtain token date and value.
###
sub sessionTokenToArray { 
    if(@_>1){shift} my $token = shift;
    return ($token =~ m/<<session<(.*)>(.*)>>/)  
}
#


sub registerClientWithToken {
    my ($self,$client, $token) = @_;
     if($client && $token){
        my $parser = $self->{'parser'};
        my $id = $parser->anon('SERVER_ID');
        $clients{$client->peerport()} = CNF_CBC->initCBC($token, $id);
     }
     return $token
}
sub unRegisterClientFromToken {
    my ($self,$client) = @_; my $key =   $client->peerport();
    if ($key && exists $clients{$key} ){    
        delete $clients{$key}
    }     
}

sub scrumbledSend {
    my ($self,$client, $content) = @_;
    if(exists $clients{$client->peerport()} ){
       my $cbc = $clients{$client->peerport()};
       $content = $cbc->encrypt($content);
       $client -> send ($content)
    }else{
       $client -> send($content); # TODO - We are still sending, as main pupose of the CNF auth protocol 
                                  #        is not security, but to have an ensured directed communication.
       print "Error, send to not authenticated $client content.";
    }
}
sub scrumbledReceive {
    my ($self, $client) = @_;
    my $content;
    if(exists $clients{$client->peerport()} ){
       my $cbc = $clients{$client->peerport()};
       $client -> recv($content, 64 * 1024); 
       $content = $cbc->decrypt($content);       
    }else{
       $client -> recv($content, 64 * 1024);
       print "Error, received to not authenticated $client content.";
    }
    return $content
}

sub checkIPrange {
    my ($self,$sip, $srange) = @_;
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

#

###
# Obtains config from repository.
# Global public if not specified which.
# returns scalar ref for config or undef if not found/present!
###
sub getRepo {     
     my ($self,$alias) = @_;
     $alias = 'global' if ! defined $alias;
    my $path = %$self{'parser'}->{'public_dir'}."/$alias.cnf";    
    return $self->{'CNF_GLOBAL'} if($alias eq 'global') && $self->{'CNF_GLOBAL'};

    if(-e $path){
      my $cnf = CNFParser->new($path);
      print "Loaded repo config: $path\n";      
      return $cnf;
    }elsif($alias eq 'global'){ 
        my $cnf = CNFParser->new(undef,{CNF_CONTENT=>$path, ANONS_ARE_PUBLIC=>1});
        $cnf->anon()->{'repo_generated'} = 1;
        $self->{'CNF_GLOBAL'} = $cnf;        
        return $cnf;
    }
    return undef;
}

sub loadConfigs {
    my ($self,@col) = @_;   
    my %configs;
    my $cnf = $self->{'parser'};    
    my $c   = $cnf->collection('@config_files');
    if($c){
        @col = @$c;            
        foreach  my $file(@col){
            my $path = "$cnf->{public_dir}/$file";
            #print "[$path]\n"; 
            if(-e $path){
                if(!$configs{$file}){
                    # Note - Reference \CNFParser stored in hash not the whole parser object.
                    # New feature added to parser ANONS_ARE_PUBLIC, shielding both globals or private properties.
                    # To its own respective repositories. Setting it to ANONS_ARE_PUBLIC=>1, all anons will turn global.
                    # And we don't want that. As actual global is setup only to be from the central.cnf. 
                    # To which any clent has access to. And again, some repositories can be limited, to who can access them.
                    # I read your mind. Yes, my head begins to hurt too....
                    $configs{$file}  = \CNFParser->new($path, {ANONS_ARE_PUBLIC=>0});
                    print "Loaded config: $path\n";
                }
            }else{            
                    print "WARNING! \@config_files registered file not found: $path\n";
            }
        }
        $self->{'%config_files'}=\%configs;
    }else{
        my $CNF_PATH = %$cnf{'CNF_CONTENT'};
        die qq(ERROR! Property '\@config_files' has not been found in central config: ./$CNF_PATH\n)
    }
}

1;