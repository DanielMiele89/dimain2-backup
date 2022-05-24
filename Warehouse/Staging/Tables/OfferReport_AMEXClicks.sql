CREATE TABLE [Staging].[OfferReport_AMEXClicks] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [IronOfferID] INT      NULL,
    [PartnerID]   SMALLINT NULL,
    [Cardholders] INT      NULL,
    [StartDate]   DATE     NULL,
    [EndDate]     DATE     NULL,
    [ClubID]      INT      NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

