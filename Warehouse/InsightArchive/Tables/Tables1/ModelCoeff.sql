CREATE TABLE [InsightArchive].[ModelCoeff] (
    [ID]          INT              IDENTITY (1, 1) NOT NULL,
    [BrandID]     SMALLINT         NOT NULL,
    [ColumnName]  VARCHAR (50)     NOT NULL,
    [Coefficient] DECIMAL (23, 20) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

