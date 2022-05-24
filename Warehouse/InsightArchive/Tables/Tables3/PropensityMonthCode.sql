CREATE TABLE [InsightArchive].[PropensityMonthCode] (
    [MonthNo] TINYINT IDENTITY (1, 1) NOT NULL,
    [IsJan]   TINYINT NOT NULL,
    [IsFeb]   TINYINT NOT NULL,
    [IsMar]   TINYINT NOT NULL,
    [IsApr]   TINYINT NOT NULL,
    [IsMay]   TINYINT NOT NULL,
    [IsJun]   TINYINT NOT NULL,
    [IsJul]   TINYINT NOT NULL,
    [IsAug]   TINYINT NOT NULL,
    [IsSep]   TINYINT NOT NULL,
    [IsOct]   TINYINT NOT NULL,
    [IsNov]   TINYINT NOT NULL,
    [IsDec]   TINYINT NOT NULL,
    PRIMARY KEY CLUSTERED ([MonthNo] ASC)
);

