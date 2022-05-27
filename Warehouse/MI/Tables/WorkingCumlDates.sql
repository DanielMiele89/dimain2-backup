CREATE TABLE [MI].[WorkingCumlDates] (
    [id]                INT           IDENTITY (1, 1) NOT NULL,
    [Cumlitivetype]     INT           NOT NULL,
    [Partnerid]         INT           NOT NULL,
    [ClientServicesref] NVARCHAR (30) NOT NULL,
    [StartDate]         DATE          NOT NULL,
    [Dateid]            INT           NOT NULL,
    [StartMonthID]      INT           NULL
);

