CREATE TABLE [Rory].[OS_Hardbounce] (
    [FanID]          INT      NOT NULL,
    [HardBounceDate] DATETIME NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FanID]
    ON [Rory].[OS_Hardbounce]([FanID] ASC);

