CREATE TABLE [Email].[Newsletter_OfferPrioritisation_Import] (
    [ID]                INT            IDENTITY (1, 1) NOT NULL,
    [PartnerName]       NVARCHAR (255) NULL,
    [AccountManager]    NVARCHAR (255) NULL,
    [ClientServicesRef] NVARCHAR (255) NULL,
    [IronOfferName]     NVARCHAR (255) NULL,
    [OfferSegment]      NVARCHAR (255) NULL,
    [IronOfferID]       NVARCHAR (255) NULL,
    [CashbackRate]      NVARCHAR (255) NULL,
    [BaseOffer]         NVARCHAR (255) NULL,
    [CampaignEndDate]   NVARCHAR (255) NULL,
    [CampaignNotes]     NVARCHAR (255) NULL
);

