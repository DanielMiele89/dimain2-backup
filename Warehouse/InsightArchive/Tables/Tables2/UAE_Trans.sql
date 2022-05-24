CREATE TABLE [InsightArchive].[UAE_Trans] (
    [FileID]                INT          NOT NULL,
    [RowNum]                INT          NOT NULL,
    [ConsumerCombinationID] INT          NOT NULL,
    [CINID]                 INT          NOT NULL,
    [CardholderPresentData] TINYINT      NOT NULL,
    [InputModeID]           TINYINT      NOT NULL,
    [LocationDebit]         VARCHAR (50) NOT NULL,
    [LocationCity]          VARCHAR (50) NOT NULL,
    [LocationCredit]        VARCHAR (50) NOT NULL,
    [PaymentTypeID]         TINYINT      NOT NULL,
    [Spend]                 MONEY        NOT NULL,
    [TranDate]              DATE         NOT NULL,
    CONSTRAINT [PK_InsightArchive_UAE_Trans] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC)
);

