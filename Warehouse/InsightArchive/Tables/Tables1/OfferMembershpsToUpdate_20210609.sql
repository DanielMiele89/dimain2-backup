CREATE TABLE [InsightArchive].[OfferMembershpsToUpdate_20210609] (
    [IronOfferID]          INT          NOT NULL,
    [CompositeID]          BIGINT       NOT NULL,
    [StartDate_Current]    VARCHAR (10) NOT NULL,
    [EndDate]              DATETIME     NULL,
    [StartDate_ToUpdateTo] DATETIME     NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_CompOfferStart]
    ON [InsightArchive].[OfferMembershpsToUpdate_20210609]([CompositeID] ASC, [IronOfferID] ASC, [StartDate_Current] ASC);

