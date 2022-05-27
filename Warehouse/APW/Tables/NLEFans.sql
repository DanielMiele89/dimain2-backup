CREATE TABLE [APW].[NLEFans] (
    [FanID]        INT         NOT NULL,
    [CINID]        INT         NULL,
    [LastBPDTrans] DATE        NULL,
    [LastPTTrans]  DATE        NULL,
    [LastTrans]    DATE        NULL,
    [NLE]          VARCHAR (1) NULL,
    CONSTRAINT [PK_APW_NLEFans] PRIMARY KEY CLUSTERED ([FanID] ASC)
);

