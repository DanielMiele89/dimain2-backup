﻿CREATE TABLE [Staging].[CLS_Onboarding_FilesReviewed] (
    [RecordType]                     VARCHAR (500) NULL,
    [ProjectName]                    VARCHAR (500) NULL,
    [ActionCode]                     VARCHAR (500) NULL,
    [SiteID]                         VARCHAR (500) NULL,
    [Comments]                       VARCHAR (500) NULL,
    [MC_Location]                    VARCHAR (500) NULL,
    [MC_LastSeenDate]                VARCHAR (500) NULL,
    [MerchantDBAName]                VARCHAR (500) NULL,
    [MC_MerchantDBAName]             VARCHAR (500) NULL,
    [MerchantLegalName]              VARCHAR (500) NULL,
    [MerchantAddress]                VARCHAR (500) NULL,
    [MC_MerchantAddress]             VARCHAR (500) NULL,
    [MerchantCity]                   VARCHAR (500) NULL,
    [MC_MerchantCity]                VARCHAR (500) NULL,
    [MerchantState]                  VARCHAR (500) NULL,
    [MC_MerchantState]               VARCHAR (500) NULL,
    [MerchantPostalCode]             VARCHAR (500) NULL,
    [MC_MerchantPostalCode]          VARCHAR (500) NULL,
    [MerchantCountry]                VARCHAR (500) NULL,
    [MC_MerchantCountry]             VARCHAR (500) NULL,
    [MerchantPhoneNumber]            VARCHAR (500) NULL,
    [MerchantChainID]                VARCHAR (500) NULL,
    [AcquiringMerchantID]            VARCHAR (500) NULL,
    [MC_ClearingAcquiringMerchantID] VARCHAR (500) NULL,
    [MC_ClearingAcquirerICA]         VARCHAR (500) NULL,
    [MC_AuthacquiringMerchantID]     VARCHAR (500) NULL,
    [MC_AuthacquirerICA]             VARCHAR (500) NULL,
    [MC_MCC]                         VARCHAR (500) NULL,
    [IndustryDescription]            VARCHAR (500) NULL,
    [EffectiveDate]                  VARCHAR (500) NULL,
    [EndDate]                        VARCHAR (500) NULL,
    [DiscountRate]                   VARCHAR (500) NULL,
    [MerchantURL]                    VARCHAR (500) NULL,
    [PassThru1]                      VARCHAR (500) NULL,
    [PassThru2]                      VARCHAR (500) NULL,
    [PassThru3]                      VARCHAR (500) NULL,
    [PassThru4]                      VARCHAR (500) NULL,
    [PassThru5]                      VARCHAR (500) NULL,
    [FileDate]                       VARCHAR (500) NULL,
    [FileReviewedByReward]           DATETIME      NOT NULL
);

