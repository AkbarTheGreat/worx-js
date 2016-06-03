package WorxJS::App;

use 5.020;
use Dancer2;
use Dancer2::Plugin::Ajax;
use Method::Signatures;

use WorxJS::WorxInteractor;

our $VERSION = '0.1';

func username()
{
	return params->{'username'};
}

func password()
{
	return params->{'password'};
}

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

ajax '/worx/password_check' => sub
{
	my $interactor = WorxJS::WorxInteractor->new('username' => username(), 'password' => password());
	header( 'Content-Type' => 'text/json' );
	if ( $interactor->is_password_valid() )
	{
		return to_json({'success' => 1});
	}
	else
	{
		return send_error 'Login failed', 503;
	}
};

true;
