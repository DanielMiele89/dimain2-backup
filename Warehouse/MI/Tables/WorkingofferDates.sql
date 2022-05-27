CREATE TABLE [MI].[WorkingofferDates] (
    [id]                INT           IDENTITY (1, 1) NOT NULL,
    [Partnerid]         INT           NOT NULL,
    [ClientServicesref] NVARCHAR (30) NOT NULL,
    [StartDate]         DATE          NOT NULL,
    [EndDate]           DATE          NOT NULL,
    [Dateid]            INT           NOT NULL
);

