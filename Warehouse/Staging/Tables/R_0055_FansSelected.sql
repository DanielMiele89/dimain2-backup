CREATE TABLE [Staging].[R_0055_FansSelected] (
    [LionSendRowNo] INT    NOT NULL,
    [FanID]         INT    NOT NULL,
    [CompositeID]   BIGINT NOT NULL,
    [LionSendID]    INT    NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IDX_Comp]
    ON [Staging].[R_0055_FansSelected]([CompositeID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_LS]
    ON [Staging].[R_0055_FansSelected]([LionSendID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_FanID]
    ON [Staging].[R_0055_FansSelected]([FanID] ASC);

