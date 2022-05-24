CREATE TABLE [Derived].[Customer] (
    [FanID]               INT              NOT NULL,
    [CustomerGUID]        UNIQUEIDENTIFIER NOT NULL,
    [ClubID]              INT              NULL,
    [CompositeID]         BIGINT           NULL,
    [SourceUID]           VARCHAR (64)     NULL,
    [AccountType]         VARCHAR (50)     NULL,
    [EmailStructureValid] BIT              NULL,
    [Title]               VARCHAR (20)     NULL,
    [City]                VARCHAR (100)    NULL,
    [County]              VARCHAR (100)    NULL,
    [Region]              VARCHAR (30)     NULL,
    [PostalSector]        VARCHAR (6)      NULL,
    [PostCodeDistrict]    VARCHAR (4)      NULL,
    [PostArea]            VARCHAR (2)      NULL,
    [CAMEOCode]           VARCHAR (10)     NULL,
    [Gender]              CHAR (1)         NULL,
    [AgeCurrent]          TINYINT          NULL,
    [AgeCurrentBandText]  VARCHAR (10)     NULL,
    [CashbackPending]     MONEY            NOT NULL,
    [CashbackAvailable]   MONEY            NOT NULL,
    [CashbackLTV]         MONEY            NOT NULL,
    [Unsubscribed]        BIT              NULL,
    [Hardbounced]         BIT              NULL,
    [MarketableByEmail]   BIT              NULL,
    [EmailTracking]       BIT              NULL,
    [MarketableByPush]    BIT              NULL,
    [CurrentlyActive]     BIT              NULL,
    [RegistrationDate]    DATE             NULL,
    [DeactivatedDate]     DATE             NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC) WITH (FILLFACTOR = 75)
);




GO
CREATE NONCLUSTERED INDEX [IX_CompositeCurrentlyActive]
    ON [Derived].[Customer]([CompositeID] ASC, [CurrentlyActive] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_CurrentlyActive_IncComposite]
    ON [Derived].[Customer]([CurrentlyActive] ASC)
    INCLUDE([CompositeID]);


GO
CREATE NONCLUSTERED INDEX [IX_MarketableActive_IncFanComp]
    ON [Derived].[Customer]([MarketableByEmail] ASC, [CurrentlyActive] ASC)
    INCLUDE([FanID], [CompositeID]);


GO
GRANT SELECT
    ON OBJECT::[Derived].[Customer] TO [visa_etl_user]
    AS [New_DataOps];

