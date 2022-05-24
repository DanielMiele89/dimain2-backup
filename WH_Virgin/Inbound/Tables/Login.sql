CREATE TABLE [Inbound].[Login] (
    [CustomerID]       INT            NULL,
    [LoginDateTime]    DATETIME2 (7)  NULL,
    [LoginInformation] VARCHAR (1000) NULL,
    [VirginCustomerID] INT            NULL,
    [LoadDate]         DATETIME2 (7)  NULL,
    [FileName]         NVARCHAR (100) NULL
);




GO
GRANT SELECT
    ON OBJECT::[Inbound].[Login] TO [dops_useragent]
    AS [dbo];

