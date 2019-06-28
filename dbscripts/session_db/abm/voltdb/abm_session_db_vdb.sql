CREATE TABLE ABM_SESSION (
    partition                    INTEGER      NOT NULL,
    id                           VARCHAR(255) NOT NULL,
    subscriber_id                BIGINT       NOT NULL,
    last_update_time             TIMESTAMP,
    created_time                 TIMESTAMP,
    state                        INTEGER DEFAULT 0,
    abm_host                     VARCHAR(40),
    abm_realm                    VARCHAR(40),
    ne_host                      VARCHAR(40),
    ne_realm                     VARCHAR(40),
    device_identifier_type       INTEGER,
    device_identifier            VARCHAR(64),
    device_id                    BIGINT,
    last_cc_request_number      BIGINT,
    last_result_code             BIGINT,
    extended_attributes          VARCHAR(10240),
    CONSTRAINT PK_ABM_SESSION PRIMARY KEY (partition, id)
);

CREATE INDEX IDX_ABMSES_UPDATETIME ON ABM_SESSION (last_update_time ASC);
CREATE INDEX IDX_ABMSES_CREATETIME ON ABM_SESSION (created_time ASC);
CREATE INDEX IDX_ABMSES_DID ON ABM_SESSION (device_identifier,device_identifier_type);

CREATE TABLE ABM_SESSION_RESERVATION (
    partition                    INTEGER             NOT NULL,
    id                           BIGINT              NOT NULL,
    subscriber_id                BIGINT              NOT NULL,
    abm_session_id               VARCHAR(255)        NOT NULL,
    sub_session_id               VARCHAR(255),
    account_balance_id           BIGINT              NOT NULL,
    account_item_type_id         BIGINT              NOT NULL,
    balance_reserved             BIGINT              NOT NULL,
    balance_confirmed            BIGINT  DEFAULT 0   NOT NULL,
    balance_type_id              INTEGER DEFAULT 0   NOT NULL,
    balance_measurement          INTEGER DEFAULT 2   NOT NULL,
    created_time                 TIMESTAMP,
    last_update_time             TIMESTAMP,
    balance_before               BIGINT              NOT NULL,
    account_id                   BIGINT,
    device_id                    BIGINT,
    balance_owned_subscriber_id  BIGINT,
    share_rule_id                BIGINT DEFAULT 0   NOT NULL,
    account_owned_subscriber_id  BIGINT,
    account_item_group_id        INTEGER,
    last_cc_request_number       BIGINT,
    last_result_code             BIGINT,
    extended_attributes          VARCHAR(10240),
    CONSTRAINT PK_ABM_SESSION_RESERVATION PRIMARY KEY (partition, id)
);
CREATE INDEX IDX_ABM_SES_RES_FK ON ABM_SESSION_RESERVATION (abm_session_id);

CREATE TABLE ABM_RETRANSMIT_RECORD  (
   partition                     INTEGER        NOT NULL,
   id                            BIGINT         NOT NULL,
   origin_host                   VARCHAR(40)    NOT NULL,
   subscriber_id                 BIGINT         NOT NULL,
   abm_session_id                VARCHAR(255)   NOT NULL,
   last_cc_request_number        BIGINT         NOT NULL,
   create_time                   TIMESTAMP      NOT NULL,
   expired_time                  TIMESTAMP,
   response_message_row_data     VARBINARY(524288),   
   CONSTRAINT PK_ABM_RETRANSMIT_RECORD primary key (partition, id, origin_host)
);
CREATE INDEX IDX_ABM_RETRANSMIT_EXPIRED ON ABM_RETRANSMIT_RECORD (expired_time ASC);
CREATE INDEX IDX_ABM_RETRANSMIT_PARTITION_EXPIRED ON ABM_RETRANSMIT_RECORD (partition, expired_time);


PARTITION TABLE ABM_SESSION ON COLUMN partition;
PARTITION TABLE ABM_SESSION_RESERVATION ON COLUMN partition;
PARTITION TABLE ABM_RETRANSMIT_RECORD ON COLUMN partition;


CREATE PROCEDURE FROM CLASS com.hpe.snap.rtc.vdb.procedures.abm.session.RcRetransmitRecordDeleteByPKProcedure;
PARTITION PROCEDURE RcRetransmitRecordDeleteByPKProcedure ON TABLE ABM_RETRANSMIT_RECORD COLUMN partition;

