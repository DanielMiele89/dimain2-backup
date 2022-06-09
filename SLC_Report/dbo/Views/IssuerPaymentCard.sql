CREATE VIEW dbo.IssuerPaymentCard
AS
SELECT ID, IssuerCustomerID, BankAccountID, PaymentCardID, [Date], [Status], StatusChangeDate
FROM SLC_Snapshot.dbo.IssuerPaymentCard
GO
GRANT SELECT
    ON OBJECT::[dbo].[IssuerPaymentCard] TO [Analyst]
    AS [dbo];

