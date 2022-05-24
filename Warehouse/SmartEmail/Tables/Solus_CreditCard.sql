CREATE TABLE [SmartEmail].[Solus_CreditCard] (
    [FanID]            INT        NULL,
    [ClubID]           INT        NULL,
    [AvailableBalance] SMALLMONEY NULL
);


GO
GRANT UPDATE
    ON OBJECT::[SmartEmail].[Solus_CreditCard] TO [gas]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[SmartEmail].[Solus_CreditCard] TO [gas]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[SmartEmail].[Solus_CreditCard] TO [gas]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[SmartEmail].[Solus_CreditCard] TO [gas]
    AS [dbo];


GO
GRANT ALTER
    ON OBJECT::[SmartEmail].[Solus_CreditCard] TO [gas]
    AS [dbo];

