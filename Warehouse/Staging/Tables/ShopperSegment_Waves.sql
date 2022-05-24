CREATE TABLE [Staging].[ShopperSegment_Waves] (
    [WaveID]    INT  IDENTITY (1, 1) NOT NULL,
    [StartDate] DATE NULL,
    [EndDate]   DATE NULL,
    PRIMARY KEY CLUSTERED ([WaveID] ASC)
);

