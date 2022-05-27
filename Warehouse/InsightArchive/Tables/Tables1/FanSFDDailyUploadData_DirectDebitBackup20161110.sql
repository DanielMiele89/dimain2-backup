CREATE TABLE [InsightArchive].[FanSFDDailyUploadData_DirectDebitBackup20161110] (
    [FanID]             INT          NOT NULL,
    [OnTrial]           BIT          NOT NULL,
    [Nominee]           BIT          NOT NULL,
    [FirstDDEarn]       DATE         NULL,
    [AccountName1]      VARCHAR (40) NULL,
    [AccountName2]      VARCHAR (40) NULL,
    [AccountName3]      VARCHAR (40) NULL,
    [Over3Accounts]     BIT          NOT NULL,
    [AccountNumber1]    VARCHAR (3)  NULL,
    [AccountNumber2]    VARCHAR (3)  NULL,
    [AccountNumber3]    VARCHAR (3)  NULL,
    [FirstEligibleDate] DATE         NULL,
    [RBSNomineeChange]  BIT          NOT NULL
);

