CREATE TABLE [Staging].[Onboarding_Matcher_Visa_ActiveList] (
    [ID]                INT          IDENTITY (1, 1) NOT NULL,
    [MerchantGroupName] VARCHAR (25) NULL,
    [BIN]               VARCHAR (25) NOT NULL,
    [MerchantID]        VARCHAR (25) NOT NULL,
    [RetailOutletID]    INT          NULL,
    [StartDate]         DATE         NULL,
    [EndDate]           DATE         NULL
);

