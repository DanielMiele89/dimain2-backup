CREATE TABLE [MI].[Campaign_Log] (
    [ID]                          INT            IDENTITY (1, 1) NOT NULL,
    [StoreProcedureName]          VARCHAR (400)  NULL,
    [Parameter_ClientServicesRef] VARCHAR (25)   NULL,
    [Parameter_StartDate]         DATE           NULL,
    [Parameter_DatabaseName]      NVARCHAR (400) NULL,
    [RunByUser]                   VARCHAR (100)  NULL,
    [RunStartTime]                DATETIME       NULL,
    [RunEndTime]                  DATETIME       NULL,
    [RunStartTime_Part1]          DATETIME       NULL,
    [RunStartTime_Part2]          DATETIME       NULL,
    [RunStartTime_Part3]          DATETIME       NULL,
    [RunStartTime_Part4]          DATETIME       NULL,
    [ErrorMessage]                BIT            NULL
);

