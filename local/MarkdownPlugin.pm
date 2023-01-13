package MarkdownPlugin;

use strict;
use warnings;
use Syntax::Keyword::Try;
use Exception::Class ('MarkdownPluginException');
use feature qw(signatures);
use Date::Manip;

our $TAB = ' 'x4;

sub new ($class, $fields={Language=>'English',DateFormat=>'US'}){      

    if(ref($fields) eq 'REF'){
       warn "Hash reference required as argument for fields!"
    }
    my $lang =   $fields->{'Language'};
    my $frmt =   $fields->{'DateFormat'};
    Date_Init("Language=$lang","DateFormat=$frmt");            
    $fields->{'disk_load'} = 0 if not exists $fields->{'disk_load'};
   
    return bless $fields, $class
}

###
# Process config data to contain expected fields and data.
###
sub convert ($self, $parser, $property) {
try{
    my $file = $parser->anon($property);
    die "Markdown file for [$property] '$file' not found specified!" if !$file; 

    my $script = do {
       open my $fh, '<:encoding(UTF-8)', $file or MarkdownPluginException->throw("File not avaliable: $file");
       local $/;
       <$fh>;    
    };
    
    my @doc = @{parse($self,$script)};

    $parser->data()->{$property} =  $doc[0];
    $parser->data()->{$property.'_headings'} = $doc[1];
   
}catch{
        MarkdownPluginException->throw(error=>$@ ,show_trace=>1);
}}



sub parse ($self, $script){

    my ($buffer, $para, $ol, $lnc); 
    my @list; my $ltype=0;  my $nix=0;my $nplen=0;
    my @titels;
    $script =~ s/^\s*|\s*$//;
    foreach my $ln(split(/\n/,$script)){        
        $ln =~ s/\t/$TAB/gs; $lnc++;
        if($ln =~ /^\s*(#+)(.*)/){
            my $h = 'h'.length($1);
            my $title = $2; 
            $titels[@titels] = {$lnc,$title};
            $buffer .= qq(<$h>$title</$h><a name=").scalar(@titels)."\"/>\n"
        }
        elsif($ln =~ /^(\s+)(\d+)\.\s(.*)/ || $ln =~ /^(\s+)([-+*])\s(.*)/){
            my @arr;
            my $spc = length($1);
            my $val = ${style($3)};
            $ltype  = $2 =~ /[-+*]/ ? 1:0;            
            if($spc>$nplen){            
               $nplen = $spc;               
               $list[@list] = \@arr;
               $nix++;
            }elsif($spc<$nplen){
               $nix--; 
            }
            if($list[$nix-1]){
                @arr = @{$list[$nix-1]};                        
                $arr[@arr] = $ltype .'|'.$val;
                $list[$nix-1] = \@arr;
            }else{
                $arr[@arr] = $ltype .'|'.$val;
                $list[@list] = \@arr;
            }
            
        }elsif($ln =~ /^\s+\</ ){
            $ln =~ s/^\s*\<//;
            $para .= ${style($ln)}." ";            
        }
        elsif($ln =~ /^\s*\*\*\*/){
            if($para){
                $para .= qq(<hr>\n)
            }else{
                $buffer .= qq(<hr>\n)
            }
        }
        elsif($ln =~ /^\s*(.*)/ && length($1)>0){
            $para .= ${style($1)}."<br>\n";
        }else{
            $ln =~ s/^\s*//;
            if(@list){
                if($para){
                   my @arr;
                   if($list[$nix-1]){
                        @arr = @{$list[$nix-1]};
                        $arr[@arr] = '2|'.$para;
                        $list[$nix-1] = \@arr; 
                   }else{
                        $arr[@arr] = '2|'.$para;
                        $list[@list] = \@arr;
                   }
                   $para=""
                }
               $buffer .= createList(0,$ltype,\@list);
               undef @list; $nplen = 0
            }
            elsif($para){
               $buffer .= qq(<p>$para</p>\n);
               $para=""
            }else{
               $buffer .= qq(<br>\n);
            }
        }
    }
    $buffer .= createList(0,$ltype,\@list) if(@list);
    $buffer .= qq(<p>$para</p>\n) if $para;    

return [\$buffer,\@titels]
}

my @LIST_ITEM_TYPE = ('ol','ul','blockquote');

sub createList ($nested,$type,@list){
    $nested++;
    my ($bf,$tabs) =("", " "x$nested);
    my $tag = $LIST_ITEM_TYPE[$type];

    foreach my $arr(@list){
            $bf .= qq($tabs<$tag>\n) if $nested>1;
            foreach my $li(@$arr){
                if(ref($li) eq 'ARRAY'){
                    $bf =~ s/\s<\/($tag)>\s$//gs if $bf;
                    my $r = $1;
                    my @lst = \@$li;
                    my $typ = get_list_type(@lst);
                    $bf .= createList($nested,$typ,@lst);
                    $bf .= qq($tabs</$tag>\n) if($r)                    
                }else{
                    $li =~ s/^(\d)\|//;
                    if($1 == 2){
                        $bf .= "$tabs<blockquote>$li</blockquote>\n"
                    }else{
                        $bf .= "$tabs<li>$li</li>\n"
                    }
                }
            }
            $bf .= qq($tabs</$tag>\n) if $nested>1;
    }
    return $bf
}

sub get_list_type (@list){
    foreach my $arr(@list){
        foreach my $li(@$arr){
            if($li =~ /^(\d)|/){
                return $1;
            }
            last;
        }
    }
    return 0;
}

sub style ($script){
    MarkdownPluginException->throw("Invalid argument!") if !$script;
    #Links <https://duckduckgo.com>
    $script =~ s/<(http[:\/\w.]*)>/<a href=\"$1\">$1<\/a>/g;
        
    my @result = map {
        s/\*\*(.*)\*\*/\<em\>$1<\/em\>/;
        s/\*(.*)\*/\<strong\>$1<\/strong\>/;
        s/__(.*)__/\<del\>$1<\/del\>/;
        s/~~(.*)~~/\<strike\>$1<\/strike\>/;        
        $_
    } split(/\s/,$script); 
    
    my $ret = join(' ',@result);    
    #Images
    $ret =~ s/!\[(.*)\]\((.*)\)/\<img src=\"$2\"\>$1\<\/img\>/;
    #Links [Duck Duck Go](https://duckduckgo.com)
    $ret =~ s/\[(.*)\]\((.*)\)/\<a href=\"$2\"\>$1\<\/a\>/;
    return \$ret;
}

#




1;