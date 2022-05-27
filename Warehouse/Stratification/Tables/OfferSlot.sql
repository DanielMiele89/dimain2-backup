CREATE TABLE [Stratification].[OfferSlot] (
    [FanID]          INT            NULL,
    [IronOfferID]    INT            NULL,
    [EmailType]      VARCHAR (1)    NULL,
    [ID]             INT            NOT NULL,
    [CampaignName]   NVARCHAR (255) NOT NULL,
    [SendDate]       DATE           NULL,
    [SendDateAsDate] DATE           NULL,
    [OfferSlot]      INT            NULL
);

