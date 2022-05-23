CREATE TABLE [COD].[Offer] (
    [ID]           INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [BriefID]      INT            NOT NULL,
    [OfferName]    NVARCHAR (256) NOT NULL,
    [OfferStatus]  INT            NOT NULL,
    [StartDate]    DATETIME       NOT NULL,
    [RetailerID]   INT            NOT NULL,
    [CampaignID]   INT            NOT NULL,
    [CampaignCode] NVARCHAR (50)  NOT NULL,
    [EndDate]      DATETIME       NOT NULL,
    CONSTRAINT [PK__Offer__3214EC27E00BA636] PRIMARY KEY CLUSTERED ([ID] ASC)
);

