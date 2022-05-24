CREATE TABLE [InsightArchive].[MonicaVinader_CustomerMatches_20210806] (
    [FanID]     INT           NOT NULL,
    [MatchedOn] VARCHAR (100) NULL
);


GO
CREATE NONCLUSTERED INDEX [CIX_Fan]
    ON [InsightArchive].[MonicaVinader_CustomerMatches_20210806]([FanID] ASC);

