CREATE TABLE [Staging].[R_0055_LionSendWeek] (
    [LionSendID]         INT  NULL,
    [SendWeekCommencing] DATE NULL
);


GO
CREATE CLUSTERED INDEX [IDX_WC]
    ON [Staging].[R_0055_LionSendWeek]([SendWeekCommencing] ASC);

