CREATE TABLE [Rory].[OS_AllCustomers_2] (
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
    [JointAccountHolder]             VARCHAR (3)    NOT NULL,
    [OverseasAddress]                VARCHAR (3)    NULL,
    [ClubCashAvailable]              SMALLMONEY     NULL,
    [ClubCashPending]                SMALLMONEY     NULL,
    [LifeTimeValue]                  SMALLMONEY     NULL,
    [RewardCreditCardFlag]           VARCHAR (3)    NOT NULL,
    [RewardCreditCardType]           VARCHAR (15)   NOT NULL,
    [RewardCurrentAcctFlag]          VARCHAR (3)    NOT NULL,
    [RewardCurrentAcctType]          VARCHAR (3)    NOT NULL,
    [RewardCurrentAcctTotalRewards]  VARCHAR (12)   NOT NULL,
    [RewardCurrentAcctMobileRewards] VARCHAR (3)    NOT NULL,
    [CustomerUsedSSOLast30Days]      VARCHAR (3)    NOT NULL,
    [AgeCurrent]                     TINYINT        NULL,
    [EmailReason]                    VARCHAR (20)   NULL,
    [CustomerUsedSSOLast6Months]     VARCHAR (3)    NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FanID]
    ON [Rory].[OS_AllCustomers_2]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_PostOut]
    ON [Rory].[OS_AllCustomers_2]([Postcode] ASC);

