CREATE TABLE [Staging].[MerchantDataDedupe_Import] (
    [ID]        INT           IDENTITY (1, 1) NOT NULL,
    [Email]     VARCHAR (500) NULL,
    [FirstName] VARCHAR (500) NULL,
    [LastName]  VARCHAR (500) NULL,
    [Address1]  VARCHAR (500) NULL,
    [Postcode]  VARCHAR (500) NULL
);

