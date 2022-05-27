﻿CREATE TABLE [SmartEmail].[TestGroupBTCustomers] (
    [Email]                        VARCHAR (255) NOT NULL,
    [FanID]                        INT           NOT NULL,
    [ClubID]                       INT           NOT NULL,
    [ClubName]                     VARCHAR (50)  NOT NULL,
    [FirstName]                    VARCHAR (64)  NULL,
    [LastName]                     VARCHAR (64)  NULL,
    [DOB]                          VARCHAR (30)  NULL,
    [Sex]                          TINYINT       NULL,
    [FromAddress]                  VARCHAR (100) NOT NULL,
    [FromName]                     VARCHAR (100) NOT NULL,
    [ClubCashAvailable]            SMALLMONEY    NOT NULL,
    [ClubCashPending]              SMALLMONEY    NOT NULL,
    [PartialPostCode]              VARCHAR (5)   NULL,
    [Title]                        VARCHAR (24)  NULL,
    [AgreedTcsDate]                VARCHAR (61)  NULL,
    [SmartEmailSendID]             INT           NULL,
    [Offer1]                       INT           NULL,
    [Offer2]                       INT           NULL,
    [Offer3]                       INT           NULL,
    [Offer4]                       INT           NULL,
    [Offer5]                       INT           NULL,
    [Offer6]                       INT           NULL,
    [Offer7]                       INT           NULL,
    [Offer1StartDate]              VARCHAR (30)  NULL,
    [Offer2StartDate]              VARCHAR (30)  NULL,
    [Offer3StartDate]              VARCHAR (30)  NULL,
    [Offer4StartDate]              VARCHAR (30)  NULL,
    [Offer5StartDate]              VARCHAR (30)  NULL,
    [Offer6StartDate]              VARCHAR (30)  NULL,
    [Offer7StartDate]              VARCHAR (30)  NULL,
    [Offer1EndDate]                VARCHAR (30)  NULL,
    [Offer2EndDate]                VARCHAR (30)  NULL,
    [Offer3EndDate]                VARCHAR (30)  NULL,
    [Offer4EndDate]                VARCHAR (30)  NULL,
    [Offer5EndDate]                VARCHAR (30)  NULL,
    [Offer6EndDate]                VARCHAR (30)  NULL,
    [Offer7EndDate]                VARCHAR (30)  NULL,
    [RedeemOffer1]                 INT           NULL,
    [RedeemOffer2]                 INT           NULL,
    [RedeemOffer3]                 INT           NULL,
    [RedeemOffer4]                 INT           NULL,
    [RedeemOffer5]                 INT           NULL,
    [RedeemOffer1EndDate]          VARCHAR (30)  NULL,
    [RedeemOffer2EndDate]          VARCHAR (30)  NULL,
    [RedeemOffer3EndDate]          VARCHAR (30)  NULL,
    [RedeemOffer4EndDate]          VARCHAR (30)  NULL,
    [RedeemOffer5EndDate]          VARCHAR (30)  NULL,
    [WelcomeEmailCode]             VARCHAR (5)   NULL,
    [IsDebit]                      TINYINT       NULL,
    [IsCredit]                     TINYINT       NULL,
    [Nominee]                      TINYINT       NULL,
    [RBSNomineeChange]             TINYINT       NULL,
    [LoyaltyAccount]               TINYINT       NULL,
    [IsLoyalty]                    TINYINT       NULL,
    [FirstEarnDate]                VARCHAR (30)  NULL,
    [FirstEarnType]                VARCHAR (255) NULL,
    [Reached5GBP]                  VARCHAR (30)  NULL,
    [Homemover]                    TINYINT       NULL,
    [Day60AccountName]             VARCHAR (255) NULL,
    [Day120AccountName]            VARCHAR (255) NULL,
    [JointAccount]                 TINYINT       NULL,
    [FulfillmentTypeID]            INT           NULL,
    [CaffeNeroBirthdayCode]        VARCHAR (255) NULL,
    [ExpiryDate]                   VARCHAR (30)  NULL,
    [LvTotalEarning]               SMALLMONEY    NOT NULL,
    [LvCurrentMonthEarning]        SMALLMONEY    NOT NULL,
    [LvMonth1Earning]              SMALLMONEY    NOT NULL,
    [LvMonth2Earning]              SMALLMONEY    NOT NULL,
    [LvMonth3Earning]              SMALLMONEY    NOT NULL,
    [LvMonth4Earning]              SMALLMONEY    NOT NULL,
    [LvMonth5Earning]              SMALLMONEY    NOT NULL,
    [LvMonth6Earning]              SMALLMONEY    NOT NULL,
    [LvMonth7Earning]              SMALLMONEY    NOT NULL,
    [LvMonth8Earning]              SMALLMONEY    NOT NULL,
    [LvMonth9Earning]              SMALLMONEY    NOT NULL,
    [LvMonth10Earning]             SMALLMONEY    NOT NULL,
    [LvMonth11Earning]             SMALLMONEY    NOT NULL,
    [LvCPOSEarning]                SMALLMONEY    NOT NULL,
    [LvDPOSEarning]                SMALLMONEY    NOT NULL,
    [LvDDEarning]                  SMALLMONEY    NOT NULL,
    [LvOtherEarning]               SMALLMONEY    NOT NULL,
    [LvCurrentAnniversaryEarning]  SMALLMONEY    NOT NULL,
    [LvPreviousAnniversaryEarning] SMALLMONEY    NOT NULL,
    [LvEAYBEarning]                SMALLMONEY    NOT NULL,
    [Marketable]                   TINYINT       NULL,
    [CustomField1]                 VARCHAR (255) NULL,
    [CustomField2]                 VARCHAR (255) NULL,
    [CustomField3]                 VARCHAR (255) NULL,
    [CustomField4]                 VARCHAR (255) NULL,
    [CustomField5]                 VARCHAR (255) NULL,
    [CustomField6]                 VARCHAR (255) NULL,
    [CustomField7]                 VARCHAR (255) NULL,
    [CustomField8]                 VARCHAR (255) NULL,
    [CustomField9]                 VARCHAR (255) NULL,
    [CustomField10]                VARCHAR (255) NULL,
    [CustomField11]                INT           NULL,
    [CustomField12]                VARCHAR (30)  NULL
);
