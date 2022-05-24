CREATE TABLE [MI].[TimeRange] (
    [ID]        TINYINT      IDENTITY (1, 1) NOT NULL,
    [StartTime] TIME (7)     NOT NULL,
    [EndTime]   TIME (7)     NOT NULL,
    [TimeDesc]  VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_MI_TimeRange] PRIMARY KEY CLUSTERED ([ID] ASC)
);

