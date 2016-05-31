package WorxInteractor;

use File::Slurp qw(read_file);
use JSON qw(from_json);
use LWP::UserAgent;
use Moose;
use Method::Signatures;
use Readonly;

Readonly my $_CONFIG_FILE => q{sites.json};

has _config => {
                 'is'      => 'ro',
                 'isa'     => 'HashRef',
                 'builder' => '_build_config',
                 'lazy'    => 1,
};

has _browser => {
                  'is'      => 'ro',
                  'isa'     => 'LWP::UserAgent',
                  'default' => sub { return LWP::UserAgent->new },
                  'lazy'    => 1,
};

has username => {
                  'is'       => 'ro',
                  'isa'      => 'Str',
                  'required' => 1,
};

has password => {
                  'is'       => 'ro',
                  'isa'      => 'Str',
                  'required' => 1,
};

method _build_config()
{
	return from_json read_file $_CONFIG_FILE;
}



