-- [Problem 1.3]

DROP TABLE IF EXISTS installed_on;
DROP TABLE IF EXISTS requests;
DROP TABLE IF EXISTS package;
DROP TABLE IF EXISTS preferred_acct;
DROP TABLE IF EXISTS basic_acct;
DROP TABLE IF EXISTS account;
DROP TABLE IF EXISTS dedicated_server;
DROP TABLE IF EXISTS shared_server;
DROP TABLE IF EXISTS server;

/*
 * This table represents a server managed by the hosting provider.
 */
CREATE TABLE server (
    hostname VARCHAR(40) PRIMARY KEY,
    os_type  VARCHAR(20) NOT NULL,

    -- Maximum number of sites that can be stored on the machine
    max_num_sites INT NOT NULL,

    -- A single character 'S' or 'D' indiciating whether the server is shared or
    -- dedicated
    server_type CHAR(1) NOT NULL,

    -- Create a superkey to enforce disjoint specialization constraint
    -- through foreign key from subclasses
    UNIQUE (hostname, server_type),

    -- Check the value of server_type is valid
    CHECK (server_type IN ('S', 'D'))
);

/*
 * This table represents a shared server.
 */
CREATE TABLE shared_server (
    hostname VARCHAR(40) PRIMARY KEY,
    server_type CHAR(1) NOT NULL,

    -- Ensure its corresponding row in server (superclass) has the same type
    FOREIGN KEY (hostname, server_type)
    REFERENCES server (hostname, server_type),

    -- Ensure its server_type value is 'S'
    CHECK (server_type = 'S')
);

/*
 * This table represents a dedicated server.
 */
CREATE TABLE dedicated_server (
    hostname VARCHAR(40) PRIMARY KEY,
    server_type CHAR(1) NOT NULL,

    -- Ensure its corresponding row in server (superclass) has the same type
    FOREIGN KEY (hostname, server_type)
    REFERENCES server (hostname, server_type),

    -- Ensure its server_type value is 'D'
    CHECK (server_type = 'D')
);

/*
 * This table represents a customer account.
 */
CREATE TABLE account (
    username VARCHAR(20) PRIMARY KEY,
    email VARCHAR(200) NOT NULL,

    -- URL of their website required to be unique
    url VARCHAR(200) NOT NULL UNIQUE,

    -- Timestamp that the customer opened an account with the provider
    time_joined TIMESTAMP NOT NULL DEFAULT NOW(),

    -- Monthly subscription price that the customer must pay, specified on a
    -- per-customer basis
    subs_price NUMERIC(6, 2) NOT NULL,

    -- A single character 'B' or 'P' indicating whether the account is basic or
    -- preferred
    acct_type CHAR(1) NOT NULL,

    -- Create a superkey to enforce disjoint specialization constraint
    -- through foreign key from subclasses
    UNIQUE (username, acct_type),

    -- Check the value of acct_type is valid
    CHECK (acct_type IN ('B', 'P'))
);


/*
 * This table represents a basic account that gets shared hosting.
 */
CREATE TABLE basic_acct (
    username VARCHAR(20) PRIMARY KEY,
    acct_type CHAR(1) NOT NULL,

    -- Hostname of associated shared server
    -- NOT NULL constraint to enforce that every basic acct must be associated
    -- with a shared server
    hostname VARCHAR(40) NOT NULL,

    -- Ensure its associated server is in shared_server
    FOREIGN KEY (hostname) REFERENCES shared_server (hostname),

    -- Ensure its corresponding row in account (superclass) has the same type
    FOREIGN KEY (username, acct_type) REFERENCES account (username, acct_type),

    -- Ensure its acct_type value is 'B'
    CHECK (acct_type = 'B')
);

/*
 * This table represents a preferred account that gets dedicated hosting.
 */
CREATE TABLE preferred_acct (
    username VARCHAR(20) PRIMARY KEY,
    acct_type CHAR(1) NOT NULL,

    -- Hostname of associated dedicated server
    -- NOT NULL constraint to enforce that every preferred acct must be
    -- associated with a dedicated server
    -- UNIQUE constraint to enforce that a single dedicated server can't be
    -- associated with multiple preferred accounts
    hostname VARCHAR(40) NOT NULL UNIQUE,

    -- Ensure its associated server is in dedicated_server
    FOREIGN KEY (hostname) REFERENCES dedicated_server (hostname),

    -- Ensure its corresponding row in account (superclass) has the same type
    FOREIGN KEY (username, acct_type) REFERENCES account (username, acct_type),

    -- Ensure its acct_type value is 'P'
    CHECK (acct_type = 'P')
);


/*
 * This table represents a software package the company provides to the
 * customers.
 */
CREATE TABLE package (
    package_name VARCHAR(40),
    version VARCHAR(20),

    -- A brief description of the package
    description VARCHAR(1000) NOT NULL,

    -- The monthly price that customers pay for using the software package
    package_price NUMERIC(6, 2) NOT NULL,

    -- The combination of (package_name, version) must be unique
    PRIMARY KEY (package_name, version)
);


/*
 * This table stores relationships between customers and packages requested by
 * the customers.
 */
CREATE TABLE requests (
    username VARCHAR(20),
    package_name VARCHAR(40),
    version VARCHAR(20),

    PRIMARY KEY (username, package_name, version),

    -- Ensure user exists
    FOREIGN KEY (username) REFERENCES account (username),

    -- Ensure package exists
    FOREIGN KEY (package_name, version)
    REFERENCES package (package_name, version)
);


/*
 * This table stores relationships between packages and servers the packages
 * are installed on.
 */
CREATE TABLE installed_on (
    package_name VARCHAR(40),
    version VARCHAR(20),
    hostname VARCHAR(40),

    PRIMARY KEY (package_name, version, hostname),

    -- Ensure the package exists
    FOREIGN KEY (package_name, version)
    REFERENCES package (package_name, version),

    -- Ensure the server exists
    FOREIGN KEY (hostname) REFERENCES server (hostname)
);
