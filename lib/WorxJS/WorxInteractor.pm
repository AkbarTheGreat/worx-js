package WorxJS::WorxInteractor;

use File::Slurp qw(read_file);
use JSON qw(from_json to_json);
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

has _user_data => (
                  'is'      => 'ro',
                  'isa'     => 'HashRef',
                  'builder' => '_get_user_data',
                  'lazy'    => 1,
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

method _get_user_data()
{
	my $login_data = $self->_config()->{'login_data'};

	my $data = { 'from'     => 'login1',
	             'secure'   => 'go',
	             'username' => $self->username(),
	};

	my $res = $self->_browser()->post($login_data, $data);


	use Data::Printer;

	my @inputs =$res->content =~ /\<input (.*)\/>/g;
	my %data;

	for my $input ( @inputs )
	{
		next unless $input =~ /name="([^"]*)"/;
		my $name = $1;
		next if $name eq 'logon';
		next if $name eq 'from';
		next if $name eq 'pw_entered';
		next if $name eq 'username';
		next unless $input =~ /value="([^"]*)"/;
		my $value = $1;
		$data{$name} = $value;
	}
	$data{'password'} = $data{'pw_in_data'};
	return \%data;
}

method is_password_valid()
{
	return 1 if ($self->password eq $self->_user_data()->{'password'});
	return;
}

1;

