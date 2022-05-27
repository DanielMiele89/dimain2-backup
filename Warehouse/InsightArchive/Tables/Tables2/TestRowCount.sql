CREATE TABLE [InsightArchive].[TestRowCount] (
    [ID]         INT      IDENTITY (1, 1) NOT NULL,
    [TblRows]    INT      NOT NULL,
    [SetTbls]    INT      NOT NULL,
    [InsertDate] DATETIME DEFAULT (getdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);




GO
GRANT INSERT
    ON OBJECT::[InsightArchive].[TestRowCount] TO [gas]
    AS [dbo];

