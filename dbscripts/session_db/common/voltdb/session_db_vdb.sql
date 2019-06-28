create table SESSION_USAGE_COUNTER  (
   id                    BIGINT                      NOT NULL,
   subscriber_id         BIGINT                      NOT NULL,
   session_id            VARCHAR(40)                 NOT NULL,
   definition_Id         INTEGER                     NOT NULL,
   usage_type            BIGINT                      NOT NULL,
   total_usage           BIGINT                      DEFAULT 0 NOT NULL,
   exponent              BIGINT                      DEFAULT 0 NOT NULL,
   last_update_timestamp TIMESTAMP                   DEFAULT NOW NOT NULL,
   constraint PK_SESSION_USAGE_COUNTER PRIMARY KEY (subscriber_id, id)
);
create index IDX_SESSIONCOUNTER_OWNER on SESSION_USAGE_COUNTER(session_id);

PARTITION TABLE SESSION_USAGE_COUNTER ON COLUMN subscriber_id;

DR TABLE SESSION_USAGE_COUNTER;