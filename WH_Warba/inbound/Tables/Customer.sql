CREATE TABLE [inbound].[Customer] (
    [id]                    BIGINT           IDENTITY (1, 1) NOT NULL,
    [customerguid]          UNIQUEIDENTIFIER NOT NULL,
    [sourceid]              VARCHAR (255)    NOT NULL,
    [dob]                   DATE             NULL,
    [gender]                VARCHAR (1)      NOT NULL,
    [bankid]                INT              NOT NULL,
    [registrationtimestamp] DATETIME         NOT NULL,
    [deactivationtimestamp] DATETIME         NULL,
    [optouttimestamp]       DATETIME         NULL,
    [loaddate]              DATETIME         NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC) WITH (FILLFACTOR = 90)
);

