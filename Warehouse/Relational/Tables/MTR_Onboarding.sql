CREATE TABLE [Relational].[MTR_Onboarding] (
    [ID]               INT           IDENTITY (1, 1) NOT NULL,
    [PartnerName]      VARCHAR (50)  NULL,
    [MerchantAcquirer] VARCHAR (50)  NULL,
    [MerchantID]       VARCHAR (25)  NULL,
    [Address]          VARCHAR (100) NULL,
    [City]             VARCHAR (50)  NULL,
    [County]           VARCHAR (50)  NULL,
    [PostCode]         VARCHAR (25)  NULL,
    [Latitude]         VARCHAR (25)  NULL,
    [Longitude]        VARCHAR (25)  NULL,
    [ActionCode]       VARCHAR (25)  NULL,
    [LocationStatus]   VARCHAR (25)  NULL,
    [ImportDate]       DATETIME      NULL
);

