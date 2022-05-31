CREATE TABLE [Rory].[OS_Customer_FirstCashbackBalance_2] (
    [FanID]     INT  NOT NULL,
    [FirstDate] DATE NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FanIDFirstDate]
    ON [Rory].[OS_Customer_FirstCashbackBalance_2]([FanID] ASC, [FirstDate] ASC);

