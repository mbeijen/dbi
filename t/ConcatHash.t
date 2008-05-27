# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CatHash.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 36;
BEGIN { use_ok('DBI') };
no warnings 'uninitialized';

# null and undefs -- segfaults?;
is (DBI::_concat_hash_sorted({ }, "=", ":", 0, undef), "");
eval {DBI::_concat_hash_sorted(undef, "=", ":", 0, undef), undef};
like ($@ || "", qr/hash is not a hash reference/); #XXX check this
is (DBI::_concat_hash_sorted({ }, undef, ":", 0, undef), "");

is (DBI::_concat_hash_sorted({ }, "=", undef, 0, undef), "");
is (DBI::_concat_hash_sorted({ }, "=", ":", undef, undef),"");

# Simple segfault tests?
ok(DBI::_concat_hash_sorted({bob=>'two', fred=>'one' }, "="x12000, ":", 1, undef));
ok(DBI::_concat_hash_sorted({bob=>'two', fred=>'one' }, "=", ":"x12000, 1, undef));
ok(DBI::_concat_hash_sorted({map {$_=>undef} (1..1000)}, "="x12000, ":", 1, undef));
ok(DBI::_concat_hash_sorted({map {$_=>undef} (1..10000)}, "=", ":"x12000, 1, undef), 'test');
ok(DBI::_concat_hash_sorted({map {$_=>undef} (1..100)}, "="x12000, ":"x12000, 1, undef), 'test');

my $simple_hash = {
    bob=>"there",
    jack=>12,
     fred=>"there",
     norman=>"there",
    # sam =>undef
};

my $simple_numeric = {
    1=>"there",
    2=>"there",
    3=>"there",
    32=>"there",
    16 => 'yo',
    07 => "buddy",
    49 => undef,
};

my $simple_mixed = {
    bob=>"there",
    jack=>12,
     fred=>"there",
     norman=>"there",
     sam =>undef,
    1=>"there",
    2=>"there",
    3=>"there",
    32=>"there",
    16 => 'yo',
    07 => "buddy",
	    49 => undef,
};

my $simple_float = {
    1.12 =>"there",
    3.1415926 =>"there",
    2.718281828 =>"there",
    32=>"there",
    1.6 => 'yo',
    0.78 => "buddy",
    49 => undef,
};

#eval {
#    DBI::_concat_hash_sorted($simple_hash, "=",,":",1,12);
#};
ok(1," Unknown sort order");
#like ($@, qr/Unknown sort order/, "Unknown sort order");



## Loopify and Add Neat


my %neats = (
    "Neat"=>0, 
    "Not Neat"=> 1
);
my %sort_types = (
    guess=>undef, 
    numeric => 1, 
    lexical=> 0
);
my %hashes = (
    Numeric=>$simple_numeric, 
    "Simple Hash" => $simple_hash, 
    "Mixed Hash" => $simple_mixed,
    "Float Hash" => $simple_float
);

for $sort_type (keys %sort_types){
    for $neat (keys %neats) {
        for $hash(keys %hashes) {
            test_concat_hash($hash, $neat, $sort_type);
        }
    }
}

sub test_concat_hash {
    my ($hash, $neat, $sort_type) = @_;
    is (
        #DBI::_concat_hash_sorted(
        _concat_hash_sorted(
            $hashes{$hash}, "=", ":",$neats{$neat}, $sort_types{$sort_type}
        ),
        _concat_hash_sorted(
            $hashes{$hash} , "=", ":",$neats{$neat}, $sort_types{$sort_type}
        ),
        "$hash - $neat $sort_type"
    );
}

if (0) {
    eval {
        use Benchmark qw(:all);
        cmpthese(200_000, {
	    Perl => sub {_concat_hash_sorted($simple_hash, "=", ":",0,undef); },
	    C=> sub {DBI::_concat_hash_sorted($simple_hash, "=", ":",0,1);}
        });

        print "\n";
        cmpthese(200_000, {
  	    NotNeat => sub {DBI::_concat_hash_sorted(
                $simple_hash, "=", ":",1,undef);
            },
	    Neat    => sub {DBI::_concat_hash_sorted(
                $simple_hash, "=", ":",0,undef);
            }
        });
    };

}
#CatHash::_concat_hash_values({ }, ":-",,"::",1,1);


sub _concat_hash_sorted {
    my ( $hash_ref, $kv_separator, $pair_separator, $value_format, $sort_type ) = @_;
    # $value_format: false=use neat(), true=dumb quotes
    # $sort_type: 0=lexical, 1=numeric, undef=try to guess

    $keys = _get_sorted_hash_keys($hash_ref, $sort_type);
    my $string = '';
    for my $key (@$keys) {
        $string .= $pair_separator if length $string > 0;
        my $value = $hash_ref->{$key};
        if ($value_format) {
            $value = (defined $value) ? "'$value'" : 'undef';
        }
        else {
            $value = DBI::neat($value,0);
        }
        $string .= $key . $kv_separator . $value;
    }
    return $string;
}

use Scalar::Util qw(looks_like_number);
sub _get_sorted_hash_keys {
    my ($hash_ref, $sort_type) = @_;
    my $sort_guess = 1;
    if (not defined $sort_type) {
        #my $first_key = (each %$hash_ref)[0];
        #$sort_type = looks_like_number($first_key);

        $sort_guess =  
            (1!=looks_like_number($_)) ? 0:$sort_guess for keys %$hash_ref;
        $sort_type = $sort_guess unless (defined $sort_type);
    }
    
    my @keys = keys %$hash_ref;
    no warnings 'numeric';
    return [ ($sort_type && $sort_guess)
        ? sort {$a <=> $b} @keys
        : sort    @keys
    ];
}



#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

