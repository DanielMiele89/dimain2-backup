CREATE VIEW dbo.DDCashbackNominee
AS
SELECT ID, BankAccountID, IssuerCustomerID, StartDate, EndDate, RequestedBy, ChangeSourceType, ActionedBy, ChangedDate
FROM SLC_Snapshot.dbo.DDCashbackNominee