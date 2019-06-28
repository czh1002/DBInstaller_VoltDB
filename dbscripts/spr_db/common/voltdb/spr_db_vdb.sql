create table SUBSCRIBER (
   id                       BIGINT                    NOT NULL,
   name                     VARCHAR(120),
   state                    TINYINT                   DEFAULT 2 NOT NULL,
   default_account_id       VARCHAR(20),
   default_payment          TINYINT                   DEFAULT 0 NOT NULL,
   profile_id               VARCHAR(20),
   product_family_id        VARCHAR(40),
   extended_attributes      VARCHAR(10240),
   last_update_timestamp    TIMESTAMP                 DEFAULT NOW NOT NULL,
   last_sync_timestamp      TIMESTAMP                 DEFAULT 0 NOT NULL,
   last_effective_timestamp TIMESTAMP                 DEFAULT NOW NOT NULL,
   state_recycle            VARCHAR(1)                DEFAULT 'A' NOT NULL,
   cycle_begin_timestamp      TIMESTAMP                  DEFAULT 0 NOT NULL,
   cycle_end_timestamp        TIMESTAMP                  DEFAULT 0 NOT NULL,
   time_zone_id             VARCHAR(60),
   country_id               VARCHAR(2),
   operator_code            VARCHAR(9),
   level1_zone_id           BIGINT                    DEFAULT 0 NOT NULL,
   level2_zone_id           BIGINT                    DEFAULT 0 NOT NULL,
   home_site_id             VARCHAR(20),
   external_id              VARCHAR(20),
   timer_id                 BIGINT                    DEFAULT 0 NOT NULL,
   timer_partition          INTEGER                   DEFAULT 0 NOT NULL,
   last_usage_timestamp     TIMESTAMP                 DEFAULT 0 NOT NULL,
   current_cycle_id         BIGINT                    DEFAULT 0 NOT NULL,
   next_cycle_id         BIGINT                       DEFAULT 0 NOT NULL,
   constraint PK_SUBSCRIBER PRIMARY KEY (id)
);
create index IDX_SUBSCRIBER_RECYCLE on SUBSCRIBER(id, state_recycle, last_update_timestamp);
create index IDX_SUBSCRIBER_LAST_USAGE on SUBSCRIBER(last_usage_timestamp, state_recycle);

create table SESSION_DATA (
   subscriber_id                BIGINT                         NOT NULL,
   session_id                   VARCHAR(100)                    NOT NULL,
   last_quota_gsus              VARCHAR(10240),
   confirmed_quota_reservations VARCHAR(10240),
   confirmed_counter_usages     VARCHAR(10240),
   last_update_timestamp        TIMESTAMP                      DEFAULT NOW NOT NULL,
   retransmit_id                VARCHAR(100),
   constraint PK_SESSION_DATA PRIMARY KEY (subscriber_id, session_id)
);

create table SUBSCRIBER_HIERARCHY_NODE (
   id                    BIGINT                         NOT NULL,
   hierarchy_id          BIGINT                         NOT NULL,
   name       			 VARCHAR(40),
   parent_id             BIGINT                         NOT NULL,
   subscriber_id         BIGINT                         NOT NULL,
   state                 TINYINT                    	DEFAULT 0 NOT NULL,
   extended_attributes   VARCHAR(10240),
   last_update_timestamp TIMESTAMP                      DEFAULT NOW NOT NULL,
   constraint PK_SUBSCRIBER_HIERARCHY_NODE PRIMARY KEY (id)
);
create unique index IDX_SUB_TREE_NAME_PARENTID on SUBSCRIBER_HIERARCHY_NODE(name, parent_id);
create index IDX_SUB_TREE_SUBSCRIBER on SUBSCRIBER_HIERARCHY_NODE(subscriber_id);
create index IDX_SUB_TREE_TREEID on SUBSCRIBER_HIERARCHY_NODE(hierarchy_id);

create table SUBSCRIBER_LOCK (
   subscriber_id               BIGINT                         NOT NULL,
   state_lock                  TINYINT                        DEFAULT 0 NOT NULL,
   state_last_change_timestamp TIMESTAMP                      DEFAULT 0 NOT NULL,
   should_lock_flag            TINYINT                        NOT NULL,
   should_lock_site_id         VARCHAR(20),
   state_recycle               VARCHAR(1)                     DEFAULT 'A' NOT NULL,
   last_update_timestamp       TIMESTAMP                      DEFAULT NOW NOT NULL,
   token_id                    VARCHAR(128),
   constraint PK_SUBSCRIBER_LOCK PRIMARY KEY (subscriber_id)
);
create index IDX_SUBSCRIBER_LOCK_RECYCLE on SUBSCRIBER_LOCK(subscriber_id, state_recycle, last_update_timestamp);

