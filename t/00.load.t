use Test::More tests => 3;

BEGIN {
use_ok( 'Catalyst::Controller::PagingAndSort' );
use_ok( 'Catalyst::Helper::Controller::PagingAndSort' );
use_ok( 'Catalyst::Helper::Model::CDBISweet' );
}

diag( "Testing Catalyst::Example::PagingAndSort $Catalyst::Controller::PagingAndSort::VERSION" );
