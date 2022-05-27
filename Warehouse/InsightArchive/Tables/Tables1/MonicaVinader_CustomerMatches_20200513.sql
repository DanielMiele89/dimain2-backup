CREATE TABLE [InsightArchive].[MonicaVinader_CustomerMatches_20200513] (
    [FanID]     INT           NOT NULL,
    [MatchedOn] VARCHAR (100) NULL
);




GO
CREATE NONCLUSTERED INDEX [CIX_Fan]
    ON [InsightArchive].[MonicaVinader_CustomerMatches_20200513]([FanID] ASC);


GO
DENY SELECT
    ON OBJECT::[InsightArchive].[MonicaVinader_CustomerMatches_20200513] TO [New_PIIRemoved]
    AS [dbo];

