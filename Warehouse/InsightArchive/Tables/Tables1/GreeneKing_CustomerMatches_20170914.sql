CREATE TABLE [InsightArchive].[GreeneKing_CustomerMatches_20170914] (
    [HashedEmail] VARCHAR (250) NULL,
    [FanID]       INT           NOT NULL,
    [Email]       VARCHAR (30)  NULL
);


GO
CREATE CLUSTERED INDEX [cix_FanID]
    ON [InsightArchive].[GreeneKing_CustomerMatches_20170914]([FanID] ASC);

