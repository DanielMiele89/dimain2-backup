CREATE TABLE [Staging].[OPECustomer] (
    [FanID]   INT     NOT NULL,
    [Random1] TINYINT NULL,
    [Random2] TINYINT NULL,
    [Random3] TINYINT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC) WITH (FILLFACTOR = 80)
);

