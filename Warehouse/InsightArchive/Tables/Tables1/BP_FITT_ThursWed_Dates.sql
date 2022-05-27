CREATE TABLE [InsightArchive].[BP_FITT_ThursWed_Dates] (
    [ID]        INT          NULL,
    [WeekDesc]  VARCHAR (40) NULL,
    [StartDate] DATE         NULL,
    [EndDate]   DATE         NULL,
    [MonthID]   INT          NULL
);


GO
CREATE CLUSTERED INDEX [Idx_Sdate]
    ON [InsightArchive].[BP_FITT_ThursWed_Dates]([StartDate] ASC);


GO
CREATE NONCLUSTERED INDEX [Idx_Edate]
    ON [InsightArchive].[BP_FITT_ThursWed_Dates]([EndDate] ASC);