CREATE PROCEDURE FROM CLASS com.hpe.snap.rtc.vdb.procedures.abm.session.RcRetransmitRecordDeleteExpiredProcedure;
PARTITION PROCEDURE RcRetransmitRecordDeleteExpiredProcedure ON TABLE ABM_RETRANSMIT_RECORD COLUMN partition;

CREATE PROCEDURE FROM CLASS com.hpe.snap.rtc.vdb.procedures.abm.session.RcRetransmitRecordGetByPKProcedure;
PARTITION PROCEDURE RcRetransmitRecordGetByPKProcedure ON TABLE ABM_RETRANSMIT_RECORD COLUMN partition;

CREATE PROCEDURE FROM CLASS com.hpe.snap.rtc.vdb.procedures.abm.session.RcRetransmitRecordGetExpiredProcedure;
PARTITION PROCEDURE RcRetransmitRecordGetExpiredProcedure ON TABLE ABM_RETRANSMIT_RECORD COLUMN partition;

CREATE PROCEDURE FROM CLASS com.hpe.snap.rtc.vdb.procedures.abm.session.RcRetransmitRecordInsertProcedure;
PARTITION PROCEDURE RcRetransmitRecordInsertProcedure ON TABLE ABM_RETRANSMIT_RECORD COLUMN partition;


CREATE PROCEDURE FROM CLASS com.hpe.snap.rtc.vdb.procedures.abm.session.RcSessionDeleteByPKProcedure;
PARTITION PROCEDURE RcSessionDeleteByPKProcedure ON TABLE ABM_SESSION COLUMN partition;
PARTITION PROCEDURE RcSessionDeleteByPKProcedure ON TABLE ABM_SESSION_RESERVATION COLUMN partition;

CREATE PROCEDURE FROM CLASS com.hpe.snap.rtc.vdb.procedures.abm.session.RcSessionGetByPKProcedure;
PARTITION PROCEDURE RcSessionGetByPKProcedure ON TABLE ABM_SESSION COLUMN partition;
PARTITION PROCEDURE RcSessionGetByPKProcedure ON TABLE ABM_SESSION_RESERVATION COLUMN partition;

CREATE PROCEDURE FROM CLASS com.hpe.snap.rtc.vdb.procedures.abm.session.RcSessionGetExpiredProcedure;
PARTITION PROCEDURE RcSessionGetExpiredProcedure ON TABLE ABM_SESSION COLUMN partition;

CREATE PROCEDURE FROM CLASS com.hpe.snap.rtc.vdb.procedures.abm.session.RcSessionInsertProcedure;
PARTITION PROCEDURE RcSessionInsertProcedure ON TABLE ABM_SESSION COLUMN partition;
PARTITION PROCEDURE RcSessionInsertProcedure ON TABLE ABM_SESSION_RESERVATION COLUMN partition;

CREATE PROCEDURE FROM CLASS com.hpe.snap.rtc.vdb.procedures.abm.session.RcSessionUpdateProcedure;
PARTITION PROCEDURE RcSessionUpdateProcedure ON TABLE ABM_SESSION COLUMN partition;
PARTITION PROCEDURE RcSessionUpdateProcedure ON TABLE ABM_SESSION_RESERVATION COLUMN partition;


CREATE PROCEDURE FROM CLASS com.hpe.snap.rtc.vdb.procedures.abm.session.RcQuerySessionByDeviceIdentifierProc;
PARTITION PROCEDURE RcQuerySessionByDeviceIdentifierProc ON TABLE ABM_SESSION COLUMN partition;
PARTITION PROCEDURE RcQuerySessionByDeviceIdentifierProc ON TABLE ABM_SESSION_RESERVATION COLUMN partition;

CREATE PROCEDURE FROM CLASS com.hpe.snap.rtc.vdb.procedures.abm.session.RcQuerySessionBySessionIdProc;
PARTITION PROCEDURE RcQuerySessionBySessionIdProc ON TABLE ABM_SESSION COLUMN partition;
PARTITION PROCEDURE RcQuerySessionBySessionIdProc ON TABLE ABM_SESSION_RESERVATION COLUMN partition;

CREATE PROCEDURE FROM CLASS com.hpe.snap.rtc.vdb.procedures.abm.session.RcQuerySessionBySubscriberIdProc;
PARTITION PROCEDURE RcQuerySessionBySubscriberIdProc ON TABLE ABM_SESSION COLUMN partition;
PARTITION PROCEDURE RcQuerySessionBySubscriberIdProc ON TABLE ABM_SESSION_RESERVATION COLUMN partition;
