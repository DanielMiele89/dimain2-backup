CREATE VIEW dbo.BankAccount
AS
SELECT ID, SortCode, MaskedAccountNumber, EncryptedAccountNumber, [Date], [Status], LastStatusChangeDate, BankAccountUId
FROM SLC_Snapshot.dbo.BankAccount