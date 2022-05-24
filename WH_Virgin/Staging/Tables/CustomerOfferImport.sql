CREATE TABLE [Staging].[CustomerOfferImport] (
    [hashKey]               NVARCHAR (50) NULL,
    [fanId]                 INT           NULL,
    [slcCustomerId]         NVARCHAR (50) NULL,
    [offerId]               NVARCHAR (50) NULL,
    [registrationStartDate] DATETIME2 (7) NULL,
    [endDate]               DATETIME2 (7) NULL
);

