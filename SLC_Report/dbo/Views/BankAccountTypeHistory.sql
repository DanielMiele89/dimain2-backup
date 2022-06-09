CREATE VIEW dbo.BankAccountTypeHistory
AS
SELECT ID, BankAccountID, [Type], StartDate, EndDate, LoyaltyFlag
FROM SLC_Snapshot.dbo.BankAccountTypeHistory