CREATE TABLE [MI].[WebLoginWeek] (
    [ID]            INT          IDENTITY (1, 1) NOT NULL,
    [WeekDesc]      VARCHAR (50) NOT NULL,
    [WeekStartDate] DATE         NOT NULL,
    [LoginCount]    INT          NOT NULL,
    [CustomerCount] INT          NOT NULL,
    CONSTRAINT [PK_MI_WebLoginWeek] PRIMARY KEY CLUSTERED ([ID] ASC)
);

