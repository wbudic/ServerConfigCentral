#!/usr/bin/env perl
use warnings; use strict; 
use lib "./tests";
use lib "./local";

require TestManager;
require CNFCentral;
use Syntax::Keyword::Try;


my $test = TestManager -> new($0);
my $central;

try{

    

    ###
    # Test instance creation.
    #
    die $test->failed() if not $central = CNFCentral->new();
    $test->case("Passed new instance CNFCentral.");
    #  
    $test-> nextCase();
    #

    # Test session token.
    die $test->failed()if not my $token = CNFCentral::generateSessionToken();   
    #
    $test->case("Passed CNFCentral::generateSessionToken().");
    $test-> nextCase();    
    #

    ###
    # Test tagCNFToArray from session token.    
    ###
    my @prop = $central->tagCNFToArray($token);
    die $test->failed()if @prop != 3;
    @prop = $central->tagCNFToArray('<<name<value>>>');
    $test->case(join '|', @prop);
    die $test->failed()if @prop != 2;
    $test->subcase("It equals to nb of elements.");
    die $test->failed()if $prop[0] ne 'name' or $prop[1] ne 'value';
    $test->subcase("And they equal 'name' and 'value'");
    
    #
    $test-> nextCase();     
    #

    ###
    # Test static utility.
    #
    @prop = $central->sessionTokenToArray($token);
    $test->case(join '|', @prop);
    die $test->failed() if @prop != 2;
    #


    #
    $test-> nextCase(); 
    #

    ###
    # Test get default repo, which should be the global one.
    #    
    my $global    = $central->getRepo();    
    die $test->failed('Expected $global is undef!') if not $global;   

    
    
        
    #
    $test-> nextCase(); 
    #

    ###
    # Test parse chain of server issued commands.
    #
   die $test->failed()
        if not my $chain = $central->parseCmdChain("auth anon kurac = 'palac ' ");
        $test->case('Passed CNFCentral->parseCmdChain("auth anon kurac = \'palac \' ")');        
    shift @$chain;shift @$chain;
    # I wonder if the following TypeScript kiddies would comprehend? :)
    my $ret = CNFCentral::_processChainedCmd(undef,'global', *AnonTagProperty, @$chain);
    die $test->failed() if $ret ne '<<anon<modified global/kurac>palac >>';
       $test->subcase('(auth anon kurac = \'palac \') eq (<<anon<global/kurac><palac >>)');
       $test->subcase(join '|', @$chain);
    die $test->failed()if not @$chain[-1] eq "= 'palac '";

       $chain = $central->parseCmdChain("auth anon dupe ispod = 'klupe' ");
    die $test->failed()if not $chain; shift @$chain;shift @$chain;
       $ret = CNFCentral::_processChainedCmd(undef,'global', *AnonTagProperty, @$chain);
    die $test->failed() if $ret ne '<<anon<modified dupe/ispod>klupe>>';
       $test->subcase('(auth anon dupe ispod = \'klupe\') eq (<<anon<dupe/ispod><klupe>>)');

       $chain = $central->parseCmdChain("auth anon dupe ispod"); shift @$chain;shift @$chain;
       $ret = CNFCentral::_processChainedCmd(undef,'global', *AnonTagProperty, @$chain);
    die $test->failed("Failed:$ret") if $ret ne '<<anon<dupe/ispod>klupe>>';
       $test->subcase('(auth anon dupe ispod) eq (<<anon<dupe/ispod>>> that is, it is empty.)');

       $chain = $central->parseCmdChain("auth anon ispod"); shift @$chain; shift @$chain;
       $ret = CNFCentral::_processChainedCmd(undef,'global', *AnonTagProperty, @$chain);
    die $test->failed() if $ret ne '<<anon<global/ispod>>>';       
       $test->subcase('(auth anon dupe ispod) eq (<<anon<global/ispod>>>  that is, it is empty or not found.)');

    die $test->failed()if not @$chain == 1;
    #

    #
    $test-> nextCase(); 
    #

    ##
    # Check if in our global rep newly placed anon.
    $chain = $central->parseCmdChain("auth anon JustAnTest = 'Best in the West'"); shift @$chain; shift @$chain;
    $ret = CNFCentral::_processChainedCmd(undef,'global', *AnonTagProperty, @$chain);
    #
    die $test->failed('Anon assignment for \$global failed.') if ( $global->anon('JustAnTest') ne 'Best in the West' );

    #   
    $test->done();    
    #
}
catch{ 
   $test -> dumpTermination($@);   
   $test -> doneFailed();
}

#
#  TESTING THE FOLLOWING IS FROM HERE  #

    sub AnonTagProperty{
        my ($client, $rep_alias, $name, $value)= @_;
        
        my $repo = $central -> getRepo($rep_alias);
        if(!$repo){
        # DISABLED we need to simulate here.    
        #     return "<<error<2>Repository not found for $rep_alias/$name>>";
            $repo = CNFParser->new(undef,{CNF_CONTENT=>$rep_alias});
            $value = $repo->anon($name) if not $value;
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

###
# Test in general session token utility.
###
sub checkGenerateSessionToken {  my $pass = shift;        
    my $t =  CNFCentral::generateSessionToken($pass);    
    $test->case($t);
    die if length($t)<27;
    return $t;
}