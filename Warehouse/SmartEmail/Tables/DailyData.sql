﻿CREATE TABLE [SmartEmail].[DailyData] (
    [Email]                        VARCHAR (255) NOT NULL,
    [FanID]                        INT           NOT NULL,
    [ClubID]                       INT           NOT NULL,
    [ClubName]                     VARCHAR (50)  NOT NULL,
    [FirstName]                    VARCHAR (64)  NULL,
    [LastName]                     VARCHAR (64)  NULL,
    [DOB]                          DATE          NULL,
    [Sex]                          BIT           NULL,
    [FromAddress]                  VARCHAR (100) NOT NULL,
    [FromName]                     VARCHAR (100) NOT NULL,
    [ClubCashAvailable]            SMALLMONEY    NOT NULL,
    [ClubCashPending]              SMALLMONEY    NOT NULL,
    [PartialPostCode]              VARCHAR (5)   NULL,
    [Title]                        VARCHAR (24)  NULL,
    [AgreedTcsDate]                DATETIME      NOT NULL,
    [WelcomeEmailCode]             VARCHAR (5)   NULL,
    [IsDebit]                      BIT           NOT NULL,
    [IsCredit]                     BIT           NOT NULL,
    [Nominee]                      BIT           NOT NULL,
    [RBSNomineeChange]             BIT           NOT NULL,
    [LoyaltyAccount]               BIT           NOT NULL,
    [IsLoyalty]                    BIT           NOT NULL,
    [FirstEarnDate]                DATE          NULL,
    [FirstEarnType]                VARCHAR (255) NULL,
    [Reached5GBP]                  DATE          NULL,
    [Homemover]                    BIT           NULL,
    [Day60AccountName]             VARCHAR (255) NULL,
    [Day120AccountName]            VARCHAR (255) NULL,
    [JointAccount]                 BIT           NULL,
    [FulfillmentTypeID]            INT           NULL,
    [CaffeNeroBirthdayCode]        VARCHAR (255) NULL,
    [ExpiryDate]                   DATE          NULL,
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
    [Marketable]                   BIT           NOT NULL,
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
    [CustomField12]                DATE          NULL,
    CONSTRAINT [PK_DailyData] PRIMARY KEY CLUSTERED ([FanID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Email_IncFan]
    ON [SmartEmail].[DailyData]([Email] ASC)
    INCLUDE([FanID]);

