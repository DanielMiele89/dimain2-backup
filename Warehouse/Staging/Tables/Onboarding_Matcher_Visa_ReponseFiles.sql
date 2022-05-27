CREATE TABLE [Staging].[Onboarding_Matcher_Visa_ReponseFiles] (
    [ID]             INT           IDENTITY (1, 1) NOT NULL,
    [BIN]            INT           NULL,
    [MerchantID]     VARCHAR (50)  NULL,
    [RetailOutletID] VARCHAR (50)  NULL,
    [StartDate]      DATE          NULL,
    [EndDate]        DATE          NULL,
    [FileName]       VARCHAR (100) NULL,
    [ImportDate]     DATE          NULL,
    [ValidationDate] DATE          NULL
);

