package WorxJS::WorxInteractor;

use File::Slurp qw(read_file);
use JSON qw(from_json);
use LWP::UserAgent;
use Moose;
use Method::Signatures;
use Readonly;

Readonly my $_CONFIG_FILE => q{sites.json};

has _config => (
                 'is'      => 'ro',
                 'isa'     => 'HashRef',
                 'builder' => '_build_config',
                 'lazy'    => 1,
);

has _browser => (
                  'is'      => 'ro',
                  'isa'     => 'LWP::UserAgent',
                  'default' => sub { return LWP::UserAgent->new },
                  'lazy'    => 1,
);

has username => (
                  'is'       => 'ro',
                  'isa'      => 'Str',
                  'required' => 1,
);

has password => (
                  'is'       => 'ro',
                  'isa'      => 'Str',
                  'required' => 1,
);

method _get_matrix()
{
	my $matrix_page = $self->_config()->{'matrix'};
	my $req = HTTP::Request->new('POST' => $matrix_page);

	my $res = $self->_browser()->request($req);

	my $page = $res->content;

	return $page; # TODO Parse this into a data structure
}

method _submit_signups()
{
	my $signup_page = $self->_config()->{'signup'};
	my $req = HTTP::Request->new('POST' => $signup_page);

	#TODO Actually submit useful data?
#	my $res = $self->_browser()->request($req);

	return;
}

method _build_config()
{
	return from_json read_file $_CONFIG_FILE;
}

method is_password_valid()
{
	my $signup_page = $self->_config()->{'signup'};
	my $req = HTTP::Request->new('POST' => $signup_page);

	my $res = $self->_browser()->request($req);

	my $page = $res->content;

	return $page; # TODO Check that we get valid logged in/not logged in from here (Also name, possibly?)
}

1;

