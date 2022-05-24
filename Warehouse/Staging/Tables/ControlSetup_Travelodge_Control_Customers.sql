CREATE TABLE [Staging].[ControlSetup_Travelodge_Control_Customers] (
    [FanID]            INT          NOT NULL,
    [CINID]            INT          NOT NULL,
    [TLD_LatestTx]     VARCHAR (30) NULL,
    [ALS_Segment]      VARCHAR (30) NULL,
    [TLD_Freq12Mon]    INT          NULL,
    [TLD_SoW]          FLOAT (53)   NULL,
    [HotelTxs]         INT          NULL,
    [TrainTxs]         INT          NULL,
    [TrainAndHotelTxs] INT          NULL,
    [Business]         VARCHAR (30) NULL,
    [Parent]           INT          NULL,
    [MainSegment]      VARCHAR (30) NULL
);


GO
CREATE NONCLUSTERED INDEX [i_Customer_FanID]
    ON [Staging].[ControlSetup_Travelodge_Control_Customers]([FanID] ASC);


GO
CREATE CLUSTERED INDEX [i_Customer_CINID]
    ON [Staging].[ControlSetup_Travelodge_Control_Customers]([CINID] ASC) WITH (FILLFACTOR = 80);

