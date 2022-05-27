CREATE TABLE [Inbound].[RBS_Customer] (
    [FanID]                  INT           NOT NULL,
    [ClubID]                 INT           NULL,
    [SourceUID]              VARCHAR (20)  NULL,
    [CompositeID]            BIGINT        NULL,
    [AccountType]            INT           NULL,
    [Title]                  VARCHAR (20)  NULL,
    [City]                   VARCHAR (100) NULL,
    [County]                 VARCHAR (100) NULL,
    [Region]                 VARCHAR (30)  NULL,
    [PostalSector]           VARCHAR (6)   NULL,
    [PostCodeDistrict]       VARCHAR (4)   NULL,
    [PostArea]               VARCHAR (2)   NULL,
    [Gender]                 CHAR (1)      NULL,
    [AgeCurrent]             TINYINT       NULL,
    [AgeCurrentBandText]     VARCHAR (10)  NULL,
    [MarketableByEmail]      BIT           NULL,
    [MarketableByDirectMail] BIT           NULL,
    [RegistrationDate]       DATE          NULL,
    [DeactivatedDate]        DATE          NULL,
    [CurrentlyActive]        BIT           NULL
);

