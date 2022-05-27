CREATE TABLE [Staging].[ControlSetup_OffersSegment_VirginPCA] (
    [IronOfferID]   INT            NOT NULL,
    [IronOfferName] NVARCHAR (200) NULL,
    [StartDate]     DATETIME       NOT NULL,
    [EndDate]       DATETIME       NOT NULL,
    [PartnerID]     INT            NULL,
    [ClubID]        INT            NULL,
    [PartnerName]   VARCHAR (100)  NULL,
    [Segment]       VARCHAR (50)   NULL,
    CONSTRAINT [PK_ControlSetup_OffersSegment_VirginPCA] PRIMARY KEY CLUSTERED ([IronOfferID] ASC, [StartDate] ASC, [EndDate] ASC) WITH (FILLFACTOR = 90)
);

