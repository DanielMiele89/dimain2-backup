CREATE VIEW dbo.[_FanSFDDailyUploadData_DirectDebit]
AS
SELECT FanID, OnTrial, Nominee, FirstDDEarn, AccountName1, AccountName2, AccountName3, Over3Accounts, AccountNumber1, AccountNumber2, AccountNumber3, FirstEligibleDate, RBSNomineeChange
FROM SLC_Snapshot.dbo.FanSFDDailyUploadData_DirectDebit