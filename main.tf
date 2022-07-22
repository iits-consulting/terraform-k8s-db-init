locals {
  databases = [
    "mordor",
    "test",
  ]
}

resource "random_password" "database_passwords" {
  for_each = local.databases

  length      = 32
  special     = false
  min_lower   = 1
  min_numeric = 1
  min_upper   = 1
}

module "db-init" {
  source          = "./db-init"
  database_engine = "postgres"
  database_root_credentials = {
    username = "root"
    password = "root"
    address  = "localhost"
  }
  initdb_script = templatefile("./initdb.sql", {
    databases = [for database in local.databases : {
      name     = database
      username = database
      password = random_password.database_passwords[database].result
    }]
  })
}
