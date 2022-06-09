CREATE VIEW dbo.IssuerCustomerAttribute
AS
SELECT ID, IssuerCustomerID, AttributeID, StartDate, EndDate, Value
FROM SLC_Snapshot.dbo.IssuerCustomerAttribute