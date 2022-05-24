CREATE TABLE [InsightArchive].[RBSG_StatementDM_20190430] (
    [Type]                      INT           NULL,
    [FanID]                     INT           NOT NULL,
    [CIN]                       VARCHAR (20)  NULL,
    [Bank]                      VARCHAR (11)  NULL,
    [CustomerType]              VARCHAR (25)  NULL,
    [Title]                     VARCHAR (20)  NULL,
    [FirstName]                 VARCHAR (50)  NULL,
    [LastName]                  VARCHAR (50)  NULL,
    [Address1]                  VARCHAR (100) NULL,
    [Address2]                  VARCHAR (100) NULL,
    [City]                      VARCHAR (100) NULL,
    [PostCode]                  VARCHAR (10)  NULL,
    [JointAccount]              INT           NULL,
    [ClubCashAvailable_30April] SMALLMONEY    NOT NULL,
    [ClubCashPending_30April]   SMALLMONEY    NULL,
    [LifeTimeValue]             SMALLMONEY    NULL,
    [CreditCardCustomer]        VARCHAR (3)   NOT NULL,
    [HouseholdBills_Threshold]  VARCHAR (8)   NOT NULL,
    [HouseholdBills_Value]      FLOAT (53)    NULL
);


GO
CREATE CLUSTERED INDEX [CIX_Fan]
    ON [InsightArchive].[RBSG_StatementDM_20190430]([FanID] ASC);

