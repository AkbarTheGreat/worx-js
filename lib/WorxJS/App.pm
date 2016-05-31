package WorxJS::App;

use 5.020;
use Dancer2;
use Dancer2::Plugin::Ajax;

our $VERSION = '0.1';

get '/' => sub
{
	template 'index';
};

get '/worx/ping' => sub
{
	header( 'Content-Type'  => 'application/json' );
	header( 'Cache-Control' =>  'no-store, no-cache, must-revalidate' );
	header( 'Access-Control-Allow-Origin' => '*' );
	to_json( {'pong' => 1} );
};

get '/worx/signups' => sub
{
	template 'signups';
};

true;
