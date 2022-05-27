CREATE TABLE [InsightArchive].[OfferMembershpsToRemove_20210511] (
    [IronOfferID]    INT            NULL,
    [StartDate]      DATETIME       NULL,
    [EndDate]        DATETIME       NULL,
    [CompositeID]    BIGINT         NULL,
    [IronOfferName]  NVARCHAR (200) NULL,
    [IsIncentivised] INT            NOT NULL,
    [OfferChoice]    BIGINT         NULL
);

