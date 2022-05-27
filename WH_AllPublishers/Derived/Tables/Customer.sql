CREATE TABLE [Derived].[Customer] (
    [CustomerID]         INT              IDENTITY (1, 1) NOT NULL,
    [SourceSystemID]     INT              NOT NULL,
    [PublisherType]      VARCHAR (25)     NULL,
    [PublisherID]        INT              NULL,
    [FanID]              INT              NOT NULL,
    [CustomerGUID]       UNIQUEIDENTIFIER NULL,
    [CompositeID]        BIGINT           NULL,
    [SourceUID]          VARCHAR (64)     NULL,
    [CINID]              INT              NULL,
    [SourceCustomerID]   VARCHAR (20)     NULL,
    [AccountType]        VARCHAR (20)     NULL,
    [Title]              VARCHAR (20)     NULL,
    [City]               VARCHAR (100)    NULL,
    [County]             VARCHAR (100)    NULL,
    [Region]             VARCHAR (30)     NULL,
    [PostalSector]       VARCHAR (6)      NULL,
    [PostCodeDistrict]   VARCHAR (4)      NULL,
    [PostArea]           VARCHAR (2)      NULL,
    [CAMEOCode]          VARCHAR (10)     NULL,
    [Gender]             VARCHAR (1)      NULL,
    [AgeCurrent]         TINYINT          NULL,
    [AgeCurrentBandText] VARCHAR (10)     NULL,
    [CashbackPending]    DECIMAL (32, 2)  NULL,
    [CashbackAvailable]  DECIMAL (32, 2)  NULL,
    [CashbackLTV]        DECIMAL (32, 2)  NULL,
    [Unsubscribed]       BIT              NULL,
    [Hardbounced]        BIT              NULL,
    [EmailTracking]      BIT              NULL,
    [MarketableByEmail]  BIT              NULL,
    [MarketableByPush]   BIT              NULL,
    [CurrentlyActive]    BIT              NULL,
    [RegistrationDate]   DATE             NULL,
    [DeactivatedDate]    DATE             NULL,
    [AddedDate]          DATETIME2 (7)    NOT NULL,
    [ModifiedDate]       DATETIME2 (7)    NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_FanID_IncCINID]
    ON [Derived].[Customer]([FanID] ASC)
    INCLUDE([CINID]);

