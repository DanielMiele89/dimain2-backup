CREATE TABLE [Staging].[OPE_Offer_Membership_Removals] (
    [FanID]             INT           NOT NULL,
    [CompositeID]       BIGINT        NULL,
    [MarketablebyEmail] BIT           NULL,
    [HTMID]             INT           NULL,
    [HTM_Description]   VARCHAR (50)  NULL,
    [PartnerID]         INT           NOT NULL,
    [PartnerName]       VARCHAR (100) NOT NULL,
    [OfferID]           INT           NULL,
    [ClientServicesRef] VARCHAR (10)  NOT NULL,
    [StartDate]         DATETIME      NULL,
    [EndDate]           DATETIME      NULL,
    [Comm Type]         VARCHAR (1)   NOT NULL,
    [TriggerBatch]      INT           NULL,
    [Grp]               VARCHAR (7)   NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [i_OPE_Offer_Membership_Removals_FanID]
    ON [Staging].[OPE_Offer_Membership_Removals]([FanID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [i_OPE_Offer_Membership_Removals_ClientServicesRef]
    ON [Staging].[OPE_Offer_Membership_Removals]([ClientServicesRef] ASC) WITH (FILLFACTOR = 80);

