#!/usr/bin/env perl
use v5.10;
use warnings; use strict; use Syntax::Keyword::Try; 
use HTTP::Headers;
use HTTP::Daemon;
use HTTP::Status;
use Gzip::Faster;
use threads;
use threads::shared;
use Thread::Semaphore;

use lib "/home/will/dev/ServerConfigCentral/local";
require CNFParser;
require CNFNode;
require HTMLProcessorPlugin;
require ShortLink;

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
my %log = $config->collection('%LOG'); %log = () if !%log;
###
my $server = HTTP::Daemon -> new(%$config) || die ("$@");
&log("HTTP daemon is running at: ". $server->url. "\n");
&log($config->writeOut());
local $SIG{'INT'} = *interrupt;
my $semaphore = Thread::Semaphore->new();
###

sub _ext_to_img_content_type {
   my $for = shift;
   return 'image/'. lc $for;
}
sub getConfig{
return CNFParser -> new ('configs/http.cnf',{DO_enabled=>1, ANONS_ARE_PUBLIC=>1, ENABLE_WARNINGS=>1, file_list_html=> getFileList() }); 
}
my $client;
try{    
    #TODO Thread lock client synchronize access to this block. So browser doesn't lock into req. access.
    #     That is, each client must finish before another span socket can have access to this block of code.
    #     Parallel possible client assignment is not possible. Also making a new process on each accept is an overkill for this application.
    #     Standard installed perl running this app, might not be compiled with threads available, hence not implemented yet.
    while (my $client = $server->accept) {   
        $semaphore -> down();
        while (my $r = $client->get_request) {
            my $local_path = substr $r->uri->path, 1;
            &log("Req:".$r->method." ".$r->uri->path, " accept-encoding:".$r->header('Accept-Encoding'));            
        if ($r->method eq 'GET' and $r->uri->path eq "/") {            
            my @stat = @{$config->{CNF_STAT}};
            my @curr = stat($config->{CNF_CONTENT});
            if($stat[9] != $curr[9]){
               $config = &getConfig;
               $home_page = $config->data()->{'HOME_PAGE'};
               &log("Reloaded home page: ".$config->{CNF_CONTENT} ." [".$stat[9]. "] with ".$curr[9]);
               undef $main_content
            }
            my %header = %hdr;
            if(!$main_content){
                if ($config->{'UseCompression'} && $r->header('Accept-Encoding') =~ m/gzip/){
                    $main_content = gzip($$home_page); 
                    &log("Home page got compressed!");
                    %header = %hdr_no_cache
                }else{ 
                    $main_content = $$home_page
                }
            }
            $client->send_response(HTTP::Response->new(RC_OK, undef, [%header], $main_content));
        }
        elsif($r->method eq 'GET' and $local_path =~ /img\@(.*)$/){
            my $dec = ShortLink::convert($1);
            say "path decoded: $dec";
            ($dec=~/.*\.(.*)$/);
            if(-f  $dec ){        
                $client->send_response(HTTP::Response->new(RC_OK),undef, ['Content-Type' => _ext_to_img_content_type($1)]);                        
                $client->send_file($dec);
            }else{                
                $client->send_error(RC_NOT_FOUND, qq(Image not found or its link is corrupted -> <b>$dec</b><br>
                                                    <img src='images/RC_NOT_FOUND.jpeg'/><br>
                                                    <a href="/">Back Home</a>))
            }
        }
        elsif($r->method eq 'GET' and $local_path =~ /\.(jpg|jpeg|png|gif|JPG|JPEG|PNG|GIF)$/){
               
              if(-f  $local_path ){        
                 # $semaphore->up();
                  $client->send_response(HTTP::Response->new(RC_OK),undef, ['Content-Type' => _ext_to_img_content_type($1)]); 
                  $client->send_file($local_path);
                #  $semaphore->down();
              }else{
                  &log("NOT FOUND: $local_path\n");            
                  $client->send_error(RC_NOT_FOUND)
              }
        }
        elsif($r->method eq 'GET' and $r->uri->path =~ /\/configs\/docs\/(.*)\.cnf$/){
            if(-f  $local_path ){        
                my $page_name = uc "$1\_PAGE";
                my $load = CNFParser -> new ( $local_path, {DO_enabled=>1, ANONS_ARE_PUBLIC=>1, ENABLE_WARNINGS=>1, file_list_html=> getFileList(1)});
                my $page = ${$load->data()->{$page_name}};
                my %header = %hdr;
                if ($config->{'UseCompression'} && $r->header('Accept-Encoding') =~ m/gzip/){ 
                    $page = gzip($page);
                    %header = %hdr_no_cache
                }
                $client->send_response(HTTP::Response->new(RC_OK, undef, [%header], $page));
            }else{
                $client->send_error(RC_NOT_FOUND, qq(No such WEB PerlCNF file -> <b>$local_path</b><br>
                                                     <img src='images/RC_NOT_FOUND.jpeg'/>"<br>
                                                     <a href="/">Back Home</a>))
            }
        }
        elsif($r->method eq 'GET' and $r->uri->path =~ /\/configs\/docs\/(.*)\.html|htm$/i){
            if(-f  $local_path ){        
                open (my$fh,'<',$local_path);                
                my $page = <$fh>;
                close $fh;
                my %header = %hdr;
                if ($config->{'UseCompression'} && $r->header('Accept-Encoding') =~ m/gzip/){ 
                    $page = gzip($page);
                    %header = %hdr_no_cache
                }
                $client->send_response(HTTP::Response->new(RC_OK, undef, [%header], $page));
                &log("send:$local_path\n");
            }else{
                $client->send_error(RC_NOT_FOUND, qq(No such file -> <b>$local_path</b><br>
                                                     <img src='images/RC_NOT_FOUND.jpeg'/>"<br>
                                                     <a href="/">Back Home</a>))
            }
        }
        elsif($r->method eq 'GET' and $r->uri->path =~ /\/configs\/docs\/.*(.*)$/){
            if(-f  $local_path ){
                $client->send_response(HTTP::Response->new(RC_OK),undef, %hdr); 
                $client->send_file($local_path);               
                &log("send:$local_path\n");
            }else{
                $client->send_error(RC_NOT_FOUND)
            }
        }
        # elsif($r->method eq 'GET' and $r->uri->path =~ /\/configs\/docs\/.*(.*)$/){
        #     if(-f  $local_path ){
        #         my $content;
        #         #$semaphore->up();
        #         open my $fh, "<", $local_path or die ("$!->$local_path"); 
        #         local $/ = undef;
        #         $content = <$fh>;
        #         close $fh;            
        #         $client->send_response(HTTP::Response->new(RC_OK, undef, [%hdr], $content));
        #        # $semaphore->down();
        #         &log("send:$local_path\n");
        #     }else{
        #         $client->send_error(RC_NOT_FOUND)
        #     }
        # }
        elsif($r->method eq 'GET' and $local_path eq 'favicon.ico'){
            $client->send_response(HTTP::Response->new(RC_OK)); 
        }
        else {
            $client->send_error(RC_FORBIDDEN)
        }
        }
        $semaphore -> up();
        $client->close;
        undef($client);        
    }
}catch{
    &log("Server closed by FATAL ERROR:$@");    
    $server->close(); 
}

