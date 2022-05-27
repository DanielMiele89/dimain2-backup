CREATE TABLE [InsightArchive].[warnerleisure_CustomerMatches_20200218] (
    [FanID]     INT           NOT NULL,
    [MatchedOn] VARCHAR (100) NULL
);




GO
CREATE NONCLUSTERED INDEX [CIX_Fan]
    ON [InsightArchive].[warnerleisure_CustomerMatches_20200218]([FanID] ASC);


GO
DENY SELECT
    ON OBJECT::[InsightArchive].[warnerleisure_CustomerMatches_20200218] TO [New_PIIRemoved]
    AS [dbo];

