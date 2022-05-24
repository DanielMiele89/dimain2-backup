CREATE TABLE [MI].[DailyMICallCentre] (
    [id]                             INT           IDENTITY (1, 1) NOT NULL,
    [BankBrand]                      NVARCHAR (50) NOT NULL,
    [CallsReceived]                  INT           NOT NULL,
    [CallsReceivedCumulativeToDate]  INT           NOT NULL,
    [CallsAbandoned]                 INT           NOT NULL,
    [CallsAbandonedCumulativeToDate] INT           NOT NULL,
    [AverageCallLength]              TIME (7)      NULL,
    [EmailReceived]                  INT           NOT NULL,
    [EmailsReceivedCumulativeToDate] INT           NOT NULL,
    [OutstandingEmails]              INT           NOT NULL,
    [ReportDate]                     DATE          NOT NULL,
    CONSTRAINT [PK_MI_DailyMICallCentre] PRIMARY KEY CLUSTERED ([id] ASC)
);

