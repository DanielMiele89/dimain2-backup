CREATE TABLE [Staging].[Onboarding_Matcher_Visa_SubmittedFiles] (
    [ID]                      INT           IDENTITY (1, 1) NOT NULL,
    [MerchantID]              VARCHAR (50)  NULL,
    [PartnerName]             VARCHAR (100) NULL,
    [City]                    VARCHAR (100) NULL,
    [Address]                 VARCHAR (202) NULL,
    [Postcode]                VARCHAR (20)  NULL,
    [RegisteredName]          VARCHAR (100) NULL,
    [AcquirerBIN]             VARCHAR (100) NULL,
    [AcquirerName]            VARCHAR (100) NULL,
    [MerchantCountryCode_ISO] INT           NULL,
    [OnlineInStore]           VARCHAR (8)   NULL,
    [RetailOutletID]          INT           NULL,
    [Result]                  VARCHAR (500) NULL,
    [ResultReason]            VARCHAR (500) NULL,
    [SentDate]                DATE          NULL,
    [ValidationDate]          DATE          NULL
);

