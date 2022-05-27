CREATE TABLE [Report].[ControlSetup_Validation_Segments] (
    [PublisherType] VARCHAR (50)   NULL,
    [PublisherID]   INT            NULL,
    [RetailerID]    INT            NULL,
    [PartnerID]     INT            NULL,
    [RetailerName]  VARCHAR (200)  NULL,
    [OfferID]       INT            NOT NULL,
    [IronOfferID]   INT            NULL,
    [OfferName]     NVARCHAR (200) NULL,
    [StartDate]     DATETIME       NOT NULL,
    [EndDate]       DATETIME       NOT NULL,
    [SegmentID]     VARCHAR (10)   NULL,
    CONSTRAINT [PK_ControlSetup_Validation_Segments] PRIMARY KEY CLUSTERED ([OfferID] ASC, [StartDate] ASC, [EndDate] ASC)
);

