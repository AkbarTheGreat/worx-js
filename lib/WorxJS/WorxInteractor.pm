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

	if ($res->is_success)
	{
		die 'SUCCESS' . $res->content;
	}
	else
	{
		die 'FAILURE';
	}
}

method _build_config()
{
	return from_json read_file $_CONFIG_FILE;
}

method is_password_valid()
{
	my $matrix_page = $self->_get_matrix();
}

1;

