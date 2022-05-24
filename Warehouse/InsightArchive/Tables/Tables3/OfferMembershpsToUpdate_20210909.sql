CREATE TABLE [InsightArchive].[OfferMembershpsToUpdate_20210909] (
    [CompositeID]        BIGINT       NOT NULL,
    [IronOfferID]        INT          NOT NULL,
    [EndDate]            DATETIME     NULL,
    [IncorrectStartDate] DATETIME     NOT NULL,
    [DesiredStartDate]   VARCHAR (23) NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_OfferCompStart]
    ON [InsightArchive].[OfferMembershpsToUpdate_20210909]([IronOfferID] ASC, [CompositeID] ASC, [IncorrectStartDate] ASC);

