CREATE TABLE [InsightArchive].[Sky026_PrimeCustomersStandard] (
    [CINID]                     INT            NOT NULL,
    [JoinPaymentType]           VARCHAR (7)    NOT NULL,
    [JoinDate]                  DATE           NOT NULL,
    [JoinYM]                    VARCHAR (25)   NOT NULL,
    [JoinAmount]                MONEY          NOT NULL,
    [LastPaymentType]           VARCHAR (7)    NULL,
    [LastAmount]                MONEY          NULL,
    [LastPaymentDate]           DATE           NULL,
    [CurrentStatus]             VARCHAR (6)    NULL,
    [LapsedDate]                DATE           NULL,
    [MembershipLength]          INT            NULL,
    [Social_Class]              NVARCHAR (255) NULL,
    [CAMEO_CODE_GROUP_Category] VARCHAR (100)  NULL,
    [AgeAtJoin]                 INT            NULL
);


GO
CREATE CLUSTERED INDEX [PIX_CINID]
    ON [InsightArchive].[Sky026_PrimeCustomersStandard]([CINID] ASC) WITH (FILLFACTOR = 90);

