CREATE TABLE [Michael].[MIDsValidation_Output] (
    [OutletID]   INT             NULL,
    [MerchantID] NVARCHAR (500)  NULL,
    [Address1]   NVARCHAR (4000) NULL,
    [Address2]   NVARCHAR (4000) NULL,
    [City]       NVARCHAR (4000) NULL,
    [County]     NVARCHAR (100)  NULL,
    [PostCode]   VARCHAR (500)   NULL,
    [status]     VARCHAR (10)    NOT NULL
);

