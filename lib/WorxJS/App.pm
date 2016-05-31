package WorxJS::App;
use Dancer2;
use Dancer2::Plugin::Ajax;

our $VERSION = '0.1';

get '/' => sub
{
	template 'index';
};

set Serializer => 'JSON';

get '/ping' => sub
{
	to_json({'pong'});
#	return to_xml({'pong'}, RootName => undef);
};

get '/signups' => sub
{
	template 'index';
};

true;
