CREATE TABLE [InsightArchive].[OfferMembershpsToUpdate_20210901] (
    [CompositeID]        BIGINT   NOT NULL,
    [IronOfferID]        INT      NOT NULL,
    [DesiredStartDate]   DATETIME NULL,
    [DesiredEndDate]     DATETIME NULL,
    [IncorrectStartDate] DATETIME NOT NULL,
    [IncorrectEndDate]   DATETIME NULL
);


GO
CREATE CLUSTERED INDEX [CIX_OfferCompStart]
    ON [InsightArchive].[OfferMembershpsToUpdate_20210901]([IronOfferID] ASC, [CompositeID] ASC, [IncorrectStartDate] ASC);

