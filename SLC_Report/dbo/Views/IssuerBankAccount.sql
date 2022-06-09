CREATE VIEW dbo.IssuerBankAccount
AS
SELECT ID, IssuerCustomerID, BankAccountID, [Date], CustomerStatus, LastCustomerStatusChangeDate, IssuerBankAccountUID
FROM SLC_Snapshot.dbo.IssuerBankAccount