create table ACCOUNT_RELATIONSHIP (
   subscriber_id              BIGINT                      NOT NULL,
   device_id                  BIGINT                      NOT NULL,
   account_id                 VARCHAR(20)                 NOT NULL,
   account_item_type_group_id INTEGER                     DEFAULT 0 NOT NULL,
   priority                   TINYINT                     DEFAULT -1 NOT NULL,
   last_update_timestamp      TIMESTAMP                   DEFAULT NOW NOT NULL,
   state_recycle              VARCHAR(1)                  DEFAULT 'A' NOT NULL,
   payment                    TINYINT                     DEFAULT 0 NOT NULL,
   extended_attributes        VARCHAR(10240),
   constraint PK_ACCOUNT_RELATIONSHIP PRIMARY KEY (subscriber_id, device_id, account_item_type_group_id)
);
create index IDX_ACCT_REL_ACCT on ACCOUNT_RELATIONSHIP(account_id);
create index IDX_ACCT_REL_RECYCLE on ACCOUNT_RELATIONSHIP(subscriber_id, state_recycle, last_update_timestamp);

create table USAGE_COUNTER  (
   id                    BIGINT                  NOT NULL,
   subscriber_id         BIGINT                  NOT NULL,
   counter_level         TINYINT                 NOT NULL,
   device_id             BIGINT                  NOT NULL,
   subscription_id       BIGINT                  NOT NULL,
   definition_Id         INTEGER                 NOT NULL,
   usage_type            TINYINT                 NOT NULL,
   total_usage           BIGINT                  DEFAULT 0 NOT NULL,
   confirmed_value       BIGINT                  DEFAULT 0 NOT NULL,
   exponent              TINYINT                 DEFAULT 0 NOT NULL,
   cycle_begin_timestamp TIMESTAMP               NOT NULL,
   cycle_end_timestamp   TIMESTAMP               NOT NULL,
   last_update_timestamp TIMESTAMP               DEFAULT NOW NOT NULL,
   time_zone_id          VARCHAR(60),
   state_recycle         VARCHAR(1)              DEFAULT 'A' NOT NULL,
   extended_attributes   VARCHAR(10240),
   timer_id                 BIGINT                    DEFAULT 0 NOT NULL,
   timer_partition          INTEGER                   DEFAULT 0 NOT NULL,
   state                    TINYINT                   DEFAULT 2 NOT NULL,
   epc_counter_def_id           VARCHAR(40),
   constraint PK_USAGE_COUNTER PRIMARY KEY (subscriber_id, id)
);
create index IDX_C0UNTER_RECYCLE on USAGE_COUNTER(subscriber_id, state_recycle, last_update_timestamp);

create table DEVICE (
   id                       BIGINT                      NOT NULL,
   state                    TINYINT                     DEFAULT 2 NOT NULL,
   subscriber_id            BIGINT                      NOT NULL,
   profile_id               VARCHAR(20),
   product_family_id        VARCHAR(40),
   extended_attributes      VARCHAR(10240),
   last_update_timestamp    TIMESTAMP                   DEFAULT NOW NOT NULL,
   last_sync_timestamp      TIMESTAMP                   DEFAULT 0 NOT NULL,
   last_effective_timestamp TIMESTAMP                   DEFAULT NOW NOT NULL,
   state_recycle            VARCHAR(1)                  DEFAULT 'A' NOT NULL,
   external_id              VARCHAR(20),
   timer_id                 BIGINT                    DEFAULT 0 NOT NULL,
   timer_partition          INTEGER                   DEFAULT 0 NOT NULL,
   cycle_begin_timestamp      TIMESTAMP                  DEFAULT 0 NOT NULL,
   cycle_end_timestamp        TIMESTAMP                  DEFAULT 0 NOT NULL,
   time_zone_id             VARCHAR(60),
   constraint PK_DEVICE PRIMARY KEY (subscriber_id, id)
);
create index IDX_HASH_DEVICE_ID on DEVICE(id);
create index IDX_DEVICE_RECYCLE on DEVICE(subscriber_id, state_recycle, last_update_timestamp);

