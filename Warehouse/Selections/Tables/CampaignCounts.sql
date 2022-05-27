CREATE TABLE [Selections].[CampaignCounts] (
    [ID]                           INT           IDENTITY (1, 1) NOT NULL,
    [EmailDate]                    DATE          NULL,
    [Cycle]                        VARCHAR (15)  NULL,
    [PartnerID]                    INT           NULL,
    [PartnerName]                  VARCHAR (50)  NULL,
    [ClientServicesRef]            VARCHAR (10)  NULL,
    [OutputTableName]              VARCHAR (250) NULL,
    [IronOfferID]                  INT           NULL,
    [IronOfferName]                VARCHAR (250) NULL,
    [Throttling]                   INT           NULL,
    [PredictedCardholderVolumes]   INT           NULL,
    [NewCampaign]                  BIT           NULL,
    [SelectionRan]                 BIT           NULL,
    [CountFromIOMCurrent]          INT           NULL,
    [CountFromSelections]          INT           NULL,
    [CountFromOfferMemberAddition] INT           NULL,
    [CountFromIOMUpcoming]         INT           NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_EmailDate]
    ON [Selections].[CampaignCounts]([EmailDate] ASC);

