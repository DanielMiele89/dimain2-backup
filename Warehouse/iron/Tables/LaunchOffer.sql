CREATE TABLE [iron].[LaunchOffer] (
    [ID]            INT      IDENTITY (1, 1) NOT NULL,
    [PartnerID]     INT      NOT NULL,
    [OfferID]       INT      NOT NULL,
    [ClubID]        INT      NOT NULL,
    [StartDate]     DATETIME NOT NULL,
    [ProcessedFlag] BIT      DEFAULT ((0)) NOT NULL,
    [ProcessedDate] DATETIME NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

