# Define: galera::db
#
# This module creates database instances, a user, and grants that user
# privileges to the database.  It can also import SQL from a file in order to,
# for example, initialize a database schema.
#
# Since it requires class galera::server, we assume to run all commands as the
# root galera user against the local galera server.
#
# Parameters:
#   [*title*]       - galera database name.
#   [*user*]        - username to create and grant access.
#   [*password*]    - user's password.
#   [*charset*]     - database charset.
#   [*host*]        - host for assigning privileges to user.
#   [*grant*]       - array of privileges to grant user.
#   [*enforce_sql*] - whether to enforce or conditionally run sql on creation.
#   [*sql*]         - sql statement to run.
#
# Actions:
#
# Requires:
#
#   class galera::server
#
# Sample Usage:
#
#  galera::db { 'mydb':
#    user     => 'my_user',
#    password => 'password',
#    host     => $::hostname,
#    grant    => ['all']
#  }
#
define galera::db (
  $user,
  $password,
  $charset     = 'utf8',
  $host        = 'localhost',
  $grant       = 'all',
  $sql         = '',
  $enforce_sql = false
) {

  mysql_database { $name:
    ensure   => present,
    charset  => $charset,
    provider => 'mysql',
    require  => Class['galera'],
  }

  database_user { "${user}@${host}":
    ensure        => present,
    password_hash => mysql_password($password),
    provider      => 'mysql',
    require       => Mysql_database[$name],
  }

  mysql_grant { "${user}@${host}/${name}":
    privileges => $grant,
    provider   => 'mysql',
    require    => Database_user["${user}@${host}"],
    table      => '*.*',
    user       => "${user}@${host}",
  }

  $refresh = ! $enforce_sql

  if $sql {
    exec{ "${name}-import":
      command     => "/usr/bin/mysql ${name} < ${sql}",
      logoutput   => true,
      refreshonly => $refresh,
      require     => Mysql_grant["${user}@${host}/${name}"],
      subscribe   => Mysql_database[$name],
    }
  }

}
