﻿CREATE TABLE [Staging].[Onboarding_Matcher_Mastercard_SubmittedFiles] (
    [ID]                             INT             IDENTITY (1, 1) NOT NULL,
    [RecordType]                     VARCHAR (2)     NULL,
    [ProjectName]                    VARCHAR (20)    NULL,
    [ActionCode]                     VARCHAR (1)     NULL,
    [SiteID]                         VARCHAR (30)    NULL,
    [Comments]                       VARCHAR (1)     NULL,
    [MC_Location]                    VARCHAR (1)     NULL,
    [MC_LastSeenDate]                VARCHAR (1)     NULL,
    [MerchantDBAName]                NVARCHAR (4000) NULL,
    [MC_MerchantDBAName]             VARCHAR (1)     NULL,
    [MerchantLegalName]              NVARCHAR (200)  NULL,
    [MerchantAddress]                NVARCHAR (4000) NULL,
    [MC_MerchantAddress]             VARCHAR (1)     NULL,
    [MerchantCity]                   NVARCHAR (4000) NULL,
    [MC_MerchantCity]                VARCHAR (1)     NULL,
    [MerchantState]                  NVARCHAR (4000) NULL,
    [MC_MerchantState]               VARCHAR (1)     NULL,
    [MerchantPostalCode]             NVARCHAR (4000) NULL,
    [MC_MerchantPostalCode]          VARCHAR (1)     NULL,
    [MerchantCountry]                VARCHAR (5)     NULL,
    [MC_MerchantCountry]             VARCHAR (1)     NULL,
    [MerchantPhoneNumber]            VARCHAR (50)    NULL,
    [MerchantChainID]                VARCHAR (1)     NULL,
    [AcquiringMerchantID]            NVARCHAR (50)   NULL,
    [MC_ClearingAcquiringMerchantID] VARCHAR (1)     NULL,
    [MC_ClearingAcquirerICA]         VARCHAR (1)     NULL,
    [MC_AuthacquiringMerchantID]     VARCHAR (1)     NULL,
    [MC_AuthacquirerICA]             VARCHAR (1)     NULL,
    [MC_MCC]                         VARCHAR (1)     NULL,
    [IndustryDescription]            VARCHAR (1)     NULL,
    [EffectiveDate]                  VARCHAR (8000)  NULL,
    [EndDate]                        VARCHAR (8000)  NULL,
    [DiscountRate]                   VARCHAR (1)     NULL,
    [MerchantURL]                    VARCHAR (1)     NULL,
    [PassThru1]                      VARCHAR (10)    NULL,
    [PassThru2]                      VARCHAR (10)    NULL,
    [PassThru3]                      VARCHAR (10)    NULL,
    [PassThru4]                      VARCHAR (10)    NULL,
    [PassThru5]                      VARCHAR (10)    NULL,
    [FileDate]                       VARCHAR (8000)  NULL,
    [FileName]                       VARCHAR (500)   NULL,
    [IsFileReviewed]                 INT             NULL
);
