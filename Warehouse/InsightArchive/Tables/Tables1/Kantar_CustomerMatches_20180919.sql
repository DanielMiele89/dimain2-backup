CREATE TABLE [InsightArchive].[Kantar_CustomerMatches_20180919] (
    [FanID]     INT          NOT NULL,
    [MatchedOn] VARCHAR (26) NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_KantarCustomerMatches_FanID]
    ON [InsightArchive].[Kantar_CustomerMatches_20180919]([FanID] ASC);

