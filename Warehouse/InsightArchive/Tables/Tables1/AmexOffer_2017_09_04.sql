CREATE TABLE [InsightArchive].[AmexOffer_2017_09_04] (
    [IronOfferID]     INT            NOT NULL,
    [AmexOfferID]     VARCHAR (10)   NOT NULL,
    [StartDate]       DATE           NOT NULL,
    [EndDate]         DATE           NOT NULL,
    [TargetAudience]  VARCHAR (50)   NOT NULL,
    [SegmentID]       TINYINT        NOT NULL,
    [OfferDefinition] VARCHAR (1000) NOT NULL,
    [CashbackOffer]   FLOAT (53)     NOT NULL,
    [SpendStretch]    MONEY          NOT NULL,
    [RetailerID]      INT            NOT NULL,
    [IsOnline]        BIT            NOT NULL,
    PRIMARY KEY CLUSTERED ([IronOfferID] ASC)
);

