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
require CNFParser;  
use constant VERSION => '1.0';

our $CBC_IV = pack("H*", "C00000000000000F");

sub client {    my ($class, $config, %self) = @_;    
    $config = 'central.cnf' if ! $config;
    if(! -e $config){$config = "~/.config/$config"}
    $self{'parser'} = CNFParser-> new (
        # Perl compiler must pass its export constants to the config as attributes, 
        # otherwise they are plain strings if specified only as such in the config.
        #
        $config, {Domain => AF_INET, Type => SOCK_STREAM, Proto => 'tcp'}   , 
        # Following is list of keys to remove from the config as they are server properties.
        # We automate the whole ordeal both client and server to have the same config file. 
        ['LocalPort',  'LocalHost', 'Listen' ,'ReusePort']
    );
    $self{'socket'} = IO::Socket->new(%{$self{'parser'}}) 
       or die "Cannot open socket, is the server running? -> $IO::Socket::errstr\n";
    bless \%self, $class;    
    return \%self;
}

sub server {    my ($class, $config, %self) = @_; 
    $config = 'central.cnf' if ! $config;
    if(! -e $config){$config = "~/.config/$config"}
    $self{'parser'} = CNFParser-> new ($config, {Domain => AF_INET, Type => SOCK_STREAM, Proto => 'tcp'});    
    $self{'socket'} = IO::Socket->new(%{$self{'parser'}})     
       or die "Cannot open socket, is the server running? -> $IO::Socket::errstr\n";    
    $self{'CLIENT_SHUTDOWN'}  = SHUT_WR;
    bless \%self, $class;    
    return \%self;
}

sub new {  
    my ($self) = @_;
    bless {}, $self;    
}

sub initCBC { my ($self, $key) = @_;
    $self->{'cbc'} =  Crypt::CBC->new( 
         -cipher => "Blowfish",
         -literal_key => 0,
         -key => $key,
         -iv =>$CBC_IV,
         -header => 'none',
         -padding => 'none',
         -pbkdf=>'pbkdf2'
    );
}
sub encrypt {my ($self, $text) = @_;
    return unpack("H*", $self->{'cbc'}->encrypt($text));
}
sub decrypt {my ($self,$cipher) = @_;
    my $ret = $self->{'cbc'}->decrypt(pack("H*",$cipher));
    $ret =~ s/\0*$//g; #Zero always padded maybe?
    return $ret;
}

sub config {
    return shift -> {parser};
}
sub configDumpENV {
    return shift -> {parser} -> dumpENV();
}

###
# Server uses following routine connection request stage.
###
sub generateSessionToken {
    my ($provided,@c) = shift;
    if (!$provided){
         @c = "1234567890ABCDEFGHIJKLMWCNFCENTRAL" =~ m/./g
       }else{
         @c = $provided =~ m/./g
       }
    my ($date,$code) = (scalar localtime, undef);    
    if(@c<28){    
        my $err =  qq(Error ->[@c] Pick token is less then 28 digits long.\n\t);
        die $err
    }
    $code .= sprintf ("%s%s", $c[rand(@c)], $c[rand(@c)])foreach(1..8);    
    return qq(<session<$date>>$code>>);
}
###
# Client/Server uses following to obtain token date and value.
###
sub sessionTokenToArray { 
    my $token = shift;
    return ($token =~ m/<session<(.*)>>(.*)>>/)  
}

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

sub loadConfigs {my ($self,@col) = @_;   
    my %configs;
    my $cnf = $self->{'parser'};    
    my $c = $cnf->collection('@config_files');
    if($c){
        @col = @$c;    
        $self->{'%config_files'}=%configs;
        foreach  my $file(@col){
            my $path = "$cnf->{public_dir}/$file";
            #print "[$path]\n"; 
            if(-e $path){
                if(!$configs{$file}){
                    #Note - Reference \CNFParser stored in hash not the whole parser object.
                    $configs{$file}  = \CNFParser->new($path);
                    print "Loaded config: $path\n";
                }
            }else{            
                    print "WARNING! Config not found: $path\n";
            }
        }
    }else{
        my $CNF_PATH = %$cnf{'CNF_CONTENT'};
        die qq(ERROR! Property '\@config_files' has not been found in central config: ./$CNF_PATH\n)
    }
}


__END__