create table DEVICE_IDENTIFIER (
   identifier_value      VARCHAR(60)                   NOT NULL,
   identifier_type       TINYINT                       NOT NULL,
   subscriber_id         BIGINT                        NOT NULL,
   device_id             BIGINT                        NOT NULL,
   effective_timestamp   TIMESTAMP                     DEFAULT NOW NOT NULL,
   state_recycle         VARCHAR(1)                    DEFAULT 'A',
   last_update_timestamp TIMESTAMP                     DEFAULT NOW NOT NULL,
   constraint PK_DEV_IDENTIFIER PRIMARY KEY (subscriber_id, identifier_value, identifier_type)
);
create index IDX_DEV_IDENTIFIER_RECYCLE on DEVICE_IDENTIFIER(subscriber_id, state_recycle, last_update_timestamp);

create table DEVICE_IDENTIFIER_INDEX (
   identifier_value      VARCHAR(60)                   NOT NULL,
   identifier_type       TINYINT                       NOT NULL,
   subscriber_id         BIGINT                        NOT NULL,
   device_id             BIGINT                        NOT NULL,
   effective_timestamp   TIMESTAMP                     DEFAULT NOW NOT NULL,
   state_recycle         VARCHAR(1)                    DEFAULT 'A',
   last_update_timestamp TIMESTAMP                     DEFAULT NOW NOT NULL,
   constraint PK_DEV_IDENTIFIER_IDX PRIMARY KEY (identifier_value, identifier_type)
);
create index IDX_DEV_IDENTIFIER_IDX_RECYCLE on DEVICE_IDENTIFIER_INDEX(subscriber_id, state_recycle, last_update_timestamp);

create table SUBSCRIPTION (
   id                         BIGINT                      NOT NULL,
   subscriber_id              BIGINT                      NOT NULL,
   device_id                  BIGINT                      NOT NULL,
   state                      TINYINT                     DEFAULT 2 NOT NULL,
   product_id                 INTEGER                     NOT NULL,
   activation_timestamp       TIMESTAMP                   NOT NULL,
   cycle_begin_timestamp      TIMESTAMP                   NOT NULL,
   cycle_end_timestamp        TIMESTAMP                   NOT NULL,
   renewed_count              BIGINT                      DEFAULT 0 NOT NULL,
   last_update_timestamp      TIMESTAMP                   DEFAULT NOW NOT NULL,
   last_effective_timestamp   TIMESTAMP                   DEFAULT NOW NOT NULL,
   last_sync_timestamp        TIMESTAMP                   DEFAULT 0 NOT NULL,
   sharing_subscription_id    BIGINT                      DEFAULT 0 NOT NULL,
   sharing_subscriber_id      BIGINT                      DEFAULT 0 NOT NULL,
   scheduled_cancel_timestamp TIMESTAMP                   DEFAULT 0 NOT NULL,
   time_zone_id               VARCHAR(60),
   extended_attributes        VARCHAR(10240),
   subscription_parameters    VARCHAR(10240),
   state_recycle              VARCHAR(1)                  DEFAULT 'A' NOT NULL,
   external_id                VARCHAR(20),
   timer_id                 BIGINT                    DEFAULT 0 NOT NULL,
   timer_partition          INTEGER                   DEFAULT 0 NOT NULL,
   epc_product_id           VARCHAR(40),
   activation_by_usage_infos  VARCHAR(10240),
   sharing_device_id          BIGINT               DEFAULT 0 NOT NULL,
   constraint PK_SUBSCRIPTION PRIMARY KEY (subscriber_id, id)
);
create index IDX_HASH_SUBSCRIPTION_ID on SUBSCRIPTION(id);
create index IDX_SUBSCRIPTION_RECYCLE on SUBSCRIPTION(subscriber_id, state_recycle, last_update_timestamp);

