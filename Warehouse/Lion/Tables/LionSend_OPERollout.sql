CREATE TABLE [Lion].[LionSend_OPERollout] (
    [ID]        INT    IDENTITY (1, 1) NOT NULL,
    [FanID]     BIGINT NULL,
    [OnNewOPE]  BIT    NULL,
    [StartDate] DATE   NULL,
    [EndDate]   DATE   NULL
);


GO
CREATE CLUSTERED INDEX [CIX_All]
    ON [Lion].[LionSend_OPERollout]([FanID] ASC, [EndDate] ASC, [OnNewOPE] ASC);

