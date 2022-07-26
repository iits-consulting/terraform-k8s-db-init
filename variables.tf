variable "pod_config" {
  type = object({
    namespace        = optional(string)
    namespace_create = optional(bool)
    name             = optional(string)
    image            = optional(string)
    annotations      = optional(map(string))
    labels           = optional(map(string))
  })
  default = null
}

locals {
  pod_config = defaults(var.pod_config, {
    namespace        = "database"
    namespace_create = true
    name             = "db-init"
    image            = "alpine:3.15.5"
  })
}

variable "database_root_credentials" {
  type = object({
    username = string
    password = string
    address  = string
    port     = optional(number)
    database = optional(string)
  })
  description = "Database root access credentials."
}

locals {
  defaults = {
    mysql = {
      port     = 3306
      database = "mysql"
    }
    postgres = {
      port     = 5432
      database = "postgres"
    }
    mariadb = {
      port     = 3306
      database = "mysql"
    }
  }
  database_root_credentials = defaults(var.database_root_credentials, {
    database = ""
    port = 0
  })
  root_credentials = {
    username = local.database_root_credentials.username
    password = local.database_root_credentials.password
    address  = local.database_root_credentials.address
    database = local.database_root_credentials.database == "" ? local.defaults[var.database_engine].database : local.database_root_credentials.database
    port     = local.database_root_credentials.port  == 0 ? local.defaults[var.database_engine].port : local.database_root_credentials.port
  }
}

variable "initdb_script" {
  type        = string
  description = "The initial SQL script."
}

variable "database_engine" {
  type        = string
  description = "The name of the database engine"
  validation {
    condition     = contains(["postgres", "mysql", "mariadb"], var.database_engine)
    error_message = "Invalid database_engine provided. Valid engines are: postgres, mysql, mariadb."
  }
}

locals {
  db_engines = {
    postgres = {
      client  = "postgresql-client"
      command = "psql"
      env_vars = {
        PGHOST     = local.root_credentials.address
        PGPORT     = local.root_credentials.port
        PGDATABASE = local.root_credentials.database
        PGUSER     = local.root_credentials.username
        PGPASSWORD = local.root_credentials.password
      }
    }
    mysql = {
      client  = "mysql-client"
      command = "mysql --user=${local.root_credentials.username} --password=$MYSQL_PASSWORD"
      env_vars = {
        MYSQL_HOST     = local.root_credentials.address
        MYSQL_TCP_PORT = local.root_credentials.port
        MYSQL_PASSWORD = local.root_credentials.password
      }
    }
    mariadb = {
      client  = "mariadb-client"
      command = "mariadb --user=${local.root_credentials.username} --password=$MYSQL_PASSWORD"
      env_vars = {
        MYSQL_HOST     = local.root_credentials.address
        MYSQL_TCP_PORT = local.root_credentials.port
        MYSQL_PASSWORD = local.root_credentials.password
      }
    }
  }
}

