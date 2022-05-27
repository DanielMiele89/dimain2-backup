CREATE TABLE [MI].[Calendar] (
    [CalendarDate]       DATE         NOT NULL,
    [MonthNumber]        TINYINT      NOT NULL,
    [MonthDesc]          VARCHAR (50) NOT NULL,
    [WeekDayNumber]      TINYINT      NOT NULL,
    [WeekDayName]        VARCHAR (50) NOT NULL,
    [WeekNumber]         TINYINT      NOT NULL,
    [WeekDesc]           VARCHAR (50) NULL,
    [WorkingDayTypeID]   TINYINT      NOT NULL,
    [QuarterNumber]      TINYINT      NOT NULL,
    [YearNumber]         SMALLINT     NOT NULL,
    [IsCurrentMonth]     BIT          NOT NULL,
    [IsLastMonth]        BIT          NOT NULL,
    [IsLastYear]         BIT          NOT NULL,
    [IsCumulative]       BIT          NOT NULL,
    [MonthStart]         DATE         NOT NULL,
    [MonthEnd]           DATE         NOT NULL,
    [IsYear]             BIT          NOT NULL,
    [IsYTD]              BIT          NOT NULL,
    [IsWeeklySummary]    BIT          NOT NULL,
    [WeekNumberMonStart] TINYINT      NULL,
    [IsYTDRMR]           BIT          NULL
);

