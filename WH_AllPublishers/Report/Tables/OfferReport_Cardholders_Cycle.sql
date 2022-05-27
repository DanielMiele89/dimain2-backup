CREATE TABLE [Report].[OfferReport_Cardholders_Cycle] (
    [ID]            INT          IDENTITY (1, 1) NOT NULL,
    [PublisherType] VARCHAR (25) NULL,
    [PublisherID]   INT          NULL,
    [RetailerID]    INT          NULL,
    [PartnerID]     INT          NULL,
    [IronOfferID]   INT          NULL,
    [OfferID]       INT          NOT NULL,
    [StartDate]     DATETIME     NULL,
    [EndDate]       DATETIME     NULL,
    [Cardholders]   INT          NULL
);


GO
CREATE CLUSTERED INDEX [CIX_IronOfferDates]
    ON [Report].[OfferReport_Cardholders_Cycle]([IronOfferID] ASC, [StartDate] ASC, [EndDate] ASC);