###
# Obtains the file list in html format.
# TODO - Formatting shouldn't be done from here, but rather from the HTMLProcessorPlugin only.
#        The configs/ directory shouldn't also be bound into the server code, throughout.
##
sub getFileList {
    my $relative = shift;
    my $ret;
    my @docs = glob('configs/docs/*.cnf');
    foreach my $lnk(@docs){        
        ($lnk =~ /configs\/docs\/(.*)\.cnf$/);
        my $n = $1;
        $lnk  =~ s/configs\/docs\/// if $relative;
        $ret .= qq(<a href="$lnk">$n</a>\n);
    }
    return  $ret;
}

sub interrupt {    
    &log("Server closed by interruption.");
    $server->close();
	exit 0;
};

sub log {
	my $message = shift;
    my $attach = join @_; $message .= $attach if $attach;
	(my $sec, my $min, my $hour, my $mday, my $mon, my $year) = gmtime();
	$mon++;
	$mon   = sprintf("%0.2d", $mon);
	$mday  = sprintf("%0.2d", $mday);
	$hour  = sprintf("%0.2d", $hour);
	$min   = sprintf("%0.2d", $min);
	$sec   = sprintf("%0.2d", $sec);
	$year += 1900;
	my $time = qq{$year/$mon/$mday $hour:$min:$sec};
    
    say $time . " " . $message if $log{console};
    if($log{enabled}&&$message){
        open (my $fh, ">>", $log{file}) or die ("$!");
        print $fh $time . " - " . $message ."\n";
        close $fh;
    }
}