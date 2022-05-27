CREATE TABLE [Staging].[Customers_Passed0GBP] (
    [FanID]           INT           NOT NULL,
    [Date]            DATE          NULL,
    [FirstEarnValue]  REAL          NULL,
    [FirstEarnType]   VARCHAR (100) NULL,
    [MyRewardAccount] VARCHAR (50)  NULL
);


GO
CREATE CLUSTERED INDEX [cx_FanID]
    ON [Staging].[Customers_Passed0GBP]([FanID] ASC) WITH (FILLFACTOR = 85);

