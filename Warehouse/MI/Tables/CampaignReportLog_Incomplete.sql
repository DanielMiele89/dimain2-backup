CREATE TABLE [MI].[CampaignReportLog_Incomplete] (
    [ID]                INT            IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef] NVARCHAR (30)  NOT NULL,
    [StartDate]         DATE           NOT NULL,
    [CalcStartDate]     DATE           NOT NULL,
    [CalcEndDate]       DATE           NOT NULL,
    [Status]            NVARCHAR (30)  DEFAULT ('Calculation Starting') NOT NULL,
    [CalcDate]          DATE           DEFAULT (getdate()) NOT NULL,
    [isError]           BIT            DEFAULT ((0)) NOT NULL,
    [ErrorDetails]      NVARCHAR (300) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

