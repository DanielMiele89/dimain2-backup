CREATE TABLE [APW].[WeeksToProcess] (
    [WeekID]        TINYINT IDENTITY (1, 1) NOT NULL,
    [WeekStartDate] DATE    NOT NULL,
    [WeekEndDate]   DATE    NOT NULL,
    CONSTRAINT [PK_BI_WeeksToProcess] PRIMARY KEY CLUSTERED ([WeekID] ASC)
);

