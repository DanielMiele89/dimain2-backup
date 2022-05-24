CREATE TABLE [InsightArchive].[RBSG_StatementDM_20200827] (
    [MatrixID]                       INT          NULL,
    [FanID]                          INT          NOT NULL,
    [SourceUID]                      VARCHAR (20) NULL,
    [Bank]                           VARCHAR (11) NULL,
    [CustomerType]                   VARCHAR (18) NOT NULL,
    [JointAccountHolder]             VARCHAR (3)  NOT NULL,
    [OverseasAddress]                VARCHAR (3)  NULL,
    [ClubCashAvailable]              SMALLMONEY   NULL,
    [ClubCashPending]                SMALLMONEY   NULL,
    [LifeTimeValue]                  SMALLMONEY   NULL,
    [RewardCreditCardFlag]           VARCHAR (3)  NOT NULL,
    [RewardCreditCardType]           VARCHAR (15) NOT NULL,
    [RewardCurrentAcctFlag]          VARCHAR (3)  NOT NULL,
    [RewardCurrentAcctType]          VARCHAR (3)  NOT NULL,
    [RewardCurrentAcctTotalRewards]  VARCHAR (12) NOT NULL,
    [RewardCurrentAcctMobileRewards] VARCHAR (3)  NOT NULL
);

