CREATE TABLE [InsightArchive].[cohortspend] (
    [ID]          INT     IDENTITY (1, 1) NOT NULL,
    [TranMonth]   DATE    NOT NULL,
    [cinid]       INT     NOT NULL,
    [spend]       MONEY   NOT NULL,
    [trancount]   INT     NOT NULL,
    [MonthNumber] TINYINT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

