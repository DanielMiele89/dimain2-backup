CREATE TABLE [InsightArchive].[OfferMembershpsToDelete_20200528] (
    [IronOfferID]         INT            NOT NULL,
    [Name]                NVARCHAR (200) NOT NULL,
    [MembershipStartDate] DATETIME       NOT NULL,
    [MembershipEndDate]   DATETIME       NULL,
    [OfferStartDate]      DATETIME       NULL,
    [OfferEndDate]        DATETIME       NULL,
    [Memberships]         INT            NULL
);

