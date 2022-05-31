CREATE TABLE [dbo].[LionUploadData_History] (
    [Email]                     NVARCHAR (100) NOT NULL,
    [FanID]                     INT            NOT NULL,
    [Username]                  NVARCHAR (20)  NOT NULL,
    [ActivityStatus]            INT            NOT NULL,
    [ClubID]                    INT            NOT NULL,
    [ClubName]                  NVARCHAR (100) NOT NULL,
    [ContactByPhone]            BIT            NOT NULL,
    [ContactBySms]              BIT            NOT NULL,
    [Country]                   NVARCHAR (80)  NULL,
    [FirstName]                 NVARCHAR (50)  NULL,
    [LastName]                  NVARCHAR (50)  NOT NULL,
    [DOB]                       DATETIME       NOT NULL,
    [EmailVerification]         NVARCHAR (8)   NOT NULL,
    [Sex]                       TINYINT        NOT NULL,
    [FromAddress]               NVARCHAR (50)  NOT NULL,
    [FromName]                  NVARCHAR (80)  NOT NULL,
    [LastLoginDate]             DATETIME       NULL,
    [LastEmailOpenDate]         DATETIME       NULL,
    [EngagementSegment]         INT            NOT NULL,
    [LastUpdatedDate]           DATETIME       NOT NULL,
    [MobileTelephone]           NVARCHAR (50)  NOT NULL,
    [Password]                  NVARCHAR (20)  NOT NULL,
    [ClubCashAvailable]         NVARCHAR (30)  NOT NULL,
    [ClubCashPending]           NVARCHAR (30)  NOT NULL,
    [Postcode]                  NVARCHAR (20)  NOT NULL,
    [PartialPostCode]           NVARCHAR (20)  NULL,
    [RegistrationDate]          DATETIME       NULL,
    [Telephone]                 NVARCHAR (50)  NOT NULL,
    [Title]                     NVARCHAR (20)  NOT NULL,
    [SpendCount_AFL]            INT            NOT NULL,
    [SpendCount_CRP]            INT            NOT NULL,
    [RedeemCount]               INT            NOT NULL,
    [SpendMoney_AFL]            MONEY          NOT NULL,
    [SpendMoney_CRP]            MONEY          NOT NULL,
    [LastSpendDate_AFL]         DATETIME       NULL,
    [LastSpendDate_CRP]         DATETIME       NULL,
    [LastSpendPartner_AFL]      NVARCHAR (100) NULL,
    [LastSpendPartner_CRP]      NVARCHAR (100) NULL,
    [LastSpendPoints_AFL]       INT            NULL,
    [LastSpendPoints_CRP]       INT            NULL,
    [LastRedeemDate]            DATETIME       NULL,
    [LastRedeemPoints]          INT            NULL,
    [LastRedeemItem]            NVARCHAR (100) NULL,
    [CardsRegistered]           INT            NOT NULL,
    [LifeStage]                 TINYINT        NOT NULL,
    [InitialDataSource]         INT            NULL,
    [ClubCashEnabled]           BIT            NOT NULL,
    [SainsburysLastTopupAmount] NVARCHAR (37)  NULL,
    [SainsburysLastTopupAward]  NVARCHAR (37)  NULL,
    [SainsburysGiftcardOrdered] INT            NOT NULL,
    [LionSendID]                INT            NULL,
    [Offer1]                    INT            NULL,
    [Offer1Title]               TEXT           NULL,
    [Offer1Description]         TEXT           NULL,
    [Offer1Image]               NVARCHAR (206) NULL,
    [Offer1Link]                NVARCHAR (145) NULL,
    [Offer2]                    INT            NULL,
    [Offer2Title]               TEXT           NULL,
    [Offer2Description]         TEXT           NULL,
    [Offer2Image]               NVARCHAR (206) NULL,
    [Offer2Link]                NVARCHAR (145) NULL,
    [Offer3]                    INT            NULL,
    [Offer3Title]               TEXT           NULL,
    [Offer3Description]         TEXT           NULL,
    [Offer3Image]               NVARCHAR (206) NULL,
    [Offer3Link]                NVARCHAR (145) NULL,
    [Offer4]                    INT            NULL,
    [Offer4Title]               TEXT           NULL,
    [Offer4Description]         TEXT           NULL,
    [Offer4Image]               NVARCHAR (206) NULL,
    [Offer4Link]                NVARCHAR (145) NULL,
    [Offer5]                    INT            NULL,
    [Offer5Title]               TEXT           NULL,
    [Offer5Description]         TEXT           NULL,
    [Offer5Image]               NVARCHAR (206) NULL,
    [Offer5Link]                NVARCHAR (145) NULL,
    [Offer6]                    INT            NULL,
    [Offer6Title]               TEXT           NULL,
    [Offer6Description]         TEXT           NULL,
    [Offer6Image]               NVARCHAR (206) NULL,
    [Offer6Link]                NVARCHAR (145) NULL,
    [AgreedTcsDate]             DATETIME       NULL,
    [Primacy]                   VARCHAR (1)    NULL,
    [Offer1Percentage]          NVARCHAR (10)  NULL,
    [Offer1Retailer]            NVARCHAR (200) NULL,
    [Offer2Percentage]          NVARCHAR (10)  NULL,
    [Offer2Retailer]            NVARCHAR (200) NULL,
    [Offer3Percentage]          NVARCHAR (10)  NULL,
    [Offer3Retailer]            NVARCHAR (200) NULL,
    [Offer4Percentage]          NVARCHAR (10)  NULL,
    [Offer4Retailer]            NVARCHAR (200) NULL,
    [Offer5Percentage]          NVARCHAR (10)  NULL,
    [Offer5Retailer]            NVARCHAR (200) NULL,
    [Offer6Percentage]          NVARCHAR (10)  NULL,
    [Offer6Retailer]            NVARCHAR (200) NULL,
    [Offer7]                    INT            NULL,
    [Offer7Title]               TEXT           NULL,
    [Offer7Description]         TEXT           NULL,
    [Offer7Image]               NVARCHAR (206) NULL,
    [Offer7Link]                NVARCHAR (145) NULL,
    [Offer7Percentage]          NVARCHAR (10)  NULL,
    [Offer7Retailer]            NVARCHAR (200) NULL,
    [Offer1ImageLink]           NVARCHAR (200) NULL,
    [Offer2ImageLink]           NVARCHAR (200) NULL,
    [Offer3ImageLink]           NVARCHAR (200) NULL,
    [Offer4ImageLink]           NVARCHAR (200) NULL,
    [Offer5ImageLink]           NVARCHAR (200) NULL,
    [Offer6ImageLink]           NVARCHAR (200) NULL,
    [Offer7ImageLink]           NVARCHAR (200) NULL,
    [Offer1TitleLink]           NVARCHAR (200) NULL,
    [Offer2TitleLink]           NVARCHAR (200) NULL,
    [Offer3TitleLink]           NVARCHAR (200) NULL,
    [Offer4TitleLink]           NVARCHAR (200) NULL,
    [Offer5TitleLink]           NVARCHAR (200) NULL,
    [Offer6TitleLink]           NVARCHAR (200) NULL,
    [Offer7TitleLink]           NVARCHAR (200) NULL,
    [Offer1RetailerLink]        NVARCHAR (200) NULL,
    [Offer2RetailerLink]        NVARCHAR (200) NULL,
    [Offer3RetailerLink]        NVARCHAR (200) NULL,
    [Offer4RetailerLink]        NVARCHAR (200) NULL,
    [Offer5RetailerLink]        NVARCHAR (200) NULL,
    [Offer6RetailerLink]        NVARCHAR (200) NULL,
    [Offer7RetailerLink]        NVARCHAR (200) NULL,
    [CustomerID]                INT            NOT NULL,
    [CustomerJourneyStatus]     VARCHAR (3)    NULL
)
WITH (DATA_COMPRESSION = PAGE);


GO
GRANT SELECT
    ON OBJECT::[dbo].[LionUploadData_History] TO [Prakash]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[dbo].[LionUploadData_History] TO [gas]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[LionUploadData_History] TO [gas]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[LionUploadData_History] TO [stuart]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[LionUploadData_History] TO [Ed]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[LionUploadData_History] TO [Suraj]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[LionUploadData_History] TO [Adam]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[dbo].[LionUploadData_History] TO [sfduser]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[LionUploadData_History] TO [sfduser]
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[dbo].[LionUploadData_History] TO [sfduser]
    AS [dbo];

