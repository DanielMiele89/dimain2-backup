CREATE TABLE [Staging].[ControlSetup_Validation_Secondary_Segments] (
    [PublisherType] VARCHAR (50)   NULL,
    [PartnerID]     INT            NULL,
    [IronOfferID]   INT            NOT NULL,
    [IronOfferName] NVARCHAR (200) NULL,
    [StartDate]     DATE           NOT NULL,
    [EndDate]       DATE           NOT NULL,
    [Segment]       VARCHAR (10)   NULL,
    CONSTRAINT [PK_ControlSetup_Validation_Secondary_Segments] PRIMARY KEY CLUSTERED ([IronOfferID] ASC, [StartDate] ASC, [EndDate] ASC)
);

