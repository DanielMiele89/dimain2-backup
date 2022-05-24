CREATE TABLE [InsightArchive].[Haven_CustomerMatches_20200122] (
    [FanID]     INT           NOT NULL,
    [MatchedOn] VARCHAR (100) NULL
);


GO
CREATE NONCLUSTERED INDEX [CIX_Fan]
    ON [InsightArchive].[Haven_CustomerMatches_20200122]([FanID] ASC);


GO
DENY SELECT
    ON OBJECT::[InsightArchive].[Haven_CustomerMatches_20200122] TO [New_PIIRemoved]
    AS [dbo];

