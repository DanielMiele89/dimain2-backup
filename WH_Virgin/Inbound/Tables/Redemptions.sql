CREATE TABLE [Inbound].[Redemptions] (
    [CustomerID]     INT            NULL,
    [RedemptionDate] DATETIME2 (7)  NULL,
    [RedemptionType] VARCHAR (8)    NULL,
    [Amount]         SMALLMONEY     NULL,
    [LoadDate]       DATETIME2 (7)  NULL,
    [FileName]       NVARCHAR (100) NULL
);




GO
GRANT UPDATE
    ON OBJECT::[Inbound].[Redemptions] TO [crtimport]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[Inbound].[Redemptions] TO [crtimport]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Inbound].[Redemptions] TO [crtimport]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[Inbound].[Redemptions] TO [crtimport]
    AS [dbo];

