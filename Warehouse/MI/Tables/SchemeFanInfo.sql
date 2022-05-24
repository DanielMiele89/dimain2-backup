CREATE TABLE [MI].[SchemeFanInfo] (
    [FanID]           INT          NOT NULL,
    [GenderID]        TINYINT      NOT NULL,
    [DOB]             DATE         NOT NULL,
    [ActivationDate]  DATE         NOT NULL,
    [CIN]             VARCHAR (50) NOT NULL,
    [CINID]           INT          NULL,
    [TmpBankID]       TINYINT      NULL,
    [BankID]          TINYINT      NULL,
    [RainbowID]       TINYINT      NULL,
    [ContactByEmail]  BIT          NOT NULL,
    [ContactByPhone]  BIT          NOT NULL,
    [ContactBySMS]    BIT          NOT NULL,
    [ContactByPost]   BIT          NOT NULL,
    [DeactivatedDate] DATE         NULL,
    CONSTRAINT [PK_MI_SchemeFanInfo] PRIMARY KEY CLUSTERED ([FanID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_MI_SchemeFanInfo_CINID]
    ON [MI].[SchemeFanInfo]([CINID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MI_SchemeFanInfo_CIN]
    ON [MI].[SchemeFanInfo]([CIN] ASC);

