package WorxJS::App;

use 5.020;
use Dancer2;
use Dancer2::Plugin::Ajax;
use Method::Signatures;

use WorxJS::WorxInteractor;

our $VERSION = '0.1';

func username()
{
	return request->header('x-akbar-username');
}

func password()
{
	return request->header('x-akbar-password');
}

func interactor()
{
	return WorxJS::WorxInteractor->new('username' => username(), 'password' => password());
}

get '/' => sub
{
	set layout => 'main';
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

ajax '/worx/matrix' => sub
{
	header( 'Content-Type' => 'application/json' );
	return send_error('Login incomplete', 502) unless ( password() && username() );
	return to_json interactor->matrix('month' => params->{'month'});
};

ajax '/worx/password_check' => sub
{
	header( 'Content-Type' => 'application/json' );
	return send_error('Login incomplete', 502) unless ( password() && username() );
	if ( interactor->is_password_valid() )
	{
		return to_json({'success' => 1});
	}
	else
	{
		return send_error 'Login failed', 503;
	}
};

ajax '/worx/submit_signups' => sub
{
	header( 'Content-Type' => 'application/json' );
	return send_error('Login incomplete', 502) unless ( password() && username() );
	my $interactor = interactor();
	if ( $interactor->is_password_valid() )
	{
		say 'Month: ' . params->{'month'};
		my @days = split q{,}, params->{'days'};
		say 'Days: '  . "@days";
		return to_json( $interactor->submit_signups('month' => params->{'month'}, 'days' => \@days) );
	}
	else
	{
		return send_error 'Login failed', 503;
	}
};

true;