create table SUBSCRIPTION_QUOTA  (
   id                    BIGINT                    NOT NULL,
   subscriber_id         BIGINT                    NOT NULL,
   device_id             BIGINT                    NOT NULL,
   subscription_id       BIGINT                    NOT NULL,
   definition_Id         INTEGER                   NOT NULL,
   usage_type            TINYINT                   NOT NULL,
   exponent              TINYINT                   DEFAULT 0 NOT NULL,
   max_quota             BIGINT                    DEFAULT 0 NOT NULL,
   max_quota_real        BIGINT                    DEFAULT 0 NOT NULL,
   recharged_quota       BIGINT                    DEFAULT 0 NOT NULL,
   used_value            BIGINT                    DEFAULT 0 NOT NULL,
   reservation           BIGINT                    DEFAULT 0 NOT NULL,
   confirmed_reservation BIGINT                    DEFAULT 0 NOT NULL,
   cycle_begin_timestamp TIMESTAMP                 NOT NULL,
   cycle_end_timestamp   TIMESTAMP                 NOT NULL,
   last_update_timestamp TIMESTAMP                 DEFAULT NOW NOT NULL,
   time_zone_id          VARCHAR(60),
   state_recycle         VARCHAR(1)                DEFAULT 'A' NOT NULL,
   extended_attributes   VARCHAR(10240),
   timer_id                 BIGINT                    DEFAULT 0 NOT NULL,
   timer_partition          INTEGER                   DEFAULT 0 NOT NULL,
   state                    TINYINT                   DEFAULT 2 NOT NULL,
   epc_quota_def_id     VARCHAR(40),
   constraint PK_SUBSCRIPTION_QUOTA PRIMARY KEY (subscriber_id, id)
);
create index IDX_HASH_QUOTA_SUBSCRIPTION on SUBSCRIPTION_QUOTA(subscription_id);
create index IDX_QUOTA_RECYCLE on SUBSCRIPTION_QUOTA(subscriber_id, state_recycle, last_update_timestamp);

create table SUBSCRIBER_CONTACT (
   subscriber_id         BIGINT                    NOT NULL,
   channel       	     VARCHAR(10)               DEFAULT 'SMS' NOT NULL,
   target                VARCHAR(60)               NOT NULL,
   state_recycle         VARCHAR(1)                DEFAULT 'A' NOT NULL,
   extended_attributes   VARCHAR(10240),
   last_update_timestamp TIMESTAMP                 DEFAULT NOW NOT NULL,
   constraint PK_SUBSCRIBER_CONTACT PRIMARY KEY (subscriber_id, channel)
);
create index IDX_CONTACT_RECYCLE on SUBSCRIBER_CONTACT(subscriber_id, state_recycle, last_update_timestamp);

create table HIS_SUBSCRIBER (
   id                       BIGINT                    NOT NULL,
   name                     VARCHAR(120),
   state                    TINYINT                   DEFAULT 2 NOT NULL,
   default_account_id       VARCHAR(20),
   default_payment          TINYINT                   DEFAULT 0 NOT NULL,
   profile_id               VARCHAR(20),
   product_family_id        VARCHAR(40),
   extended_attributes      VARCHAR(10240),
   last_update_timestamp    TIMESTAMP                 DEFAULT NOW NOT NULL,
   last_sync_timestamp      TIMESTAMP                 DEFAULT 0 NOT NULL,
   last_effective_timestamp TIMESTAMP                 DEFAULT NOW NOT NULL,
   state_recycle            VARCHAR(1)                DEFAULT 'A' NOT NULL,
   cycle_begin_timestamp      TIMESTAMP                  DEFAULT 0 NOT NULL,
   cycle_end_timestamp        TIMESTAMP                  DEFAULT 0 NOT NULL,
   time_zone_id             VARCHAR(60),
   country_id               VARCHAR(2),
   operator_code            VARCHAR(9),
   level1_zone_id           BIGINT                    DEFAULT 0 NOT NULL,
   level2_zone_id           BIGINT                    DEFAULT 0 NOT NULL,
   home_site_id             VARCHAR(20),
   external_id              VARCHAR(20),
   timer_id                 BIGINT                    DEFAULT 0 NOT NULL,
   timer_partition          INTEGER                   DEFAULT 0 NOT NULL,
   last_usage_timestamp     TIMESTAMP                 DEFAULT 0 NOT NULL,
   current_cycle_id         BIGINT                    DEFAULT 0 NOT NULL,
   next_cycle_id         BIGINT                       DEFAULT 0 NOT NULL,
   history_id                BIGINT                    NOT NULL,
   history_expired_timestamp TIMESTAMP                 DEFAULT NOW NOT NULL,
   archive_timestamp         TIMESTAMP                 DEFAULT NOW NOT NULL,
   constraint PK_HIS_SUBSCRIBER PRIMARY KEY (id, history_id)
);
create index IDX_HASH_HIS_SUB_ID on HIS_SUBSCRIBER(id);
create index IDX_HIS_SUB_RECYCLE on HIS_SUBSCRIBER(id, state_recycle, last_update_timestamp);

