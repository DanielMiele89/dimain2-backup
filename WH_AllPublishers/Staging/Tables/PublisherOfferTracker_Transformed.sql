CREATE TABLE [Staging].[PublisherOfferTracker_Transformed] (
    [PrimaryPartnerName] NVARCHAR (255) NOT NULL,
    [PrimaryPartnerID]   INT            NOT NULL,
    [PartnerID]          INT            NOT NULL,
    [OfferCode]          VARCHAR (10)   NOT NULL,
    [StartDate]          DATE           NOT NULL,
    [EndDate]            DATE           NOT NULL,
    [TargetAudience]     VARCHAR (50)   NOT NULL,
    [Definition]         VARCHAR (1000) NOT NULL,
    [CashbackOffer]      FLOAT (53)     NOT NULL,
    [SpendStretch]       MONEY          CONSTRAINT [default_SpendStretch] DEFAULT ((0)) NOT NULL,
    [SegmentID]          TINYINT        NOT NULL,
    [IsOnline]           BIT            NOT NULL
);

