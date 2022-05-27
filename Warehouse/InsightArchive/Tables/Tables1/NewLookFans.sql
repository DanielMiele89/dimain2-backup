CREATE TABLE [InsightArchive].[NewLookFans] (
    [FanID]        INT         NOT NULL,
    [CINID]        INT         NULL,
    [LastBPDTrans] DATE        NULL,
    [LastPTTrans]  DATE        NULL,
    [LastTrans]    DATE        NULL,
    [NLE]          VARCHAR (1) NULL,
    [LastSUTrans]  DATE        NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