create table HIS_USAGE_COUNTER (
   id                    BIGINT                  NOT NULL,
   subscriber_id         BIGINT                  NOT NULL,
   counter_level         TINYINT                 NOT NULL,
   device_id             BIGINT                  NOT NULL,
   subscription_id       BIGINT                  NOT NULL,
   definition_Id         INTEGER                 NOT NULL,
   usage_type            TINYINT                 NOT NULL,
   total_usage           BIGINT                  DEFAULT 0 NOT NULL,
   confirmed_value       BIGINT                  DEFAULT 0 NOT NULL,
   exponent              TINYINT                 DEFAULT 0 NOT NULL,
   cycle_begin_timestamp TIMESTAMP               NOT NULL,
   cycle_end_timestamp   TIMESTAMP               NOT NULL,
   last_update_timestamp TIMESTAMP               DEFAULT NOW NOT NULL,
   time_zone_id          VARCHAR(60),
   state_recycle         VARCHAR(1)              DEFAULT 'A' NOT NULL,
   extended_attributes   VARCHAR(10240),
   timer_id                 BIGINT                    DEFAULT 0 NOT NULL,
   timer_partition          INTEGER                   DEFAULT 0 NOT NULL,
   state                    TINYINT                   DEFAULT 2 NOT NULL,
   epc_counter_def_id           VARCHAR(40),
   history_id            BIGINT                  NOT NULL,
   Archive_timestamp     TIMESTAMP               DEFAULT NOW NOT NULL,
   constraint PK_USAGE_COUNTER_HIS PRIMARY KEY (subscriber_id, history_id)
);
create index IDX_HASH_HIS_COUNTER_ID on HIS_USAGE_COUNTER(id);
create index IDX_HIS_COUNTER_RECYCLE on HIS_USAGE_COUNTER(subscriber_id, state_recycle, last_update_timestamp);

create table HIS_DEVICE (
   id                       BIGINT                      NOT NULL,
   state                    TINYINT                     DEFAULT 2 NOT NULL,
   subscriber_id            BIGINT                      NOT NULL,
   profile_id               VARCHAR(20),
   product_family_id        VARCHAR(40),
   extended_attributes      VARCHAR(10240),
   last_update_timestamp    TIMESTAMP                   DEFAULT NOW NOT NULL,
   last_sync_timestamp      TIMESTAMP                   DEFAULT 0 NOT NULL,
   last_effective_timestamp TIMESTAMP                   DEFAULT NOW NOT NULL,
   state_recycle            VARCHAR(1)                  DEFAULT 'A' NOT NULL,
   external_id              VARCHAR(20),
   timer_id                 BIGINT                    DEFAULT 0 NOT NULL,
   timer_partition          INTEGER                   DEFAULT 0 NOT NULL,
   cycle_begin_timestamp      TIMESTAMP                  DEFAULT 0 NOT NULL,
   cycle_end_timestamp        TIMESTAMP                  DEFAULT 0 NOT NULL,
   time_zone_id             VARCHAR(60),
   history_id                BIGINT                      NOT NULL,
   history_expired_timestamp TIMESTAMP                   DEFAULT NOW NOT NULL,
   archive_timestamp         TIMESTAMP                   DEFAULT NOW NOT NULL,
   constraint PK_HIS_DEVICE  PRIMARY KEY (subscriber_id, history_id)
);
create index IDX_HASH_HIS_DEVICE_ID on HIS_DEVICE(id);
create index IDX_HIS_DEVICE_RECYCLE on HIS_DEVICE(subscriber_id, state_recycle, last_update_timestamp);

create table HIS_DEVICE_IDENTIFIER (
   identifier_value          VARCHAR(60)                   NOT NULL,
   identifier_type           TINYINT                       NOT NULL,
   subscriber_id             BIGINT                        NOT NULL,
   device_id                 BIGINT                        NOT NULL,
   effective_timestamp       TIMESTAMP                     DEFAULT NOW NOT NULL,
   state_recycle             VARCHAR(1)                    DEFAULT 'A',
   last_update_timestamp     TIMESTAMP                     DEFAULT NOW NOT NULL,
   history_id                BIGINT                        NOT NULL,
   history_expired_timestamp TIMESTAMP                     DEFAULT NOW NOT NULL,
   archive_timestamp         TIMESTAMP                     DEFAULT NOW NOT NULL,
   constraint PK_DEV_IDENTIFIER_HIS PRIMARY KEY (subscriber_id, history_id)
);
create index IDX_HIS_DEVID_KEY on HIS_DEVICE_IDENTIFIER(identifier_value, identifier_type);
create index IDX_HIS_DEVID_RECYCLE on HIS_DEVICE_IDENTIFIER(subscriber_id, state_recycle, last_update_timestamp);

