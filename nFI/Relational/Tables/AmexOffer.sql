CREATE TABLE [Relational].[AmexOffer] (
    [IronOfferID]     INT            NOT NULL,
    [AmexOfferID]     VARCHAR (10)   NOT NULL,
    [StartDate]       DATE           NOT NULL,
    [EndDate]         DATE           NOT NULL,
    [TargetAudience]  VARCHAR (50)   NOT NULL,
    [SegmentID]       TINYINT        NULL,
    [OfferDefinition] VARCHAR (1000) NOT NULL,
    [CashbackOffer]   FLOAT (53)     NOT NULL,
    [SpendStretch]    MONEY          NOT NULL,
    [RetailerID]      INT            NOT NULL,
    [IsOnline]        BIT            NOT NULL,
    [PublisherID]     INT            NOT NULL,
    CONSTRAINT [PK__AmexOffe__058BF9ABBD000F87] PRIMARY KEY CLUSTERED ([IronOfferID] ASC)
);

