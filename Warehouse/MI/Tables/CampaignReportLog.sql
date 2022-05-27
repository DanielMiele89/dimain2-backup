CREATE TABLE [MI].[CampaignReportLog] (
    [LogID]              INT           IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef]  VARCHAR (40)  NOT NULL,
    [StartDate]          DATE          NOT NULL,
    [Status]             VARCHAR (50)  CONSTRAINT [DF_CampaignReportLog_Status] DEFAULT ('Calculation Starting') NOT NULL,
    [CalcDate]           DATETIME      CONSTRAINT [DF_MI_CampaignReportLog_CalcDate] DEFAULT (getdate()) NOT NULL,
    [ReportDate]         DATETIME      NULL,
    [Reason]             VARCHAR (50)  CONSTRAINT [DF_MI_CampaignReportLog_Reason] DEFAULT ('Automated') NOT NULL,
    [IsError]            BIT           CONSTRAINT [DF_MI_CampaignReportLog_IsError] DEFAULT ((0)) NOT NULL,
    [ErrorDetails]       VARCHAR (500) NULL,
    [ExtendedPeriod]     BIT           CONSTRAINT [DF_CampaignReportLog_ExtendedPeriod] DEFAULT ((0)) NOT NULL,
    [SummedCampVal]      FLOAT (53)    NULL,
    [SummedFinalResults] FLOAT (53)    NULL,
    CONSTRAINT [PK_MI_CampaignReportLog] PRIMARY KEY CLUSTERED ([LogID] ASC)
);

