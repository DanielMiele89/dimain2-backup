CREATE TABLE [Relational].[CustomerAttribute] (
    [CINID]                    INT     NOT NULL,
    [OutdoorHiking]            BIT     DEFAULT ((0)) NOT NULL,
    [Parent]                   BIT     DEFAULT ((0)) NOT NULL,
    [ParentOfYoung]            BIT     DEFAULT ((0)) NOT NULL,
    [Gambling]                 BIT     DEFAULT ((0)) NOT NULL,
    [Pets]                     BIT     DEFAULT ((0)) NOT NULL,
    [OnlineGroceriesRegular]   BIT     DEFAULT ((0)) NOT NULL,
    [OnlineGroceriesTentative] BIT     DEFAULT ((0)) NOT NULL,
    [OnlineOnly]               BIT     DEFAULT ((0)) NOT NULL,
    [OnlineAndOffline]         BIT     DEFAULT ((0)) NOT NULL,
    [OfflineOnly]              BIT     DEFAULT ((0)) NOT NULL,
    [NotShopped]               BIT     DEFAULT ((0)) NOT NULL,
    [VisitsOnline]             TINYINT DEFAULT ((0)) NOT NULL,
    [VisitsOffline]            TINYINT DEFAULT ((0)) NOT NULL,
    [VisitsCoalition]          TINYINT DEFAULT ((0)) NOT NULL,
    [VisitsNonCoalition]       TINYINT DEFAULT ((0)) NOT NULL,
    [RecencyOnline]            DATE    NULL,
    [RecencyOffline]           DATE    NULL,
    [RecencyCoalition]         DATE    NULL,
    [RecencyNonCoalition]      DATE    NULL,
    [CarOwner]                 BIT     DEFAULT ((0)) NOT NULL,
    [ValueMonthTotal]          MONEY   DEFAULT ((0)) NOT NULL,
    [ValueMonthOnline]         MONEY   DEFAULT ((0)) NOT NULL,
    [ValueMonthCoalition]      MONEY   DEFAULT ((0)) NOT NULL,
    [FrequencyMonthTotal]      INT     DEFAULT ((0)) NOT NULL,
    [FrequencyMonthOnline]     INT     DEFAULT ((0)) NOT NULL,
    [FrequencyMonthCoalition]  INT     DEFAULT ((0)) NOT NULL,
    [FrequencyYearRetail]      INT     NULL,
    [ValueYearRetail]          MONEY   NULL,
    [RecencyYearRetail]        DATE    NULL,
    [BankID]                   TINYINT CONSTRAINT [DF_CustomerAttribute_BankID] DEFAULT ((0)) NOT NULL,
    [FirstTranDate]            DATE    NULL,
    [RecencyYearRetailDays]    INT     NULL,
    PRIMARY KEY CLUSTERED ([CINID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_CustomerAttribute_BankIDFirstTranDate]
    ON [Relational].[CustomerAttribute]([BankID] ASC, [FirstTranDate] ASC)
    INCLUDE([CINID], [RecencyOnline], [RecencyOffline]);


GO
CREATE NONCLUSTERED INDEX [IX_CustomerAttribute_FirstTranDate]
    ON [Relational].[CustomerAttribute]([FirstTranDate] ASC)
    INCLUDE([CINID], [RecencyOnline], [RecencyOffline], [BankID]);


GO
CREATE NONCLUSTERED INDEX [IX_CustomerAttribute_RecencyYearRetail]
    ON [Relational].[CustomerAttribute]([RecencyYearRetail] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CustomerAttribute_ValueYearRetail]
    ON [Relational].[CustomerAttribute]([ValueYearRetail] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CustomerAttribute_FrequencyYearRetail]
    ON [Relational].[CustomerAttribute]([FrequencyYearRetail] ASC);

