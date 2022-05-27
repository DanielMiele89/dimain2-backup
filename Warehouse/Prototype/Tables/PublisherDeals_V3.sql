CREATE TABLE [Prototype].[PublisherDeals_V3] (
    [ID]              INT            NOT NULL,
    [ClubID]          INT            NULL,
    [PlatformFee]     DECIMAL (5, 2) NULL,
    [AccMgmtFee]      DECIMAL (5, 2) NULL,
    [OfferSourceFee]  DECIMAL (5, 2) NULL,
    [DistributionFee] DECIMAL (5, 2) NULL,
    [StartDate]       DATE           NULL,
    [EndDate]         DATE           NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

