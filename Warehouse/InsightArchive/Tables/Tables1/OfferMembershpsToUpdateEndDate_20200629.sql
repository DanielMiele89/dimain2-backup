CREATE TABLE [InsightArchive].[OfferMembershpsToUpdateEndDate_20200629] (
    [ClubName]       NVARCHAR (100) NOT NULL,
    [PartnerID]      INT            NOT NULL,
    [PartnerName]    NVARCHAR (100) NOT NULL,
    [IronOfferID]    INT            NOT NULL,
    [IronOfferName]  VARCHAR (100)  NULL,
    [OfferStartDate] DATETIME       NULL,
    [OfferEndDate]   DATETIME       NULL,
    [Memberships]    INT            NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [UCIX_IronOfferID]
    ON [InsightArchive].[OfferMembershpsToUpdateEndDate_20200629]([IronOfferID] ASC);

