CREATE TABLE [Prototype].[Hack_PropensityScore] (
    [FanID]                      INT        NOT NULL,
    [LastTransactionForRetailer] DATE       NULL,
    [AcquireScore]               FLOAT (53) NULL,
    [SpendAmount]                MONEY      NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

