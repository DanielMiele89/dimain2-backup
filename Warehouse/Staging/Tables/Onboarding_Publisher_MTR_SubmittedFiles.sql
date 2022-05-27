CREATE TABLE [Staging].[Onboarding_Publisher_MTR_SubmittedFiles] (
    [ID]                     INT           IDENTITY (1, 1) NOT NULL,
    [PartnerID]              INT           NULL,
    [PartnerName]            VARCHAR (50)  NULL,
    [Address]                VARCHAR (100) NULL,
    [City]                   VARCHAR (50)  NULL,
    [County]                 VARCHAR (50)  NULL,
    [Postcode]               VARCHAR (50)  NULL,
    [MerchantID]             VARCHAR (50)  NULL,
    [MerchantAcquirer]       VARCHAR (50)  NULL,
    [Latitude]               VARCHAR (50)  NULL,
    [Longitude]              VARCHAR (50)  NULL,
    [ActionCode]             VARCHAR (50)  NULL,
    [PartnerOutletReference] VARCHAR (50)  NULL,
    [Channel]                INT           NULL,
    [StartDate]              DATE          NULL,
    [EndDate]                DATE          NULL,
    [SubmittedDate]          DATE          NULL
);

