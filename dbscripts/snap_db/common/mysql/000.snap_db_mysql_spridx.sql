create table DEVICE_IDENTIFIER_INDEX (
   identifier_value      VARCHAR(60)                   NOT NULL,
   identifier_type       TINYINT                       NOT NULL,
   subscriber_id         BIGINT                        NOT NULL,
   device_id             BIGINT                        NOT NULL,
   effective_timestamp   BIGINT                        DEFAULT 0 NOT NULL,
   state_recycle         VARCHAR(1)                    DEFAULT 'A',
   last_update_timestamp BIGINT                        DEFAULT 0 NOT NULL,
   partition_id          INTEGER,
   constraint PK_DEV_IDENTIFIER_IDX PRIMARY KEY (identifier_value, identifier_type)
);
create index IDX_ROOT_DEV_IDENTIFIER on DEVICE_IDENTIFIER_INDEX(subscriber_id);