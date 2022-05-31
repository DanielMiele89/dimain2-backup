﻿CREATE TABLE [Rory].[OS_FrontbookPackaged_2] (
    [FanID]                          INT            NOT NULL,
    [SourceUID]                      VARCHAR (20)   NULL,
    [Bank]                           VARCHAR (11)   NULL,
    [CustomerType]                   VARCHAR (18)   NOT NULL,
    [Title]                          NVARCHAR (20)  NULL,
    [FirstName]                      NVARCHAR (50)  NOT NULL,
    [LastName]                       NVARCHAR (50)  NOT NULL,
    [Address1]                       NVARCHAR (100) NOT NULL,
    [Address2]                       NVARCHAR (100) NOT NULL,
    [Address3]                       VARCHAR (1)    NOT NULL,
    [Address4]                       VARCHAR (1)    NOT NULL,
    [City]                           NVARCHAR (100) NOT NULL,
    [Postcode]                       NVARCHAR (20)  NOT NULL,
    [JointAccountHolder]             INT            NULL,
    [OverseasAddress]                VARCHAR (1)    NOT NULL,
    [ClubCashAvailable]              SMALLMONEY     NULL,
    [ClubCashPending]                SMALLMONEY     NULL,
    [LifeTimeValue]                  SMALLMONEY     NULL,
    [RewardCreditCardFlag]           INT            NULL,
    [RewardCreditCardType]           INT            NULL,
    [RewardCurrentAcctFlag]          INT            NULL,
    [RewardCurrentAcctType]          VARCHAR (3)    NOT NULL,
    [RewardCurrentAcctTotalRewards]  MONEY          NULL,
    [RewardCurrentAcctMobileRewards] MONEY          NULL
);

