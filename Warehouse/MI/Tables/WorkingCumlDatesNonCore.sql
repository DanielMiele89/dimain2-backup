CREATE TABLE [MI].[WorkingCumlDatesNonCore] (
    [ID]                TINYINT       IDENTITY (1, 1) NOT NULL,
    [Partnerid]         INT           NOT NULL,
    [Cumlitivetype]     INT           NOT NULL,
    [ClientServicesref] NVARCHAR (30) NOT NULL,
    [StartDate]         DATE          NOT NULL,
    [Dateid]            INT           NOT NULL,
    [StartMonthID]      INT           NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

