CREATE TABLE [Staging].[AcquireAnalysis_NonSpenders] (
    [FanID] INT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_Fan]
    ON [Staging].[AcquireAnalysis_NonSpenders]([FanID] ASC);

