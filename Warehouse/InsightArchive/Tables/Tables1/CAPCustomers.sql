CREATE TABLE [InsightArchive].[CAPCustomers] (
    [FanID]     INT  NOT NULL,
    [StartDate] DATE NOT NULL,
    [EndDate]   DATE NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_InsightArchive_CAPCustomers_Cover]
    ON [InsightArchive].[CAPCustomers]([StartDate] ASC, [EndDate] ASC);

