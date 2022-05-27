CREATE TABLE [InsightArchive].[OfferMembershipRemoval_Acquire] (
    [FanID]                INT           NOT NULL,
    [CompositeID]          BIGINT        NULL,
    [MarketablebyEmail]    BIT           NULL,
    [HTMID]                INT           NULL,
    [HTM_Description]      VARCHAR (50)  NULL,
    [ShopperSegmentTypeID] INT           NULL,
    [PartnerID]            INT           NOT NULL,
    [PartnerName]          VARCHAR (100) NOT NULL,
    [OfferID]              INT           NULL,
    [ClientServicesRef]    VARCHAR (10)  NOT NULL,
    [StartDate]            DATETIME      NULL,
    [EndDate]              DATETIME      NULL,
    [Comm Type]            VARCHAR (1)   NOT NULL,
    [TriggerBatch]         INT           NULL,
    [Grp]                  VARCHAR (7)   NOT NULL
);

