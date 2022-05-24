CREATE TABLE [InsightArchive].[VMCCBankFundedPOC_ControlGroups_250821] (
    [FanID]                 INT         NOT NULL,
    [CINID]                 INT         NULL,
    [AccountType]           VARCHAR (4) NOT NULL,
    [IsRetailActive_30Days] INT         NOT NULL,
    [GrocerEligible]        INT         NOT NULL,
    [AmazonEligible]        INT         NOT NULL
);

