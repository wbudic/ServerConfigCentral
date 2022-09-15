package CNF_CBC;

use warnings; use strict;
use feature qw(signatures);

our $CBC_IV = "C00000000000000F";

###
# Config CBC object implementation.
##
 
sub initCBC ($class, $token, $id){
    my @prp = CNFCentral::sessionTokenToArray($token);
    die "Error: Invalid session token: $token [".join('|', @prp)."]" if @prp !=2;
    my $key = qq($prp[1]-$id);

   return bless {
            token => $token,
            session_key => $key,
            cbc         => Crypt::CBC->new( 
                                        -cipher => "Blowfish",
                                        -pass =>  $key,
                                        -iv => pack("H*", $CBC_IV),
                                        -header => 'none',
                                        -padding => 'none',
                                        -nodeprecate=>1 ,
                                        -pbkdf=>'randomiv'
            )
    }, $class
}
sub encrypt {my ($self, $text) = @_;
    return unpack("H*", $self->{'cbc'}->encrypt($text));
}
sub decrypt {my ($self,$cipher) = @_;
    my $ret = $self->{'cbc'}->decrypt(pack("H*",$cipher));
    $ret =~ s/\0*$//g; #Zero always padded maybe?
    return $ret;
}

1;

