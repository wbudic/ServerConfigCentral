#!/usr/bin/env perl

use warnings; use strict;
use lib "./local";
require CNFCentral;


my $central = CNFCentral -> client();
my $socket  = $central   -> {'socket'};
my $buffer;
$socket->send("list");
#$socket -> send("prp list sample1/PAGE");
do{
    $socket->recv($buffer, 1024);
    print $buffer;
}while(length ($buffer)>0);

#$central ->  configDumpENV();

END{
$socket->close() if $central;
}
__END__

