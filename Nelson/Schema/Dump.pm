package Nelson::Schema::Dump;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("dump");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "bigint",
    default_value => "nextval('seqdumpid'::regclass)",
    is_nullable => 0,
    size => 8,
  },
  "text",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "user",
  {
    data_type => "character varying",
    default_value => "'?'::character varying",
    is_nullable => 0,
    size => 28,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("dump_text_key", ["text"]);
__PACKAGE__->add_unique_constraint("dump_pkey", ["id"]);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-03-21 16:47:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OSDx/deZovSNCHwMneX7Og


# You can replace this text with custom content, and it will be preserved on regeneration
1;