create table HIS_DEVICE_IDENTIFIER_INDEX (
   identifier_value          VARCHAR(60)                   NOT NULL,
   identifier_type           TINYINT                       NOT NULL,
   subscriber_id             BIGINT                        NOT NULL,
   device_id                 BIGINT                        NOT NULL,
   effective_timestamp       TIMESTAMP                     DEFAULT NOW NOT NULL,
   state_recycle             VARCHAR(1)                    DEFAULT 'A',
   last_update_timestamp     TIMESTAMP                     DEFAULT NOW NOT NULL,
   history_id                BIGINT                        NOT NULL,
   history_expired_timestamp TIMESTAMP                     DEFAULT NOW NOT NULL,
   archive_timestamp         TIMESTAMP                     DEFAULT NOW NOT NULL,
   constraint PK_DEV_IDENTIFIER_HIS_IDX PRIMARY KEY (identifier_value, history_id)
);
create index IDX_HIS_DEVID_IDX_RECYCLE on HIS_DEVICE_IDENTIFIER_INDEX(subscriber_id, state_recycle, last_update_timestamp);

create table HIS_SUBSCRIPTION (
   
   id                         BIGINT                      NOT NULL,
   subscriber_id              BIGINT                      NOT NULL,
   device_id                  BIGINT                      NOT NULL,
   state                      TINYINT                     DEFAULT 2 NOT NULL,
   product_id                 INTEGER                     NOT NULL,
   activation_timestamp       TIMESTAMP                   NOT NULL,
   cycle_begin_timestamp      TIMESTAMP                   NOT NULL,
   cycle_end_timestamp        TIMESTAMP                   NOT NULL,
   renewed_count              BIGINT                      DEFAULT 0 NOT NULL,
   last_update_timestamp      TIMESTAMP                   DEFAULT NOW NOT NULL,
   last_effective_timestamp   TIMESTAMP                   DEFAULT NOW NOT NULL,
   last_sync_timestamp        TIMESTAMP                   DEFAULT 0 NOT NULL,
   sharing_subscription_id    BIGINT                      DEFAULT 0 NOT NULL,
   sharing_subscriber_id      BIGINT                      DEFAULT 0 NOT NULL,
   scheduled_cancel_timestamp TIMESTAMP                   DEFAULT 0 NOT NULL,
   time_zone_id               VARCHAR(60),
   extended_attributes        VARCHAR(10240),
   subscription_parameters    VARCHAR(10240),
   state_recycle              VARCHAR(1)                  DEFAULT 'A' NOT NULL,
   external_id                VARCHAR(20),
   timer_id                 BIGINT                    DEFAULT 0 NOT NULL,
   timer_partition          INTEGER                   DEFAULT 0 NOT NULL,
   epc_product_id           VARCHAR(40),
   activation_by_usage_infos  VARCHAR(10240),
   sharing_device_id          BIGINT               DEFAULT 0 NOT NULL,
   history_id                 BIGINT                      NOT NULL,
   history_expired_timestamp TIMESTAMP                    DEFAULT NOW NOT NULL,
   Archive_timestamp         TIMESTAMP                    DEFAULT NOW NOT NULL,
   constraint PK_SUBSCRIPTION_HIS PRIMARY KEY (subscriber_id, history_id)
);
create index IDX_HASH_HIS_SPT_ID on HIS_SUBSCRIPTION(id);
create index IDX_HIS_SPT_RECYCLE on HIS_SUBSCRIPTION(subscriber_id, state_recycle, last_update_timestamp);

