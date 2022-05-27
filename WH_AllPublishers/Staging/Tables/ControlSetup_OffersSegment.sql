CREATE TABLE [Staging].[ControlSetup_OffersSegment] (
    [IronOfferID]   INT            NOT NULL,
    [IronOfferName] NVARCHAR (200) NULL,
    [StartDate]     DATE           NOT NULL,
    [EndDate]       DATE           NOT NULL,
    [PartnerID]     INT            NULL,
    [ClubID]        INT            NULL,
    [PartnerName]   VARCHAR (100)  NULL,
    [Segment]       VARCHAR (50)   NULL,
    CONSTRAINT [PK_ControlSetup_OffersSegment] PRIMARY KEY CLUSTERED ([IronOfferID] ASC, [StartDate] ASC, [EndDate] ASC) WITH (FILLFACTOR = 90)
);

