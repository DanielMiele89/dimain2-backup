CREATE TABLE [InsightArchive].[RBSG_StatementDM_20170710] (
    [RewardCustomerID]     INT           NOT NULL,
    [Bank]                 VARCHAR (11)  NULL,
    [Customer type]        VARCHAR (18)  NULL,
    [Title]                VARCHAR (20)  NULL,
    [FirstName]            VARCHAR (50)  NULL,
    [Lastname]             VARCHAR (50)  NULL,
    [Address1]             VARCHAR (100) NULL,
    [Address2]             VARCHAR (100) NULL,
    [City]                 VARCHAR (100) NULL,
    [Postcode]             VARCHAR (10)  NULL,
    [Balance]              SMALLMONEY    NOT NULL,
    [Pending]              SMALLMONEY    NULL,
    [DD_Earnings]          MONEY         NOT NULL,
    [DC_Earnings]          MONEY         NOT NULL,
    [CC_Earnings]          MONEY         NULL,
    [Reward Credit card]   VARCHAR (3)   NOT NULL,
    [Household bill]       VARCHAR (8)   NOT NULL,
    [Joint account holder] VARCHAR (3)   NOT NULL,
    [TypeID]               INT           NULL
);

