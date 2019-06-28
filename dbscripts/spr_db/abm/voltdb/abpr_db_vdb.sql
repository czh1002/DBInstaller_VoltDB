CREATE TABLE ABM_ACCOUNT (
   id                        BIGINT          NOT NULL,
   subscriber_id             BIGINT          NOT NULL,
   name                      VARCHAR(120)    NOT NULL,
   account_type_id           INTEGER         NOT NULL,
   state                     TINYINT,
   effective_date            TIMESTAMP       DEFAULT NOW NOT NULL,
   expire_date               TIMESTAMP,
   create_time               TIMESTAMP,
   last_update_timestamp     TIMESTAMP      DEFAULT NOW NOT NULL,
   last_sync_timestamp       TIMESTAMP,
   state_recycle             VARCHAR(1)     DEFAULT 'A' NOT NULL,
   timer_id                 BIGINT          DEFAULT 0 NOT NULL,
   timer_partition          INTEGER         DEFAULT 0 NOT NULL,
   extended_attributes       VARCHAR(10240),
   CONSTRAINT PK_ABM_ACCOUNT PRIMARY KEY (subscriber_id,id)
);
create index IDX_ABM_ACCOUNT_UPDATETIME on ABM_ACCOUNT(subscriber_id, last_update_timestamp, state_recycle);

CREATE TABLE ABM_ACCOUNT_BALANCE
(
   id                           BIGINT          NOT NULL,
   subscriber_id                BIGINT          NOT NULL,
   account_id                   BIGINT          NOT NULL,
   balance_type_id              INTEGER         NOT NULL,
   priority                     INTEGER         NOT NULL,
   max_balance                  BIGINT          DEFAULT 0 NOT NULL,
   used_balance                 BIGINT          DEFAULT 0 NOT NULL,
   balance_reserved             BIGINT          DEFAULT 0 NOT NULL,
   confirmed_reservation        BIGINT          DEFAULT 0 NOT NULL,
   measurement_type             INTEGER         NOT NULL,
   balance_exponent             INTEGER         DEFAULT -2 NOT NULL,
   currency_code                VARCHAR(3)      DEFAULT 'N/A' NOT NULL,
   state                        TINYINT         NOT NULL,
   effective_date               TIMESTAMP       DEFAULT NOW NOT NULL,
   expire_date                  TIMESTAMP,
   create_time                  TIMESTAMP,
   last_update_timestamp        TIMESTAMP       DEFAULT NOW NOT NULL,
   last_sync_timestamp          TIMESTAMP,
   state_recycle                VARCHAR(1)      DEFAULT 'A' NOT NULL,
   timer_id                 BIGINT              DEFAULT 0 NOT NULL,
   timer_partition          INTEGER             DEFAULT 0 NOT NULL,
   extended_attributes          VARCHAR(10240),
   CONSTRAINT PK_ACCOUNT_BALANCE PRIMARY KEY (subscriber_id,id)
);
create index IDX_HASH_ACCOUNT_BALANCE on ABM_ACCOUNT_BALANCE(account_id);
create index IDX_ACCOUNT_BALANCE_UPDATETIME on ABM_ACCOUNT_BALANCE(subscriber_id, last_update_timestamp, state_recycle);


CREATE TABLE ABM_BALANCE_SHARE_RULE
(
   id                           BIGINT           NOT NULL,
   subscriber_id                BIGINT           NOT NULL,
   account_balance_id           BIGINT           NOT NULL,
   share_rule_type              TINYINT          DEFAULT 0 NOT NULL,
   applicable_object_type       TINYINT          DEFAULT 0 NOT NULL,
   applicable_object_id         BIGINT           NOT NULL,
   applicable_subscriber_id      BIGINT           NOT NULL,
   priority                     INTEGER          DEFAULT 600 NOT NULL,
   effective_date               TIMESTAMP        DEFAULT NOW NOT NULL,
   expire_date                  TIMESTAMP,
   create_time                  TIMESTAMP,
   last_update_timestamp        TIMESTAMP      DEFAULT NOW NOT NULL,
   state_recycle                VARCHAR(1)      DEFAULT 'A' NOT NULL,
   extended_attributes          VARCHAR(10240),
   CONSTRAINT PK_BALANCE_SHARE_RULE PRIMARY KEY (subscriber_id,id)
);
create index IDX_HASH_BALANCE_SHARE_RULE_FK on ABM_BALANCE_SHARE_RULE(applicable_subscriber_id);
create index IDX_HASH_BALANCE_SHARE_RULE on ABM_BALANCE_SHARE_RULE(account_balance_id);
create index IDX_BALANCE_SHARE_RULE_UPDATETIME on ABM_BALANCE_SHARE_RULE(subscriber_id, last_update_timestamp, state_recycle);
create index IDX_BALANCE_SHARE_RULE_CONSUMER on ABM_BALANCE_SHARE_RULE(applicable_object_id, applicable_object_type, state_recycle);




