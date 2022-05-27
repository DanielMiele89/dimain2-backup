CREATE TABLE [InsightArchive].[KuwaitComboSpend] (
    [id]                    INT      IDENTITY (1, 1) NOT NULL,
    [ConsumerCombinationID] INT      NOT NULL,
    [tranmonth]             TINYINT  NOT NULL,
    [tranyear]              SMALLINT NOT NULL,
    [spend]                 MONEY    NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

