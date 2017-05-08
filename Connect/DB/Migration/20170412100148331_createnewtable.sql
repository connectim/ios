-- Table: t_taglistt
CREATE TABLE t_tag (
id        INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
tag       VARCHAR (256) NOT NULL UNIQUE
);

-- Table: t_usertag
CREATE TABLE t_usertag (
id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
tag_id           INTEGER,
address          VARCHAR (256) NOT NULL
);

-- Table: t_recommand_friend
CREATE TABLE t_recommand_friend (
id INTEGER       PRIMARY KEY AUTOINCREMENT NOT NULL,
address          VARCHAR (256) NOT NULL UNIQUE,
pub_key          VARCHAR (256) NOT NULL UNIQUE,
username         VARCHAR (256) NOT NULL,
avatar           VARCHAR (256) NOT NULL,
status           INTEGER DEFAULT 0
);

-- Table: t_addressbook
CREATE TABLE t_addressbook (
id               INTEGER       PRIMARY KEY AUTOINCREMENT NOT NULL,
address          VARCHAR (256) NOT NULL  UNIQUE,
tag              VARCHAR (256),
create_time      INTEGER
);
-- Table: t_newfriendrequest
CREATE TABLE t_friendrequest (
id                     INTEGER       PRIMARY KEY AUTOINCREMENT NOT NULL,
address                VARCHAR (256) NOT NULL UNIQUE,
pub_key                VARCHAR (256) NOT NULL UNIQUE,
avatar                 VARCHAR (256),
username               VARCHAR (256),
source                 INT           DEFAULT 0,
status                 INT           DEFAULT 0,
read                   INT           DEFAULT 0,
tips 				   VARCHAR (256),
createtime             INTEGER       DEFAULT 0
);

-- Table: t_group_information
CREATE TABLE t_group(
id           INTEGER       PRIMARY KEY AUTOINCREMENT NOT NULL,
identifier   VARCHAR (256) NOT NULL UNIQUE,
name         VARCHAR (256),
ecdh_key     VARCHAR (256) NOT NULL,
common       INTEGER     DEFAULT 0,
verify       INTEGER     DEFAULT 0,
pub          INTEGER     DEFAULT 0,
avatar       VARCHAR (256) NOT NULL,
summary      VARCHAR (256)
);

-- Table: t_group_member
CREATE TABLE t_group_member (
id    INTEGER       PRIMARY KEY AUTOINCREMENT NOT NULL,
identifier          VARCHAR (256) NOT NULL,
username            VARCHAR (256) NOT NULL,
avatar              VARCHAR (256) NOT NULL,
address             VARCHAR (256) NOT NULL,
role                INTEGER DEFAULT 0,
nick                VARCHAR (256),
pub_key             VARCHAR (256) NOT NULL
);
-- Table: t_group_member unique index
CREATE UNIQUE INDEX [] ON t_group_member (
identifier,
address
);

-- Table: t_transactiontable
CREATE TABLE t_transactiontable (
id              INTEGER       PRIMARY KEY AUTOINCREMENT NOT NULL,
message_id      VARCHAR (256) NOT NULL UNIQUE,
hashid          VARCHAR (256) NOT NULL UNIQUE,
status          INT           DEFAULT 0,
pay_count       INT           DEFAULT 0,
crowd_count     INT           DEFAULT 0
);

-- Table: t_recent_conversion
CREATE TABLE t_conversion (
id                    INTEGER       PRIMARY KEY AUTOINCREMENT NOT NULL,
identifier            VARCHAR (256) NOT NULL UNIQUE,
name                  VARCHAR (256) NOT NULL,
avatar                VARCHAR (256) NOT NULL,
draft            	  TEXT,
stranger              INT           DEFAULT 0,
last_time             INTEGER,
unread_count          INT           DEFAULT 0,
top                   INT           DEFAULT 0,
notice                INT           DEFAULT 0,
type                  INT           DEFAULT 0,
content               TEXT
);

CREATE TABLE t_conversion_setting (
id                    INTEGER       PRIMARY KEY AUTOINCREMENT NOT NULL,
identifier            VARCHAR (256) NOT NULL UNIQUE,
snap_time             INT           DEFAULT 0,
disturb               INT           DEFAULT 0
);

-- Table: t_message
CREATE TABLE t_message (
id INTEGER       PRIMARY KEY AUTOINCREMENT NOT NULL,
message_id       VARCHAR (256) NOT NULL,
message_ower     VARCHAR (256) NOT NULL,
content          TEXT,
send_status      INT           DEFAULT 0,
snap_time        INTEGER       DEFAULT 0,
read_time        INTEGER       DEFAULT 0,
state            INT           DEFAULT 0,
createtime       INTEGER       DEFAULT 0
);

-- Table: t_contact
CREATE TABLE t_contact (
id INTEGER       PRIMARY KEY AUTOINCREMENT NOT NULL,
address          VARCHAR (256) NOT NULL UNIQUE,
pub_key          VARCHAR (256) NOT NULL UNIQUE,
avatar           VARCHAR (256) NOT NULL,
username         VARCHAR (256) NOT NULL ,
remark           VARCHAR (256),
source           INT           DEFAULT 0,
blocked          INT           DEFAULT 0,
common    	     INT           DEFAULT 0
);

-- insert contact info
INSERT OR REPLACE INTO t_contact (pub_key,address,username,avatar) VALUES ('connect','Connect','Connect','connect_logo');
