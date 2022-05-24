CREATE TABLE [Staging].[AcquireAnalysis_Customers] (
    [FanID] INT NOT NULL,
    [CINID] INT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_Fan]
    ON [Staging].[AcquireAnalysis_Customers]([FanID] ASC);


GO
CREATE CLUSTERED INDEX [CIX_CIN]
    ON [Staging].[AcquireAnalysis_Customers]([CINID] ASC);