PARTITION TABLE ABM_ACCOUNT ON COLUMN subscriber_id;
PARTITION TABLE ABM_ACCOUNT_BALANCE ON COLUMN subscriber_id;

CREATE TABLE ABM_SOURCE_LOG
(
   id                           BIGINT          NOT NULL,
   subscriber_id                BIGINT          NOT NULL,
   account_balance_id           BIGINT          NOT NULL,
   operation_type               TINYINT         NOT NULL,
   operation_time               TIMESTAMP       DEFAULT NOW NOT NULL,
   amount                       BIGINT          NOT NULL,
   balance_after                BIGINT          NOT NULL,
   extended_validity_period     BIGINT          NOT NULL,
   balance_expire_date_after    TIMESTAMP,
   balance_type_id              INTEGER         NOT NULL,
   balance_measurement          INTEGER         DEFAULT 2 NOT NULL,
   balance_exponent             INTEGER         DEFAULT -2 NOT NULL,
   owned_account_id             BIGINT          NOT NULL,
   currency_code                VARCHAR(3)      DEFAULT 'N/A' NOT NULL,
   operation_info               VARCHAR(255),
   operation_source_system      VARCHAR(64)     NOT NULL,
   operation_source_staff       VARCHAR(64),
   state_before_operation       INTEGER         NOT NULL,
   last_update_timestamp        TIMESTAMP       DEFAULT NOW NOT NULL,
   state_recycle                VARCHAR(1)      DEFAULT 'A' NOT NULL,   
   extended_attributes          VARCHAR(10240),
);

EXPORT TABLE ABM_SOURCE_LOG TO STREAM ABMSourceLog;
PARTITION TABLE ABM_SOURCE_LOG ON COLUMN subscriber_id;


create table ABM_BALANCE_PAYOUT_LOG(
   id                               BIGINT               NOT NULL,
   subscriber_id                    BIGINT               NOT NULL,
   account_balance_id               BIGINT               NOT NULL,
   operation_type                   TINYINT              DEFAULT 1 NOT NULL,
   operation_time                   TIMESTAMP            DEFAULT NOW NOT NULL,
   amount                           BIGINT               NOT NULL,
   balance_after                    BIGINT               NOT NULL,
   Operation_info                   VARCHAR(255),
   balance_type_id                  BIGINT               NOT NULL,
   balance_measurement              INTEGER              DEFAULT 2 NOT NULL,
   balance_exponent                 INTEGER              DEFAULT -2 NOT NULL,
   currency_code                    VARCHAR(3)           DEFAULT 'N/A' NOT NULL,
   account_item_type_id             VARCHAR(20)          NOT NULL,
   billing_cycle_info               VARCHAR(10)          NOT NULL,
   billing_info                     VARCHAR(20),
   account_id                       BIGINT,
   device_id                        BIGINT,
   share_rule_id                    BIGINT,
   account_item_group_id            INTEGER,
   operation_source_system          VARCHAR(64)          NOT NULL,
   operation_source_staff           VARCHAR(64),
   state_recycle                    VARCHAR(1)            DEFAULT 'A' NOT NULL,
   extended_attributes              VARCHAR(10240),
);
EXPORT TABLE ABM_BALANCE_PAYOUT_LOG TO STREAM ABMBalancePayoutLog;
PARTITION TABLE ABM_BALANCE_PAYOUT_LOG ON COLUMN subscriber_id;

DR TABLE ABM_ACCOUNT;
DR TABLE ABM_ACCOUNT_BALANCE;
DR TABLE ABM_BALANCE_SHARE_RULE;
