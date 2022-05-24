CREATE TABLE [InsightArchive].[OfferMembershpsToRemove_20200629] (
    [ClubName]                 NVARCHAR (100) NOT NULL,
    [PartnerID]                INT            NOT NULL,
    [PartnerName]              NVARCHAR (100) NOT NULL,
    [IronOfferID]              INT            NOT NULL,
    [IronOfferName]            VARCHAR (100)  NULL,
    [OfferStartDate]           DATETIME       NULL,
    [OfferEndDate]             DATETIME       NULL,
    [OfferMembershipStartDate] DATETIME       NOT NULL,
    [OfferMembershipEndDate]   DATETIME       NULL,
    [Memberships]              INT            NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [UCIX_IronOfferIDOfferMembershipStartDate]
    ON [InsightArchive].[OfferMembershpsToRemove_20200629]([IronOfferID] ASC, [OfferMembershipStartDate] ASC);

