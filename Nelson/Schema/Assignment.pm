package Nelson::Schema::Assignment;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw( InflateColumn::DateTime Core ));
__PACKAGE__->table("assignment");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "bigint",
    default_value => "nextval('seqassignid'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "user",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 28,
  },
  "key",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 64,
  },
  "value",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 512,
  },
  "when",
  {
    data_type => "datetime",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "revision",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 4 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("assign_key_key", ["key", "revision"]);
__PACKAGE__->add_unique_constraint("assign_pkey", ["id"]);



# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-03-21 16:47:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XlfT0cfkIorLx7PnfQPw3g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
