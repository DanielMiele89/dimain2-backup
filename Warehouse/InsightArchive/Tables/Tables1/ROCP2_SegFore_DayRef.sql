CREATE TABLE [InsightArchive].[ROCP2_SegFore_DayRef] (
    [DateID]    INT         NOT NULL,
    [LineDate]  DATE        NULL,
    [weeknum]   BIGINT      NULL,
    [StartDate] DATE        NULL,
    [Enddate]   DATE        NULL,
    [day]       INT         NULL,
    [dmonth]    INT         NULL,
    [year]      INT         NULL,
    [MonthID1]  VARCHAR (7) NULL,
    [MonthID2]  VARCHAR (7) NULL
);