create table HIS_SUBSCRIPTION_QUOTA (
   id                    BIGINT                    NOT NULL,
   subscriber_id         BIGINT                    NOT NULL,
   device_id             BIGINT                    NOT NULL,
   subscription_id       BIGINT                    NOT NULL,
   definition_Id         INTEGER                   NOT NULL,
   usage_type            TINYINT                   NOT NULL,
   exponent              TINYINT                   DEFAULT 0 NOT NULL,
   max_quota             BIGINT                    DEFAULT 0 NOT NULL,
   max_quota_real        BIGINT                    DEFAULT 0 NOT NULL,
   recharged_quota       BIGINT                    DEFAULT 0 NOT NULL,
   used_value            BIGINT                    DEFAULT 0 NOT NULL,
   reservation           BIGINT                    DEFAULT 0 NOT NULL,
   confirmed_reservation BIGINT                    DEFAULT 0 NOT NULL,
   cycle_begin_timestamp TIMESTAMP                 NOT NULL,
   cycle_end_timestamp   TIMESTAMP                 NOT NULL,
   last_update_timestamp TIMESTAMP                 DEFAULT NOW NOT NULL,
   time_zone_id          VARCHAR(60),
   state_recycle         VARCHAR(1)                DEFAULT 'A' NOT NULL,
   extended_attributes   VARCHAR(10240),
   timer_id                 BIGINT                    DEFAULT 0 NOT NULL,
   timer_partition          INTEGER                   DEFAULT 0 NOT NULL,
   state                    TINYINT                   DEFAULT 2 NOT NULL,
   epc_quota_def_id     VARCHAR(40),
   history_id            BIGINT                    NOT NULL,
   archive_timestamp     TIMESTAMP                 DEFAULT NOW NOT NULL,
   constraint PK_HIS_SUBSCRIPTION_QUOTA PRIMARY KEY (subscriber_id, history_id)
);
create index IDX_HASH_HIS_QUOTA_ID on HIS_SUBSCRIPTION_QUOTA(id);
create index IDX_HIS_QUOTA_RECYCLE on HIS_SUBSCRIPTION_QUOTA(subscriber_id, state_recycle, last_update_timestamp);
create table COUNTER_UPDATE_LOG  (
   counter_id             			BIGINT          NOT NULL,
   subscriber_id          			BIGINT          NOT NULL,
   counter_level          			TINYINT         NOT NULL,
   counter_owner_id       			BIGINT          NOT NULL,
   counter_definition_Id  			INTEGER         NOT NULL,
   usage_type             			TINYINT         NOT NULL,
   total_usage            			BIGINT          DEFAULT 0 NOT NULL,
   old_total_usage        			BIGINT          DEFAULT 0 NOT NULL,
   total_usage_delta      			BIGINT          DEFAULT 0 NOT NULL,
   monetory_exponent      			TINYINT         DEFAULT 0 NOT NULL,
   cycle_begin_timestamp  			TIMESTAMP       DEFAULT 0 NOT NULL,
   cycle_end_timestamp    			TIMESTAMP       DEFAULT 0 NOT NULL,
   counter_extended_attributes    	VARCHAR(10240),
   old_counter_extended_attributes  VARCHAR(10240),
   rt_session_id          			VARCHAR(256),
   event_type             			TINYINT          DEFAULT 0 NOT NULL,
   event_timestamp        			TIMESTAMP        DEFAULT NOW NOT NULL,
   log_extended_attributes      	VARCHAR(1000000 BYTES),
   own_subscriber_id_in_sharing  	BIGINT           DEFAULT 0 NOT NULL,
   confirmed_value            		BIGINT          DEFAULT 0 NOT NULL,
   old_confirmed_value        		BIGINT          DEFAULT 0 NOT NULL,
);

create table QUOTA_UPDATE_LOG  (
   quota_id             			BIGINT          NOT NULL,
   subscriber_id          			BIGINT          NOT NULL,
   subscription_id       			BIGINT          NOT NULL,
   quota_definition_Id  			INTEGER         NOT NULL,
   usage_type             			TINYINT         NOT NULL,
   used_value            			BIGINT          DEFAULT 0 NOT NULL,
   old_used_value        			BIGINT          DEFAULT 0 NOT NULL,
   used_value_delta      			BIGINT          DEFAULT 0 NOT NULL,
   balance	            			BIGINT          DEFAULT 0 NOT NULL,
   old_balance	        			BIGINT          DEFAULT 0 NOT NULL,
   balance_delta      				BIGINT          DEFAULT 0 NOT NULL,
   monetory_exponent      			TINYINT         DEFAULT 0 NOT NULL,
   cycle_begin_timestamp  			TIMESTAMP       DEFAULT 0 NOT NULL,
   cycle_end_timestamp    			TIMESTAMP       DEFAULT 0 NOT NULL,
   quota_extended_attributes    	VARCHAR(10240),
   old_quota_extended_attributes  	VARCHAR(10240),
   rt_session_id          			VARCHAR(256),
   event_type             			TINYINT          DEFAULT 0 NOT NULL,
   event_timestamp        			TIMESTAMP        DEFAULT NOW NOT NULL,
   log_extended_attributes      	VARCHAR(1000000 BYTES),
   own_subscriber_id_in_sharing  	BIGINT           DEFAULT 0 NOT NULL,
   reservation            		    BIGINT          DEFAULT 0 NOT NULL,
   old_reservation        		    BIGINT          DEFAULT 0 NOT NULL,
   confirmed_reservation            BIGINT          DEFAULT 0 NOT NULL,
   old_confirmed_reservation        BIGINT          DEFAULT 0 NOT NULL,
);


