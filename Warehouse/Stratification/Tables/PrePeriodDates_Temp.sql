CREATE TABLE [Stratification].[PrePeriodDates_Temp] (
    [StartDate]         SMALLDATETIME NOT NULL,
    [EndDate]           SMALLDATETIME NOT NULL,
    [RainbowAdjustment] FLOAT (53)    NULL,
    PRIMARY KEY CLUSTERED ([StartDate] ASC, [EndDate] ASC)
);

