CREATE TABLE [MI].[SSAS_DimDate] (
    [DateValue]     DATE         NOT NULL,
    [WeekNumber]    TINYINT      NOT NULL,
    [MonthNumber]   TINYINT      NOT NULL,
    [MonthText]     VARCHAR (50) NOT NULL,
    [QuarterNumber] TINYINT      NOT NULL,
    [QuarterText]   VARCHAR (50) NOT NULL,
    [YearNumber]    SMALLINT     NOT NULL,
    CONSTRAINT [MI_SSAS_DimDate] PRIMARY KEY CLUSTERED ([DateValue] ASC)
);

