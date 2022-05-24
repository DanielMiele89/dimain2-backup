CREATE TABLE [Derived].[Customer_Archived] (
    [FanID]               INT           NOT NULL,
    [ClubID]              INT           NULL,
    [CompositeID]         BIGINT        NULL,
    [SourceUID]           VARCHAR (20)  NULL,
    [AccountType]         VARCHAR (20)  NULL,
    [EmailStructureValid] BIT           NULL,
    [Title]               VARCHAR (20)  NULL,
    [City]                VARCHAR (100) NULL,
    [County]              VARCHAR (100) NULL,
    [Region]              VARCHAR (30)  NULL,
    [PostalSector]        VARCHAR (6)   NULL,
    [PostCodeDistrict]    VARCHAR (4)   NULL,
    [PostArea]            VARCHAR (2)   NULL,
    [CAMEOCode]           VARCHAR (10)  NULL,
    [Gender]              CHAR (1)      NULL,
    [AgeCurrent]          TINYINT       NULL,
    [AgeCurrentBandText]  VARCHAR (10)  NULL,
    [CashbackPending]     MONEY         NOT NULL,
    [CashbackAvailable]   MONEY         NOT NULL,
    [CashbackLTV]         MONEY         NOT NULL,
    [Unsubscribed]        BIT           NULL,
    [Hardbounced]         BIT           NULL,
    [MarketableByEmail]   BIT           NULL,
    [CurrentlyActive]     BIT           NULL,
    [RegistrationDate]    DATE          NULL,
    [DeactivatedDate]     DATE          NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC) WITH (FILLFACTOR = 75)
);


GO
CREATE NONCLUSTERED INDEX [IX_CompFan]
    ON [Derived].[Customer_Archived]([CompositeID] ASC)
    INCLUDE([FanID]);

