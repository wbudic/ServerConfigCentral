#!/usr/bin/env perl
use warnings; use strict; 
use lib "./tests";
use lib "/home/will/dev/ServerConfigCentral/local";

require TestManager;
require CNFParser;
require CNFNode;

my $test = TestManager->new($0);

use Syntax::Keyword::Try; try {

    ###
    # Test instance creation.
    ###
    die $test->failed()  if not my $node = CNFNode->new({'_'=>'node','#'=>1});
    $test->evaluate("name==node",$node->name(),'node');
    $test->evaluate("val==1",$node->val(),1);
    $test->case("Passed new instance for CNFParser.");
    #
    #  
    $test-> nextCase();
    #

    ###
    # Test validation.
    ###
    $test->case("Testing validation.");

    $test->subcase('Misclosed property.');

    my $errors = $node -> validate(qq(
        [a[
            [b[
                <e<
                [#[some value]#]
            ]b]
            >e>
        ]a]

    ));

    $test->subcase('Unclosed property.');

   $node -> validate(qq(
        [a[
            [b[
                <e<
                [#[some value]#]
            ]b]            
        ]a]
        ]c]

    )); 

    $test->subcase('Fully valid property.');
    
    $node -> validate(qq(
        [a[
            [b[        
                [#[some value]#]
            ]b]            
        ]a]
        

    )); 

    $test->subcase('Knownn to fail but but valid property.');

    $node -> validate(qq(
[span[
    [#[]#]
]span]
<a<
    [#[]#]
>a>
    ));

    $node -> validate(qq(
<body<
    [nest[
        [tag1[    
        ]tag1]
        [tag2[    
        ]tag2]
        [tag3[    
        ]tag3]
    ]nest]
>body>

    ));    

$node -> validate(qq(
[row[        
    [cell[            
        [h3[ Other Available Pages ]h3]
        [span[
            [#[ 
                [
            ]#]
        ]span]
        <a<
            href = /
            [#[Home]#]
        >a>
        [span[
            [#[] |]#]
        ]span]              
        [*[file_list_html]*]  
    ]cell]
]row]
>fail>
));  

$node -> validate(qq(
    [row[        
        [cell[   
            style: text-align:center; background:#00ffff0d
            [h2[HOME PAGE]h2]
        ]cell]
    ]row]
    [row[        
        [cell[            
            [img[                    
            ]img]
            <div<
            >div>
            [div2[

            ]div2]
        ]cell]
    ]row]
    [row[        
        [cell[            
            [h3[ Available Pages ]h3] 
            [*[file_list_html]*]  
        ]cell]
    ]row]
)); 



$node -> validate(qq(
    [row[
        [cell[
            [div[
                <img<
                        src  =  images/PerlCNF.png
                        style= "float:right"
                >img>
                
                <p<
                    style: vertical-align:middle;
                    <#<
                        To contact as you need the details, that have been emailed to you.
                    >#>
                >p>
            ]div]
        ]cell]
    ]row] 
));


    #
    $test-> nextCase();
    #

    
    

    #
    $test->done();
    #
}
catch{ 
   $test -> dumpTermination($@);   
   $test->doneFailed();
}


