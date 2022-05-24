CREATE TABLE [InsightArchive].[Proba_Oct_Spender] (
    [FanID]           INT  NOT NULL,
    [MonthDate]       DATE NOT NULL,
    [IsTargetSpender] BIT  NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

