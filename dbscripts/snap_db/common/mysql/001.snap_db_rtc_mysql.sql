CREATE TABLE IF NOT EXISTS CURRENCY_CODES
(
    ID                CHAR(3)     NOT NULL,
    NUM_CODE          SMALLINT    NOT NULL,
    FRACTIONAL_DIGITS TINYINT     NOT NULL,
    FULL_NAME         VARCHAR(128) NULL,
    LOCATIONS         VARCHAR(256) NULL,
    CREATE_TIME       BIGINT      NOT NULL,
    LAST_UPDATE_TIME  BIGINT      NOT NULL,
    STATE_LIFECYCLE   CHAR(1)     NOT NULL,
    CONSTRAINT PK_CURRENCY PRIMARY KEY (ID),
    CONSTRAINT UNIQUE_CURRENCY_CODE UNIQUE(NUM_CODE)
);

insert into ATOM_SEQUENCE (SEQUENCE, VALUE) VALUES('SEQ_CAC',1000000);