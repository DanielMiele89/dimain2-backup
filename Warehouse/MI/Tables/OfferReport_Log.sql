CREATE TABLE [MI].[OfferReport_Log] (
    [IronOfferID]          INT           NOT NULL,
    [StartDate]            DATE          NOT NULL,
    [EndDate]              DATE          NOT NULL,
    [isPartial]            BIT           NOT NULL,
    [isCalculated]         BIT           CONSTRAINT [DF_OfferReportLog_isCalculated] DEFAULT ((0)) NOT NULL,
    [isReported]           BIT           CONSTRAINT [DF_OfferReportLog_isReported] DEFAULT ((0)) NOT NULL,
    [CalcDate]             DATETIME      CONSTRAINT [DF_OfferReportLog_CalcDate] DEFAULT (getdate()) NOT NULL,
    [ReportDate]           DATETIME      NULL,
    [MonthlyReportingDate] DATE          NULL,
    [Notes]                VARCHAR (500) CONSTRAINT [DF_OfferReportLog_Notes] DEFAULT ('Automated') NOT NULL,
    [IsError]              BIT           CONSTRAINT [DF_OfferReportLog_IsError] DEFAULT ((0)) NOT NULL,
    [ErrorDetails]         VARCHAR (500) NULL,
    CONSTRAINT [PK_OfferReportLog] PRIMARY KEY CLUSTERED ([IronOfferID] ASC, [StartDate] ASC, [EndDate] ASC)
);

