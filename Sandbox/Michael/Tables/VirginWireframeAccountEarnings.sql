CREATE TABLE [Michael].[VirginWireframeAccountEarnings] (
    [ID]               INT           IDENTITY (1, 1) NOT NULL,
    [CalculationDate]  DATE          NULL,
    [PeriodType]       VARCHAR (50)  NOT NULL,
    [StartDate]        DATE          NOT NULL,
    [EndDate]          DATE          NOT NULL,
    [PublisherID]      INT           NULL,
    [PublisherName]    VARCHAR (50)  NULL,
    [FanID]            INT           NULL,
    [Gender]           VARCHAR (1)   NULL,
    [AgeBucketName]    VARCHAR (6)   NULL,
    [AgeBucketStart]   INT           NULL,
    [AgeBucketEnd]     INT           NULL,
    [Postcode]         VARCHAR (10)  NULL,
    [PostcodeDistrict] VARCHAR (10)  NULL,
    [Region]           VARCHAR (30)  NULL,
    [Retailer]         VARCHAR (100) NULL,
    [Sector]           VARCHAR (100) NULL,
    [SubSector]        VARCHAR (100) NULL,
    [OfferType]        VARCHAR (50)  NULL,
    [Spend]            MONEY         NULL,
    [Earnings]         MONEY         NULL,
    [Transactions]     INT           NULL,
    CONSTRAINT [PK_AccountEarnings] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [UC_AccountEarnings] UNIQUE NONCLUSTERED ([StartDate] ASC, [EndDate] ASC, [FanID] ASC, [Retailer] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NCIX_AccountEarnings]
    ON [Michael].[VirginWireframeAccountEarnings]([StartDate] ASC, [EndDate] ASC)
    INCLUDE([Retailer]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [NCIX2_AccountEarnings]
    ON [Michael].[VirginWireframeAccountEarnings]([Retailer] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [NCIX3_AccountEarnings]
    ON [Michael].[VirginWireframeAccountEarnings]([FanID] ASC);

