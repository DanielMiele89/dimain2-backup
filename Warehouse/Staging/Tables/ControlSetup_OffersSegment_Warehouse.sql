CREATE TABLE [Staging].[ControlSetup_OffersSegment_Warehouse] (
    [IronOfferID]   INT            NOT NULL,
    [IronOfferName] NVARCHAR (200) NULL,
    [StartDate]     DATETIME       NOT NULL,
    [EndDate]       DATETIME       NOT NULL,
    [PartnerID]     INT            NULL,
    [PartnerName]   VARCHAR (100)  NULL,
    [Segment]       VARCHAR (50)   NULL,
    CONSTRAINT [PK_ControlSetup_OffersSegment_Warehouse] PRIMARY KEY CLUSTERED ([IronOfferID] ASC, [StartDate] ASC, [EndDate] ASC)
);

