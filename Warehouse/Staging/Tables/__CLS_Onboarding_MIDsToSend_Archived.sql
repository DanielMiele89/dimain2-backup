CREATE TABLE [Staging].[__CLS_Onboarding_MIDsToSend_Archived] (
    [ID]                 INT          IDENTITY (1, 1) NOT NULL,
    [PrimaryPartnerID]   INT          NULL,
    [PrimaryPartnerName] VARCHAR (50) NULL,
    [RetailOutletID]     INT          NULL,
    [MerchantID]         VARCHAR (50) NULL,
    [LastSendDate]       DATE         NULL,
    [IsFileCreated]      BIT          NULL
);

