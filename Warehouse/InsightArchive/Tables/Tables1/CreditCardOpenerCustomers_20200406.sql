CREATE TABLE [InsightArchive].[CreditCardOpenerCustomers_20200406] (
    [CustomerID] INT           NOT NULL,
    [Brand]      VARCHAR (7)   NULL,
    [Private]    VARCHAR (1)   NULL,
    [Title]      VARCHAR (20)  NULL,
    [Firstname]  VARCHAR (50)  NULL,
    [Lastname]   VARCHAR (50)  NULL,
    [Address1]   VARCHAR (100) NULL,
    [Address2]   VARCHAR (100) NULL,
    [City]       VARCHAR (100) NULL,
    [County]     VARCHAR (100) NULL,
    [Postcode]   VARCHAR (10)  NULL,
    [Type]       VARCHAR (1)   NULL
);




GO
DENY SELECT
    ON OBJECT::[InsightArchive].[CreditCardOpenerCustomers_20200406] TO [New_PIIRemoved]
    AS [dbo];

