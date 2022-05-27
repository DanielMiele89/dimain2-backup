CREATE TABLE [InsightArchive].[VMCCBankFundedPOC_CustomerCategorisation] (
    [FanID]                 INT          NULL,
    [CINID]                 INT          NULL,
    [IsControl]             INT          NOT NULL,
    [Eligibility]           VARCHAR (11) NULL,
    [AccountType]           VARCHAR (4)  NOT NULL,
    [IsRetailActive_30Days] INT          NOT NULL,
    [HasOpened]             INT          NULL
);

