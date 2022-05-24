CREATE TABLE [Stratification].[Customers_Temp] (
    [ReportMonth] INT    NOT NULL,
    [CINID]       INT    NULL,
    [FanID]       INT    NULL,
    [CompositeID] BIGINT NULL,
    [Activated]   INT    NOT NULL,
    [IsRainbow]   INT    NOT NULL,
    CONSTRAINT [un_1] UNIQUE NONCLUSTERED ([FanID] ASC)
);


GO
CREATE CLUSTERED INDEX [CustomerIndex]
    ON [Stratification].[Customers_Temp]([CINID] ASC);

