package Nelson::Schema::Score;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("score");
__PACKAGE__->add_columns(
  "key",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 128,
  },
  "score",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
);
__PACKAGE__->set_primary_key("key");
__PACKAGE__->add_unique_constraint("score_key_key1", ["key"]);
__PACKAGE__->add_unique_constraint("score_key_key", ["key"]);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-03-21 16:47:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+lzFBmWsBuuHHAq2LWWZpw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
