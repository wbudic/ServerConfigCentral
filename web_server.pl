#!/usr/bin/env perl
use v5.10;
use warnings; use strict; use Syntax::Keyword::Try; 
use HTTP::Headers;
use HTTP::Daemon;
use HTTP::Status;
use MIME::Base64;
use Gzip::Faster;

use lib "local";
require CNFParser;
require CNFNode;
require HTMLProcessorPlugin;

my $config = &getConfig; 
my %hdr_no_cache = $config->collection('%HEADER_NO_CACHE');
my $home_page = $config->data()->{'HOME_PAGE'};
my $main_content;
if (%hdr_no_cache){
    $hdr_no_cache{'Page-Server-App'}    = "$0";
    $hdr_no_cache{'Content-Encoding'}   = 'gzip';
    $hdr_no_cache{'Charset'}            = "UTF-8";
    $hdr_no_cache{'Expires'}            = '1s'#`date`;
}
my %hdr = %hdr_no_cache; delete %hdr{'Content-Encoding'};
my $server = HTTP::Daemon -> new(%$config) || die ("$@");
print "HTTP daemon is running at: ", $server->url, "\n";
local $SIG{'INT'} = *interrupt;

sub _ext_to_img_content_type {
   my $for = shift;
   return 'image/'. lc $for;
}
sub getConfig{
return CNFParser -> new ('configs/http.cnf',{DO_enabled=>1, ANONS_ARE_PUBLIC=>1, ENABLE_WARNINGS=>1, file_list_html=> getFileList() }); 
}
my $client;
try{    
    while ($client = $server->accept) {        
        while (my $r = $client->get_request) {
            my $local_path = substr $r->uri->path, 1;
            say "Req:".$r->method." ".$r->uri->path, " encoding:".$r->header('Accept-Encoding');            
        if ($r->method eq 'GET' and $r->uri->path eq "/") {            
            my @stat = @{$config->{CNF_STAT}};
            my @curr = stat($config->{CNF_CONTENT});
            if($stat[9] != $curr[9]){
               $config = &getConfig;
               $home_page = $config->data()->{'HOME_PAGE'};
               say "Reloaded home page: ".$config->{CNF_CONTENT} ." [".$stat[9]. "] with ".$curr[9];
               undef $main_content
            }
            if(!$main_content){
                if ($r->header('Accept-Encoding') =~ m/gzip/){
                    $main_content = gzip($$home_page); say "Home page compressed!"
                }else{ 
                    $main_content = $$home_page
                }
            }
            $client->send_response(HTTP::Response->new(RC_OK, undef, [%hdr_no_cache], $main_content));
        }
        elsif($r->method eq 'GET' and $local_path =~ /\.(jpg|jpeg|png|gif|JPG|JPEG|PNG|GIF)$/){
              $client->send_response(HTTP::Response->new(RC_OK),undef, ['Content-Type' => _ext_to_img_content_type($1)]);                        
              $client->send_file($local_path);
        }
        elsif($r->method eq 'GET' and $r->uri->path =~ /\/configs\/docs\/(.*)\.cnf$/){            
            my $page_name = uc "$1\_PAGE";
            my $load = CNFParser -> new ( $local_path, {DO_enabled=>1, ANONS_ARE_PUBLIC=>1, ENABLE_WARNINGS=>1, file_list_html=> getFileList()});
            my $page = ${$load->data()->{$page_name}};
            #$page = gzip($page) if $r->header('Accept-Encoding') =~ m/gzip/;            
            $client->send_response(HTTP::Response->new(RC_OK, undef, [%hdr], $page));
        }
        elsif($r->method eq 'GET' and $r->uri->path =~ /\/configs\/docs\/(.*)$/){
            my $content;
            open my $fh, "<", $local_path or die ("$!->$local_path"); 
            $content = <$fh>;
            close $fh;            
            $client->send_response(HTTP::Response->new(RC_OK, undef, [%hdr], $content));
        }
        elsif($r->method eq 'GET' and $local_path eq 'favicon.ico'){
            $client->send_response(HTTP::Response->new(RC_OK)); 
        }
        else {
            $client->send_error(RC_FORBIDDEN)
        }
        }
        $client->close;
        undef($client);
    }
}catch{
    $client->close;
    $server->close();
    print("Fatal Error: $@");
}


sub getFileList {
    my $ret ="";
    my @docs = glob('configs/docs/*.cnf');
    foreach my $lnk(@docs){
        ($lnk=~/configs\/docs\/(.*)\.cnf$/);
        $ret .= qq(<a href="$lnk">$1</a>\n);
    }
    return '<div>' . $ret . '</div>'
}

sub interrupt {    
    $server->close();
	exit 0;
};