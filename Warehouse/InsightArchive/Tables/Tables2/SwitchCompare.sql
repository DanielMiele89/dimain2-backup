CREATE TABLE [InsightArchive].[SwitchCompare] (
    [ID]           INT          IDENTITY (1, 1) NOT NULL,
    [BrandID]      SMALLINT     NOT NULL,
    [CompareDesc]  VARCHAR (50) NOT NULL,
    [IsSwitcher]   BIT          NOT NULL,
    [Spend]        MONEY        NOT NULL,
    [TranCount]    BIGINT       NOT NULL,
    [SpenderCount] BIGINT       NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

