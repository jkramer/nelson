package Nelson::Schema::Scrobble;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("scrobble");
__PACKAGE__->add_columns(
  "user",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 28,
  },
  "login",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 28,
  },
  "time",
  { data_type => "bigint", default_value => 0, is_nullable => 1, size => 8 },
  "track",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 1,
    size => 128,
  },
);
__PACKAGE__->set_primary_key("user");
__PACKAGE__->add_unique_constraint("scrobble_pkey", ["user"]);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-03-21 16:47:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RmEkkC568RVTVzlM9dfwOw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
