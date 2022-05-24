CREATE TABLE [Staging].[FanSFDDailyUploadData_DirectDebit] (
    [FanID]             INT          NOT NULL,
    [OnTrial]           BIT          CONSTRAINT [df_FanSFDDailyUploadDataDirectDebit_OnTrial] DEFAULT ((1)) NOT NULL,
    [Nominee]           BIT          CONSTRAINT [df_FanSFDDailyUploadDataDirectDebit_Nominee] DEFAULT ((0)) NOT NULL,
    [FirstDDEarn]       DATE         NULL,
    [AccountName1]      VARCHAR (40) NULL,
    [AccountName2]      VARCHAR (40) NULL,
    [AccountName3]      VARCHAR (40) NULL,
    [Over3Accounts]     BIT          CONSTRAINT [df_FanSFDDailyUploadDataDirectDebit_Over3Accounts] DEFAULT ((0)) NOT NULL,
    [AccountNumber1]    VARCHAR (3)  NULL,
    [AccountNumber2]    VARCHAR (3)  NULL,
    [AccountNumber3]    VARCHAR (3)  NULL,
    [FirstEligibleDate] DATE         NULL,
    [RBSNomineeChange]  BIT          CONSTRAINT [df_FanSFDDailyUploadDataDirectDebit_RBSNomineeChange] DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);


GO
DENY SELECT
    ON OBJECT::[Staging].[FanSFDDailyUploadData_DirectDebit] TO [New_PIIRemoved]
    AS [dbo];

