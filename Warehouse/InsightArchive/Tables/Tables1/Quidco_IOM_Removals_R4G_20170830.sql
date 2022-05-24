CREATE TABLE [InsightArchive].[Quidco_IOM_Removals_R4G_20170830] (
    [CompositeID] BIGINT   NOT NULL,
    [IronOfferID] INT      NOT NULL,
    [StartDate]   DATETIME NOT NULL
);


GO
CREATE CLUSTERED INDEX [cix_Quidco_IOM_Removals_R4G_20170830_AllFields]
    ON [InsightArchive].[Quidco_IOM_Removals_R4G_20170830]([CompositeID] ASC, [IronOfferID] ASC, [StartDate] ASC);

