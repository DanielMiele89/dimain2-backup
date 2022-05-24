CREATE TABLE [Staging].[OPE_Validation_Input] (
    [PartnerName]       VARCHAR (50)   NULL,
    [AccountManager]    VARCHAR (50)   NULL,
    [ClientServicesRef] VARCHAR (8)    NULL,
    [IronOfferName]     VARCHAR (50)   NULL,
    [OfferSegment]      VARCHAR (50)   NULL,
    [IronOfferID]       INT            NULL,
    [CashbackRate]      DECIMAL (5, 2) NULL,
    [BaseOffer]         VARCHAR (50)   NULL,
    [CampaignEndDate]   DATE           NULL,
    [CampaignNotes]     VARCHAR (100)  NULL
);

