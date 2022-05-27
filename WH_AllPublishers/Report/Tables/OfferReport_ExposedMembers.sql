CREATE TABLE [Report].[OfferReport_ExposedMembers] (
    [OfferReportingPeriodsID] INT NOT NULL,
    [FanID]                   INT NOT NULL,
    CONSTRAINT [PK__OfferReportingPeriodFanID] PRIMARY KEY CLUSTERED ([OfferReportingPeriodsID] ASC, [FanID] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_FanIDOfferReportingPeriods]
    ON [Report].[OfferReport_ExposedMembers]([FanID] ASC, [OfferReportingPeriodsID] ASC) WITH (FILLFACTOR = 70);

