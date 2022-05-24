CREATE TABLE [Staging].[OfferReport_AMEXExposedClickCounts] (
    [ID]            INT  NOT NULL,
    [IronOfferID]   INT  NULL,
    [ReceivedDate]  DATE NULL,
    [ExposedCounts] INT  NULL,
    [ClickCounts]   INT  NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