create table SPR_ENTITY_ID_MAPPING  (
   external_Id             			VARCHAR(256)    NOT NULL,
   entity_Type_Id          			TINYINT         NOT NULL,
   internal_Id            			BIGINT          NOT NULL,
   subscriber_Id        			BIGINT          NOT NULL,
   constraint PK_SPR_ENTITY_ID_MAPPING PRIMARY KEY (external_Id, entity_Type_Id)
);


PARTITION TABLE SUBSCRIBER ON COLUMN id;
PARTITION TABLE SESSION_DATA ON COLUMN subscriber_id;
PARTITION TABLE SUBSCRIBER_LOCK ON COLUMN subscriber_id;
PARTITION TABLE ACCOUNT_RELATIONSHIP ON COLUMN subscriber_id;
PARTITION TABLE USAGE_COUNTER ON COLUMN subscriber_id;
PARTITION TABLE DEVICE ON COLUMN subscriber_id;
PARTITION TABLE DEVICE_IDENTIFIER ON COLUMN subscriber_id;
PARTITION TABLE DEVICE_IDENTIFIER_INDEX ON COLUMN identifier_value;
PARTITION TABLE SUBSCRIPTION ON COLUMN subscriber_id;
PARTITION TABLE SUBSCRIPTION_QUOTA ON COLUMN subscriber_id;
PARTITION TABLE SPR_ENTITY_ID_MAPPING ON COLUMN external_id;
PARTITION TABLE SUBSCRIBER_CONTACT ON COLUMN subscriber_id;
PARTITION TABLE HIS_SUBSCRIBER ON COLUMN id;
PARTITION TABLE HIS_USAGE_COUNTER ON COLUMN subscriber_id;
PARTITION TABLE HIS_DEVICE ON COLUMN subscriber_id;
PARTITION TABLE HIS_DEVICE_IDENTIFIER ON COLUMN subscriber_id;
PARTITION TABLE HIS_DEVICE_IDENTIFIER_INDEX ON COLUMN identifier_value;
PARTITION TABLE HIS_SUBSCRIPTION ON COLUMN subscriber_id;
PARTITION TABLE HIS_SUBSCRIPTION_QUOTA ON COLUMN subscriber_id;
PARTITION TABLE COUNTER_UPDATE_LOG ON COLUMN subscriber_id;
PARTITION TABLE QUOTA_UPDATE_LOG ON COLUMN subscriber_id;

DR TABLE SUBSCRIBER;
DR TABLE SESSION_DATA;
DR TABLE SUBSCRIBER_LOCK;
DR TABLE ACCOUNT_RELATIONSHIP;
DR TABLE USAGE_COUNTER;
DR TABLE DEVICE;
DR TABLE DEVICE_IDENTIFIER;
DR TABLE DEVICE_IDENTIFIER_INDEX;
DR TABLE SUBSCRIPTION;
DR TABLE SUBSCRIPTION_QUOTA;
DR TABLE SPR_ENTITY_ID_MAPPING;
DR TABLE SUBSCRIBER_CONTACT;
DR TABLE HIS_SUBSCRIBER;
DR TABLE HIS_USAGE_COUNTER;
DR TABLE HIS_DEVICE;
DR TABLE HIS_DEVICE_IDENTIFIER;
DR TABLE HIS_DEVICE_IDENTIFIER_INDEX;
DR TABLE HIS_SUBSCRIPTION;
DR TABLE HIS_SUBSCRIPTION_QUOTA;
DR TABLE SUBSCRIBER_HIERARCHY_NODE;

EXPORT TABLE COUNTER_UPDATE_LOG TO STREAM CounterUpdateLog;
EXPORT TABLE QUOTA_UPDATE_LOG TO STREAM QuotaUpdateLog;
